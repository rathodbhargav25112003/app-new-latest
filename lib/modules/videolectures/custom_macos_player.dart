// ignore_for_file: deprecated_member_use, library_private_types_in_public_api, unused_import, use_super_parameters, unused_field, unused_local_variable, non_constant_identifier_names, dead_code, prefer_final_fields, unnecessary_import, must_be_immutable

import 'dart:io';
import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';
import 'package:flick_video_player/flick_video_player.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../helpers/app_tokens.dart';
import '../../helpers/constants.dart';


class MyMacosView extends StatefulWidget {
   MyMacosView({required this.videoId, super.key, this.flickManager});
  FlickManager? flickManager;
  final String videoId;

  @override
  State<MyMacosView> createState() => _MyMacosViewState();
}

class _MyMacosViewState extends State<MyMacosView> {
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchVideoUrl();
  }

  Future<void> _fetchVideoUrl() async {
    try {
      // Use server-side proxy instead of direct Vimeo API call
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token") ?? '';
      final proxyUrl = '$baseUrl/video/vimeo-url/${widget.videoId}';

      final response = await http.get(
        Uri.parse(proxyUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': token,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final payload = data['data'] ?? data;
        final videoUrl = (payload['link'] ?? payload['url']) as String?;

        if (videoUrl != null && videoUrl.isNotEmpty) {
          setState(() {
            widget.flickManager = FlickManager(
              videoPlayerController: VideoPlayerController.networkUrl(
                Uri.parse(videoUrl),
              ),
            );
            isLoading = false;
          });
        } else {
          debugPrint('[macOS] No video URL in proxy response');
        }
      } else {
        debugPrint('[macOS] Vimeo proxy failed: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[macOS] Error fetching video URL: $e');
    }
  }



  @override
  void dispose() {
    widget.flickManager?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Platform.isMacOS
        ? isLoading
            ? Center(
                child: CircularProgressIndicator(
                  color: AppTokens.accent(context),
                ),
              )
            : FlickVideoPlayer(flickManager: widget.flickManager!)
        : const SizedBox.shrink(); // Placeholder for non-macOS platforms
  }
}
