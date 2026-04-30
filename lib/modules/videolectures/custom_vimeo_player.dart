// lib/vimeo_player.dart
// ignore_for_file: deprecated_member_use, library_private_types_in_public_api, unused_import, use_super_parameters, unused_field, unused_local_variable, non_constant_identifier_names, dead_code, prefer_final_fields, unnecessary_import, depend_on_referenced_packages, prefer_interpolation_to_compose_strings

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:shusruta_lms/helpers/app_tokens.dart';

class VimeoPlayer extends StatefulWidget {
  const VimeoPlayer({
    super.key,
    required this.videoId,
    required this.onControllerCreated,
    this.onTimeUpdate,
    this.onPlayerReady,
    this.initialStartSeconds = 0,
  });

  final String videoId;
  final Function(VimeoPlayerController) onControllerCreated;
  final void Function(int seconds)? onTimeUpdate;
  final VoidCallback? onPlayerReady;
  final int initialStartSeconds;

  @override
  State<VimeoPlayer> createState() => _VimeoPlayerState();
}

class _VimeoPlayerState extends State<VimeoPlayer> with AutomaticKeepAliveClientMixin {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..addJavaScriptChannel('PlayerReady', onMessageReceived: (JavaScriptMessage msg) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        // Notify parent
        widget.onPlayerReady?.call();
      })
      ..addJavaScriptChannel('TimeUpdate', onMessageReceived: (JavaScriptMessage msg) {
        final value = int.tryParse(msg.message);
        if (value != null) {
          widget.onTimeUpdate?.call(value);
        }
      })
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
          },
          onNavigationRequest: (NavigationRequest request) {
            // Keep navigation within the same WebView (block target=_blank redirects)
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(_videoPage(widget.videoId));

    // Provide controller once
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          widget.onControllerCreated(
            VimeoPlayerController(
              _seekTo,
              _pause,
              _unload,
              _play,
              _unmute,
              () async => null,
              _resumeAt,
            ),
          );
        }
      });
    }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Stack(
      children: [
        WebViewWidget(
          controller: _controller,
        ),
        if (_isLoading)
          Positioned.fill(
            child: ColoredBox(
              color: Colors.black,
              child: Center(
                child: CircularProgressIndicator(
                  color: AppTokens.accent(context),
                ),
              ),
            ),
          ),
      ],
    );
  }

  @override
  bool get wantKeepAlive => true;

  Uri _videoPage(String videoId) {
    final html = '''
      <html>
        <head>
          <style>
            body {
              background-color: black;
              margin: 0px;
            }
            </style>
          <meta name="viewport" content="initial-scale=1.0, maximum-scale=1.0">
          <meta http-equiv="Content-Security-Policy" 
          content="default-src * gap:; script-src * 'unsafe-inline' 'unsafe-eval'; connect-src *; 
          img-src * data: blob: android-webview-video-poster:; style-src * 'unsafe-inline';">
        </head>
        <body>
          <iframe 
          id="vimeoPlayer"
          src="https://player.vimeo.com/video/$videoId?loop=0&autoplay=1&muted=1&playsinline=1" 
          width="100%" height="100%" frameborder="0" allow="autoplay; fullscreen; picture-in-picture" 
          allowfullscreen></iframe>
          <script src="https://player.vimeo.com/api/player.js"></script>
          <script>
            var player = new Vimeo.Player(document.getElementById('vimeoPlayer'));
            var startSec = ${widget.initialStartSeconds};
            function seekTo(seconds) {
              player.setCurrentTime(seconds);
            }
            function pause() {
              try { player.pause(); } catch(e) {}
            }
            function unload() {
              try { player.unload(); } catch(e) {}
            }
            function play() {
              try { player.play(); } catch(e) {}
            }
            function unmute() {
              try { player.setMuted(false); } catch(e) {}
            }
            function getCurrentTime() {
              try { return player.getCurrentTime(); } catch(e) { return 0; }
            }
            function resumeAt(seconds) {
              try { player.setCurrentTime(seconds).then(function(){ player.play(); }); } catch(e) {}
            }
            try {
              player.on('loaded', function(){
                if (startSec && startSec > 0) {
                  player.setCurrentTime(startSec).then(function(){ player.play(); });
                }
                if (window.PlayerReady && window.PlayerReady.postMessage) {
                  window.PlayerReady.postMessage('ready');
                }
              });
              // Poll current time every 2 seconds and post to Flutter
              var __timePollIntervalId = setInterval(function(){
                player.getCurrentTime().then(function(seconds){
                  if (window.TimeUpdate && window.TimeUpdate.postMessage) {
                    try { window.TimeUpdate.postMessage(String(Math.floor(seconds))); } catch(e) {}
                  }
                });
              }, 2000);
            
            function stopTimers(){
              try { clearInterval(__timePollIntervalId); } catch(e) {}
            }
            function destroy(){
              try { stopTimers(); } catch(e) {}
              try { player.unload(); } catch(e) {}
              try {
                var iframe = document.getElementById('vimeoPlayer');
                if (iframe) { iframe.src = 'about:blank'; iframe.remove(); }
              } catch(e) {}
            }
            } catch(e) {}
          </script>
        </body>
      </html>
    ''';
    final String contentBase64 =
        base64Encode(const Utf8Encoder().convert(html));
    return Uri.parse('data:text/html;base64,$contentBase64');
  }

  void _seekTo(int seconds) {
    _controller.runJavaScript('seekTo($seconds);');
  }

  void _pause() {
    _controller.runJavaScript('pause();');
  }

  void _unload() {
    _controller.runJavaScript('try{destroy();}catch(e){}');
  }

  void _play() {
    _controller.runJavaScript('play();');
  }

  void _unmute() {
    _controller.runJavaScript('unmute();');
  }

  void _resumeAt(int seconds) {
    _controller.runJavaScript('resumeAt(' + seconds.toString() + ');');
  }

  @override
  void dispose() {
    // Aggressively destroy the iframe before disposal to prevent long hangs
    try {
      _controller.runJavaScript('try{destroy();}catch(e){}');
    } catch (_) {}
    // Keep dispose minimal to avoid blocking UI during back navigation
    super.dispose();
  }
}

class VimeoPlayerController {
  final Function(int seconds) seekTo;
  final VoidCallback pause;
  final VoidCallback unload;
  final VoidCallback play;
  final VoidCallback unmute;
  final Future<int?> Function() getCurrentTime;
  final void Function(int seconds) resumeAt;

  VimeoPlayerController(this.seekTo, this.pause, this.unload, this.play, this.unmute, this.getCurrentTime, this.resumeAt);
}
