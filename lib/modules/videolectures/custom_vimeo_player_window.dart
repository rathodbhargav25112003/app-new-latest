// ignore_for_file: deprecated_member_use, library_private_types_in_public_api, unused_import, use_super_parameters, unused_field, unused_local_variable, non_constant_identifier_names, dead_code, prefer_final_fields, unnecessary_import, must_call_super

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shusruta_lms/helpers/app_tokens.dart';
import 'package:shusruta_lms/modules/videolectures/custom_vimeo_player.dart';
import 'package:window_manager/window_manager.dart';
import 'package:webview_windows/webview_windows.dart';

final navigatorKey = GlobalKey<NavigatorState>();

class WindowVimeoPlayer extends StatefulWidget {
  const WindowVimeoPlayer({
    super.key,
    required this.videoId,
    required this.onControllerCreated,
    this.onFullScreen,
  });

  final String videoId;
  final Function(VimeoPlayerController1) onControllerCreated;
  final Function(bool)? onFullScreen;

  @override
  State<WindowVimeoPlayer> createState() => _WindowVimeoPlayerState();
}

class _WindowVimeoPlayerState extends State<WindowVimeoPlayer>
    with AutomaticKeepAliveClientMixin {
  final _controller = WebviewController();
  final _textController = TextEditingController();
  final List<StreamSubscription> _subscriptions = [];
  String? _currentlyLoadedVideoId;

  @override
  void initState() {
    super.initState();
    initPlatformState();
    // Notify the parent widget that the controller has been created
    widget.onControllerCreated(VimeoPlayerController1(_controller));
  }

  Future<void> initPlatformState() async {
    try {
      // Initialize the WebView controller
      await _controller.initialize();

      // Listen to URL changes
      _subscriptions.add(_controller.url.listen((url) {
        _textController.text = url;
      }));

      // Listen to fullscreen changes
      _subscriptions
          .add(_controller.containsFullScreenElementChanged.listen((flag) {
        debugPrint('Contains fullscreen element: $flag');
        // setFullScreen(flag);

        if (widget.onFullScreen != null) {
          widget.onFullScreen!(flag);
        }
      }));

      // Set WebView properties
      await _controller.setBackgroundColor(Colors.transparent);
      await _controller.setPopupWindowPolicy(WebviewPopupWindowPolicy.deny);

      // Load the Vimeo video URL directly
      // Only load if not already loaded with the same video id
      _currentlyLoadedVideoId = widget.videoId;
      await _controller.loadUrl(videoPage(widget.videoId));

      if (!mounted) return;
      setState(() {});
    } on PlatformException catch (e) {
      // Handle platform-specific exceptions
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Error'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Code: ${e.code}'),
                Text('Message: ${e.message}'),
              ],
            ),
            actions: [
              TextButton(
                child: const Text('Continue'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              )
            ],
          ),
        );
      });
    }
  }

  /// Generates the Vimeo video URL.
  String videoPage(String videoId) {
    // Direct Vimeo video link with fast-start hints
    // autoplay=1 (muted) can reduce gesture/handshake delay; playsinline keeps layout stable
    return 'https://player.vimeo.com/video/'
        '$videoId?loop=0&autoplay=1&muted=1&playsinline=1';
  }

  /// Sets the application window to fullscreen or windowed mode.
  // void setFullScreen(bool isFullScreen) {
  //   if (isFullScreen) {
  //     windowManager.setFullScreen(true);
  //   } else {
  //     windowManager.setFullScreen(false);
  //   }
  // }

  /// Builds the composite view containing the WebView and loading indicator.
  Widget compositeView() {
    super.build(context);
    if (!_controller.value.isInitialized) {
      return Center(
        child: Text(
          'Not Initialized',
          style: AppTokens.titleLg(context).copyWith(
            fontWeight: FontWeight.w900,
            color: AppTokens.muted(context),
          ),
        ),
      );
    } else {
      return Column(
        children: [
          Flexible(
            child: Card(
              color: Colors.transparent,
              elevation: 0,
              clipBehavior: Clip.antiAliasWithSaveLayer,
              child: Stack(
                children: [
                  Webview(
                    scaleFactor: 1.0,
                    filterQuality: FilterQuality.high,
                    _controller,
                    permissionRequested: onPermissionRequested,
                  ),
                  StreamBuilder<LoadingState>(
                    stream: _controller.loadingState,
                    builder: (context, snapshot) {
                      if (snapshot.hasData &&
                          snapshot.data == LoadingState.loading) {
                        return LinearProgressIndicator(
                          minHeight: 2,
                          color: AppTokens.accent(context),
                          backgroundColor: AppTokens.surface2(context),
                        );
                      } else {
                        return const SizedBox();
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }
  }

  /// Handles permission requests from the WebView.
  Future<WebviewPermissionDecision> onPermissionRequested(
      String url, WebviewPermissionKind kind, bool isUserInitiated) async {
    final decision = await showDialog<WebviewPermissionDecision>(
      context: navigatorKey.currentContext!,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('WebView Permission Requested'),
        content: Text('WebView has requested permission for \'$kind\'.'),
        actions: <Widget>[
          TextButton(
            onPressed: () =>
                Navigator.pop(context, WebviewPermissionDecision.deny),
            child: const Text('Deny'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(context, WebviewPermissionDecision.allow),
            child: const Text('Allow'),
          ),
        ],
      ),
    );

    return decision ?? WebviewPermissionDecision.none;
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: compositeView(),
    );
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    // Cancel all stream subscriptions
    for (var s in _subscriptions) {
      s.cancel();
    }
    // Dispose the WebView controller
    _controller.dispose();
    super.dispose();
  }
}

/// Controller class for the Vimeo player.
/// This can be expanded to include additional functionalities as needed.
class VimeoPlayerController1 {
  final WebviewController webviewController;

  VimeoPlayerController1(this.webviewController);

  // Add methods to control the WebView or interact with the Vimeo player
  Future<void> loadVideoById(String videoId) async {
    await webviewController.loadUrl(
      'https://player.vimeo.com/video/$videoId?loop=0&autoplay=1&muted=1&playsinline=1',
    );
  }
}
