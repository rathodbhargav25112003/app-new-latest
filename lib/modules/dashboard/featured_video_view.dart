import 'dart:io';
import '../../app/routes.dart';
import '../../helpers/app_tokens.dart';
import '../../helpers/colors.dart';
import '../../helpers/styles.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../helpers/dimensions.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../models/featured_list_model.dart';
import '../videolectures/custom_vimeo_player.dart';
import '../videolectures/store/video_category_store.dart';
import '../videolectures/model/get_all_video_topic_detail_model.dart';
import 'package:shusruta_lms/modules/videolectures/custom_vimeo_player_window.dart' as window;
import 'package:shared_preferences/shared_preferences.dart';

class FeaturedVideoView extends StatefulWidget {
  final Videos? featuredVideo;
  final List<Videos>? featuredVideoList;
  const FeaturedVideoView(
      {super.key, this.featuredVideo, this.featuredVideoList});

  @override
  State<FeaturedVideoView> createState() => _FeaturedVideoViewState();
  static Route<dynamic> route(RouteSettings routeSettings) {
    final arguments = routeSettings.arguments as Map<String, dynamic>;
    return PageRouteBuilder(
      settings: routeSettings,
      pageBuilder: (_, __, ___) => FeaturedVideoView(
        featuredVideo: arguments['featuredVideo'],
        featuredVideoList: arguments['featuredVideoList'],
      ),
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
      transitionsBuilder: (_, __, ___, child) => child,
    );
  }
}

class _FeaturedVideoViewState extends State<FeaturedVideoView> with WidgetsBindingObserver {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool pdfview = false;
  bool positive = false;
  bool isFullScreen = false;
  String pdfUrl = '';
  String contentUrl = '';
  int currentIndex = 0;
  late window.VimeoPlayerController1 _vimeoPlayerController1;
  late VimeoPlayerController _vimeoPlayerController;
  bool _mobileControllerReady = false;
  bool _windowControllerReady = false;
  bool _isExiting = false; // prevents double-pop and repeated cleanup
  int _lastSavedSeconds = 0;
  bool get _isDesktop => Platform.isWindows || Platform.isMacOS || Platform.isLinux;
  int _initialStartSeconds = 0;
  SharedPreferences? _prefs; // cache to avoid repeated getInstance calls
  int _lastPersistedSeconds = -1; // throttling guard
  bool _detached = false; // when true, video widget is removed immediately

  String get _resumeKey {
    final raw = widget.featuredVideo?.videoUrl ?? '';
    // Extract numeric Vimeo ID if present, else fallback to raw
    final match = RegExp(r'(\d{6,})').firstMatch(raw);
    final id = match != null ? match.group(1) : raw;
    return 'video_pos_$id';
  }

  Future<void> _savePosition(int seconds) async {
    // Keep latest in memory for resume/cleanup
    _lastSavedSeconds = seconds;
    try {
      // If prefs is not ready yet, initialize once
      final prefs = _prefs ??= await SharedPreferences.getInstance();
      // Persist without awaiting to avoid blocking UI thread
      // Best-effort write; errors are ignored
      // ignore: unawaited_futures
      prefs.setInt(_resumeKey, seconds);
    } catch (_) {}
  }

  void _savePositionThrottled(int seconds) {
    _lastSavedSeconds = seconds;
    // Save only if moved at least 5 seconds since last persist
    if (_lastPersistedSeconds == -1 || (seconds - _lastPersistedSeconds).abs() >= 5) {
      _lastPersistedSeconds = seconds;
      // Fire-and-forget; do not await
      // ignore: discarded_futures
      _savePosition(seconds);
    }
  }

  Future<int> _loadPosition() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_resumeKey) ?? 0;
    } catch (_) {
      return 0;
    }
  }

  Future<void> _cleanupPlayer() async {
    try {
      if (Platform.isWindows || Platform.isMacOS) {
        if (_windowControllerReady) {
          // Webview_windows will dispose on widget dispose; nothing else to call here
        }
      } else {
        if (_mobileControllerReady) {
          // Best-effort persist latest known time before pausing
          await _savePosition(_lastSavedSeconds);
          _vimeoPlayerController.pause();
          _vimeoPlayerController.unload();
        }
      }
    } catch (_) {}
  }

  // Do not block back navigation; schedule cleanup asynchronously
  Future<bool> _onWillPopFast() async {
    if (_isExiting) return true;
    _isExiting = true;
    // Stop player immediately (fire-and-forget) to cut ongoing events
    try {
      if (!_isDesktop) {
        _vimeoPlayerController.pause();
        _vimeoPlayerController.unload();
      }
    } catch (_) {}
    // Stop time updates from doing work
    _mobileControllerReady = false;
    // Detach player from tree to avoid heavy dispose during route pop
    if (mounted && !_detached) {
      setState(() { _detached = true; });
    }
    // Fire-and-forget cleanup so pop returns immediately
    Future.microtask(() async {
      await _cleanupPlayer();
    });
    return true;
  }

  void _onBackTap() {
    if (_isExiting) return;
    _isExiting = true;
    // Stop player immediately (fire-and-forget) to cut ongoing events
    try {
      if (!_isDesktop) {
        _vimeoPlayerController.pause();
        _vimeoPlayerController.unload();
      }
    } catch (_) {}
    // Stop time updates from doing work
    _mobileControllerReady = false;
    // Detach player from tree to avoid heavy dispose during route pop
    if (mounted && !_detached) {
      setState(() { _detached = true; });
    }
    // Pop in next microtask so detach has taken effect
    Future.microtask(() => Navigator.pop(context));
    // Cleanup after pop to avoid blocking UI thread
    Future.microtask(() async {
      await _cleanupPlayer();
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _getAllVideoDetailList();
    contentUrl = widget.featuredVideo?.contentUrl ?? "";
    if (contentUrl != "") {
      pdfUrl = "getPDF${contentUrl.substring(contentUrl.lastIndexOf('/'))}";
    }
    // Warm up SharedPreferences to avoid platform channel stall on back
    SharedPreferences.getInstance().then((p) => _prefs = p);
    // Preload saved position so the player can start at last position
    _loadPosition().then((sec) {
      if (!mounted) return;
      setState(() {
        _initialStartSeconds = sec;
      });
    });
  }

  Future<void> _getAllVideoDetailList() async {
    final store = Provider.of<VideoCategoryStore>(context, listen: false);
    await store
        .onAllVideoTopicDetailApiCall(widget.featuredVideo?.topicId ?? "");
  }

  @override
  Widget build(BuildContext context) {
    final store = Provider.of<VideoCategoryStore>(context, listen: false);
    List<Videos>? filteredTopics = widget.featuredVideoList;
    if (widget.featuredVideo != null) {
      filteredTopics = widget.featuredVideoList
          ?.where((topic) => topic.topicName != widget.featuredVideo!.topicName)
          .toList();
    }
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light.copyWith(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    int convertTimeStringToSeconds(String timeString) {
      // Split the time string by colon and parse each part
      List<String> parts = timeString.split(':');
      int hours = int.parse(parts[0]);
      int minutes = int.parse(parts[1]);
      int seconds = int.parse(parts[2]);

      // Convert everything to total seconds
      return (hours * 3600) + (minutes * 60) + seconds;
    }

    void seekToChapter(String? timeString) {
      if (timeString != null && timeString.isNotEmpty) {
        int totalSeconds = convertTimeStringToSeconds(timeString);
        _vimeoPlayerController.seekTo(totalSeconds);
      } else {
        // Handle the case where timeString is null or empty
        print('Invalid time string');
      }
    }

    return DefaultTabController(
      length: 2,
      child: SafeArea(
        child: WillPopScope(
          onWillPop: _onWillPopFast,
          child: Scaffold(
          key: _scaffoldKey,
          backgroundColor:
              isFullScreen ? ThemeManager.black : ThemeManager.white,
          body: OrientationBuilder(
            builder: (_, Orientation orientation) {
              bool isLandscape = orientation == Orientation.landscape;
              double videoWidth = double.infinity;
              double videoHeight = isLandscape
                  ? (Platform.isWindows || Platform.isMacOS)
                      ? MediaQuery.of(context).size.height * 0.922
                      : MediaQuery.of(context).size.height
                  : MediaQuery.of(context).size.height * 0.27;
              String videoUrl = widget.featuredVideo?.videoUrl ?? "";
              // debugPrint("videourl $videoUrl");
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(
                        AppTokens.s8, AppTokens.s8, AppTokens.s16, AppTokens.s8),
                    color: AppColors.black,
                    child: Row(
                      children: [
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTapDown: (_) => _onBackTap(),
                          child: const Padding(
                            padding: EdgeInsets.all(AppTokens.s8),
                            child: Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: AppColors.white,
                              size: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppTokens.s8),
                        Expanded(
                          child: Text(
                            widget.featuredVideo?.topicName ?? "",
                            style: AppTokens.titleSm(context).copyWith(
                              color: AppColors.white,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),

                  //video player
                  (Platform.isWindows || Platform.isMacOS)
                      ? Container(
                          height: isFullScreen
                              ? videoHeight
                              : MediaQuery.of(context).size.height * 0.5,
                          color: ThemeManager.black,
                          padding: EdgeInsets.zero,
                          margin: EdgeInsets.zero,
                          child: window.WindowVimeoPlayer(
                            videoId: videoUrl,
                            onControllerCreated: (controller) {
                              _vimeoPlayerController1 = controller;
                              _windowControllerReady = true;
                            },
                            onFullScreen: (p0) {
                              debugPrint("FUll screen : $p0");

                              isFullScreen = p0;
                              setState(() {});
                            },
                          ),
                        )
                      : Container(
                          height: videoHeight,
                          color: ThemeManager.black,
                          padding: EdgeInsets.zero,
                          margin: EdgeInsets.zero,
                          child: VimeoPlayer(
                            videoId: widget.featuredVideo?.videoUrl ?? "",
                            initialStartSeconds: _initialStartSeconds,
                            onControllerCreated: (controller) {
                              _vimeoPlayerController = controller;
                              _mobileControllerReady = true;
                            },
                            onTimeUpdate: (sec) {
                              // Throttled, non-blocking save to reduce back-pressure
                              _savePositionThrottled(sec);
                            },
                            onPlayerReady: () async {
                              // Give the player a moment to become fully controllable
                              await Future.delayed(const Duration(milliseconds: 200));
                              final sec = await _loadPosition();
                              if (_mobileControllerReady && sec > 0) {
                                // Double-seek to ensure the iframe applies the position
                                _vimeoPlayerController.seekTo(sec);
                                await Future.delayed(const Duration(milliseconds: 250));
                                _vimeoPlayerController.seekTo(sec);
                                await Future.delayed(const Duration(milliseconds: 150));
                                _vimeoPlayerController.play();
                                // Unmute best-effort (may require user gesture depending on device policy)
                                _vimeoPlayerController.unmute();
                              }
                            },
                          ),
                          // InAppWebView(
                          //   initialData: InAppWebViewInitialData(
                          //     data: '<iframe src="$videoUrl" width="100%" height="100%" frameborder="0" allow="autoplay; fullscreen; picture-in-picture;" allowfullscreen></iframe>',
                          //     mimeType: 'text/html',
                          //     encoding: 'utf-8',
                          //   ),
                          //   initialOptions: InAppWebViewGroupOptions(
                          //     crossPlatform: InAppWebViewOptions(
                          //       useShouldOverrideUrlLoading: true,
                          //       mediaPlaybackRequiresUserGesture: false,
                          //       supportZoom: true,
                          //       useOnLoadResource: true,
                          //       javaScriptEnabled: true,
                          //       transparentBackground: true,
                          //     ),
                          //   ),
                          //   onWebViewCreated: (InAppWebViewController controller) {
                          //     controller.evaluateJavascript(source: '''
                          //     document.querySelector("iframe").requestFullscreen();
                          //     document.querySelector("iframe").addEventListener("fullscreenchange", (event) => {
                          //       if (document.fullscreenElement) {
                          //         document.documentElement.style.overflow = 'hidden';
                          //       } else {
                          //         document.documentElement.style.overflow = 'auto';
                          //       }
                          //     });
                          //   ''');
                          //   },
                          // )
                        ),
                  // Positioned(
                  //   top: Dimensions.PADDING_SIZE_EXTRA_LARGE * 0.8,
                  //   left: Dimensions.PADDING_SIZE_LARGE,
                  //   child:       IconButton(       highlightColor: Colors.transparent,     hoverColor: Colors.transparent,
                  //     alignment: Alignment.topLeft,
                  //     icon: const Icon(
                  //       Icons.arrow_back_ios,
                  //       color: Color(0xFFF7F6FF),
                  //     ),
                  //     onPressed: () {
                  //       Navigator.pop(context);
                  //     },
                  //   ),
                  // ),
                  // Positioned(
                  //   top: Dimensions.PADDING_SIZE_EXTRA_LARGE * 0.8,
                  //   left: Dimensions.PADDING_SIZE_EXTRA_LARGE * 29,
                  //   child: GestureDetector(
                  //     onTap: () {
                  //       setState(() {
                  //         _scaffoldKey.currentState?.openEndDrawer();
                  //       });
                  //     },
                  //     child: const Icon(Icons.more_horiz, color: Color(0xFFF7F6FF)),
                  //   ),
                  // ),
                  // Container(
                  //   width: MediaQuery.of(context).size.width,
                  //   color: ThemeManager.currentTheme == AppTheme.Dark ? ThemeManager.white : Theme.of(context).primaryColor,
                  //   child: Padding(
                  //     padding: const EdgeInsets.only(
                  //       left: Dimensions.PADDING_SIZE_EXTRA_LARGE,
                  //       top: Dimensions.PADDING_SIZE_LARGE,
                  //       bottom: Dimensions.PADDING_SIZE_LARGE,
                  //       right: Dimensions.PADDING_SIZE_DEFAULT,
                  //     ),
                  //     child: Row(
                  //       crossAxisAlignment: CrossAxisAlignment.center,
                  //       children: [
                  //         Column(
                  //           crossAxisAlignment: CrossAxisAlignment.start,
                  //           children: [
                  //             SizedBox(
                  //               width: MediaQuery.of(context).size.width * 0.45,
                  //               child: Text(widget.featuredVideo?.topicName??"",
                  //                 style: interRegular.copyWith(
                  //                   fontSize: Dimensions.fontSizeLarge,
                  //                   fontWeight: FontWeight.w500,
                  //                   color: Colors.white,
                  //                 ),),
                  //             ),
                  //             const SizedBox(height: Dimensions.PADDING_SIZE_SMALL),
                  //           ],
                  //         ),
                  //         const Spacer(),
                  //         Padding(
                  //           padding: const EdgeInsets.only(right: Dimensions.PADDING_SIZE_SMALL),
                  //           child:       IconButton(       highlightColor: Colors.transparent,     hoverColor: Colors.transparent,
                  //             icon: const Icon(Icons.home, color: Colors.white),
                  //             onPressed: () {
                  //               Navigator.of(context).pushNamed(Routes.dashboard);
                  //             },
                  //           ),
                  //         ),
                  //         //Switch
                  //         // contentUrl!=""?
                  //         // SizedBox(
                  //         //   width: 130,
                  //         //   child: AnimatedToggleSwitch<bool>.dual(
                  //         //     current: positive,
                  //         //     first: false,
                  //         //     second: true,
                  //         //     dif: 20.0,
                  //         //     borderColor: Colors.transparent,
                  //         //     borderWidth: 5.0,
                  //         //     height: 55,
                  //         //     boxShadow: const [
                  //         //       BoxShadow(
                  //         //         color: ThemeManager.black26,
                  //         //         spreadRadius: 1,
                  //         //         blurRadius: 2,
                  //         //         offset: Offset(0, 1.5),
                  //         //       ),
                  //         //     ],
                  //         //     onChanged: (b) {
                  //         //       setState(() => positive = b);
                  //         //       return Future.delayed(const Duration(seconds: 2));
                  //         //     },
                  //         //     colorBuilder: (b) => b ? ThemeManager.videoColor : ThemeManager.lightBlue,
                  //         //     iconBuilder: (value) => value
                  //         //         ? const Icon(Icons.video_collection_sharp)
                  //         //         : const Icon(Icons.note_alt_sharp),
                  //         //     textBuilder: (value) => value
                  //         //         ? Center(child: Text('View Videos',
                  //         //       style: interRegular.copyWith(
                  //         //         fontSize: Dimensions.fontSizeSmall,
                  //         //         fontWeight: FontWeight.w600,
                  //         //         color: Theme.of(context).primaryColor,
                  //         //       ),))
                  //         //         : Center(child: Text('View Notes',
                  //         //       style: interRegular.copyWith(
                  //         //         fontSize: Dimensions.fontSizeSmall,
                  //         //         fontWeight: FontWeight.w600,
                  //         //         color: Theme.of(context).primaryColor,
                  //         //       ),)),
                  //         //   ),
                  //         // ):const SizedBox(),
                  //       ],
                  //     ),
                  //   ),
                  // ),

                  //PdfView
                  // if(positive==true)
                  //   SizedBox(
                  //     height: MediaQuery.of(context).size.height - videoHeight,
                  //     child: SfPdfViewer.network(
                  //       pdfBaseUrl+pdfUrl,
                  //       key: _pdfViewerKey,
                  //     ),
                  //   )

                  //More Chapters
                  // else
                  if (!isFullScreen)
                    Expanded(
                      child: Column(
                        children: [
                          Container(
                            margin: const EdgeInsets.fromLTRB(
                                AppTokens.s16, AppTokens.s12, AppTokens.s16, 0),
                            decoration: BoxDecoration(
                              color: AppTokens.surface2(context),
                              borderRadius: AppTokens.radius12,
                              border: Border.all(
                                  color: AppTokens.border(context),
                                  width: 0.5),
                            ),
                            child: TabBar(
                              onTap: (index) {
                                setState(() => currentIndex = index);
                              },
                              indicator: BoxDecoration(
                                color: AppTokens.surface(context),
                                borderRadius: AppTokens.radius12,
                                boxShadow: AppTokens.shadow1(context),
                              ),
                              indicatorSize: TabBarIndicatorSize.tab,
                              indicatorPadding: const EdgeInsets.all(3),
                              dividerColor: Colors.transparent,
                              labelColor: AppTokens.ink(context),
                              unselectedLabelColor: AppTokens.muted(context),
                              labelStyle: AppTokens.titleSm(context),
                              unselectedLabelStyle:
                                  AppTokens.titleSm(context).copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                              tabs: const [
                                Tab(text: "Chapters"),
                                Tab(text: "More Videos"),
                              ],
                            ),
                          ),
                          Expanded(
                            child: TabBarView(children: [
                              store.allvideotopicdetail.value?.message == null
                                  ? SizedBox(
                                      height:
                                          MediaQuery.of(context).size.height *
                                              0.43,
                                      child: ListView.builder(
                                        padding: EdgeInsets.zero,
                                        shrinkWrap: true,
                                        itemCount: store.allvideotopicdetail
                                            .value?.section?.length,
                                        itemBuilder:
                                            (BuildContext context, int index) {
                                          Section? allVideo = store
                                              .allvideotopicdetail
                                              .value
                                              ?.section?[index];
                                          return Column(
                                            children: [
                                              Padding(
                                                padding: const EdgeInsets
                                                    .symmetric(
                                                    horizontal: Dimensions
                                                            .PADDING_SIZE_LARGE *
                                                        1.2,
                                                    vertical: Dimensions
                                                            .PADDING_SIZE_SMALL *
                                                        1.1),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      allVideo?.sectionName ??
                                                          '',
                                                      style: interSemiBold
                                                          .copyWith(
                                                        fontSize: Dimensions
                                                            .fontSizeDefault,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color:
                                                            ThemeManager.black,
                                                      ),
                                                    ),
                                                    Row(
                                                      children: [
                                                        Text(
                                                          allVideo?.description ??
                                                              '',
                                                          style: interSemiBold
                                                              .copyWith(
                                                            fontSize: Dimensions
                                                                .fontSizeSmall,
                                                            fontWeight:
                                                                FontWeight.w400,
                                                            color: ThemeManager
                                                                .grey,
                                                          ),
                                                        ),
                                                        // Text('  •  ',
                                                        //   style: interSemiBold.copyWith(
                                                        //     fontSize: Dimensions.fontSizeSmall,
                                                        //     fontWeight: FontWeight.w400,
                                                        //     color: ThemeManager.grey,
                                                        //   ),),
                                                        // Text(convertSecondsToMinutesAndSeconds(allVideo?.sectionTime??''),
                                                        //   style: interSemiBold.copyWith(
                                                        //     fontSize: Dimensions.fontSizeSmall,
                                                        //     fontWeight: FontWeight.w400,
                                                        //     color: ThemeManager.grey,
                                                        //   ),),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              SizedBox(
                                                width: MediaQuery.of(context)
                                                    .size
                                                    .width,
                                                height: 1,
                                                child: Container(
                                                  color: ThemeManager.grey,
                                                ),
                                              ),
                                              (allVideo?.chapter?.isNotEmpty ??
                                                      false)
                                                  ? ListView.builder(
                                                      shrinkWrap: true,
                                                      physics:
                                                          const NeverScrollableScrollPhysics(),
                                                      itemCount: allVideo
                                                          ?.chapter?.length,
                                                      itemBuilder:
                                                          (BuildContext context,
                                                              int subIndex) {
                                                        return InkWell(
                                                          onTap: () {
                                                            String? timeString =
                                                                allVideo
                                                                    ?.chapter?[
                                                                        subIndex]
                                                                    .time;
                                                            if (timeString !=
                                                                null) {
                                                              seekToChapter(
                                                                  timeString);
                                                            }
                                                          },
                                                          child: Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              Padding(
                                                                padding: const EdgeInsets
                                                                    .symmetric(
                                                                    horizontal:
                                                                        Dimensions.PADDING_SIZE_LARGE *
                                                                            1.2,
                                                                    vertical:
                                                                        Dimensions.PADDING_SIZE_SMALL *
                                                                            1.1),
                                                                child: Column(
                                                                  crossAxisAlignment:
                                                                      CrossAxisAlignment
                                                                          .start,
                                                                  children: [
                                                                    Text(
                                                                      '${subIndex + 1}. ${allVideo?.chapter?[subIndex].title}',
                                                                      style: interSemiBold
                                                                          .copyWith(
                                                                        fontSize:
                                                                            Dimensions.fontSizeDefault,
                                                                        fontWeight:
                                                                            FontWeight.w600,
                                                                        color: ThemeManager
                                                                            .black,
                                                                      ),
                                                                    ),
                                                                    Text(
                                                                      'video • ${allVideo?.chapter?[subIndex].time != '' ? convertSecondsToMinutesAndSeconds(allVideo?.chapter?[subIndex].time ?? '') ?? '' : ''}',
                                                                      style: interSemiBold
                                                                          .copyWith(
                                                                        fontSize:
                                                                            Dimensions.fontSizeSmall,
                                                                        fontWeight:
                                                                            FontWeight.w400,
                                                                        color: ThemeManager
                                                                            .grey,
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        );
                                                      },
                                                    )
                                                  : const SizedBox()
                                            ],
                                          );
                                        },
                                      ),
                                    )
                                  : Center(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal:
                                                Dimensions.PADDING_SIZE_SMALL),
                                        child: Text(
                                          "We're sorry, there's no content available right now. Please check back later or explore other sections for more educational resources.",
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: ThemeManager.black,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // const SizedBox(
                                  //     height:
                                  //         Dimensions.PADDING_SIZE_SMALL * 2),
                                  // if((filteredTopics?.length??0) > 1)
                                  //   Padding(
                                  //     padding: const EdgeInsets.only(
                                  //       left: Dimensions.PADDING_SIZE_EXTRA_LARGE,
                                  //       right: Dimensions.PADDING_SIZE_DEFAULT,
                                  //     ),
                                  //     child: Text("More Chapters",
                                  //       style: interRegular.copyWith(
                                  //         fontSize: Dimensions.fontSizeLarge,
                                  //         fontWeight: FontWeight.w600,
                                  //         color: Theme.of(context).primaryColor,
                                  //       ),),
                                  //   ),
                                  // const SizedBox(
                                  //     height:
                                  //         Dimensions.PADDING_SIZE_SMALL * 2),
                                  Expanded(
                                    child: ListView.builder(
                                      padding: EdgeInsets.zero,
                                      itemCount: filteredTopics?.length,
                                      shrinkWrap: true,
                                      // physics:
                                      //     const NeverScrollableScrollPhysics(),
                                      itemBuilder:
                                          (BuildContext context, int index) {
                                        Videos? allTopic =
                                            filteredTopics?[index];
                                        return Container(
                                          padding: const EdgeInsets.only(
                                            left: Dimensions.PADDING_SIZE_SMALL,
                                            // top: Dimensions.PADDING_SIZE_SMALL,
                                            right: Dimensions
                                                .PADDING_SIZE_EXTRA_LARGE,
                                            bottom:
                                                Dimensions.PADDING_SIZE_LARGE,
                                          ),
                                          child: InkWell(
                                            onTap: () {
                                              Navigator.of(context).pushNamed(
                                                  Routes.featuredVideos,
                                                  arguments: {
                                                    "featuredVideo": allTopic,
                                                    "featuredVideoList":
                                                        widget.featuredVideoList
                                                  });
                                            },
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    // Container(
                                                    //   width: 80,
                                                    //   height: 40,
                                                    //   decoration: const BoxDecoration(
                                                    //     borderRadius: BorderRadius.only(
                                                    //       topLeft: Radius.circular(10),
                                                    //       bottomLeft: Radius.circular(10),
                                                    //     ),
                                                    //     image: DecorationImage(
                                                    //       image: AssetImage("assets/image/video_play_icon.png",),
                                                    //     ),
                                                    //   ),
                                                    // ),
                                                    SizedBox(
                                                      width: 80,
                                                      height: 40,
                                                      // decoration: const BoxDecoration(
                                                      //   borderRadius: BorderRadius.only(
                                                      //     topLeft: Radius.circular(10),
                                                      //     bottomLeft: Radius.circular(10),
                                                      //   ),
                                                      //   image: DecorationImage(
                                                      //     image: AssetImage("assets/image/video_play_icon.png",),
                                                      //   ),
                                                      // ),
                                                      child: SvgPicture.asset(
                                                        "assets/image/videocategoryIcon.svg",
                                                        color:
                                                            ThemeManager.black,
                                                      ),
                                                    ),
                                                    const SizedBox(
                                                      width: Dimensions
                                                          .PADDING_SIZE_EXTRA_SMALL,
                                                    ),
                                                    Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          allTopic?.topicName ??
                                                              "",
                                                          style: interSemiBold
                                                              .copyWith(
                                                            fontSize: Dimensions
                                                                .fontSizeSmall,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            color: ThemeManager
                                                                .black,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          height: Dimensions
                                                              .PADDING_SIZE_SMALL,
                                                        ),
                                                        // Text(allTopic?.description ?? "",
                                                        //   style: interSemiBold.copyWith(
                                                        //     fontSize: Dimensions.fontSizeDefault,
                                                        //     fontWeight: FontWeight.w500,
                                                        //     color: ThemeManager.black,
                                                        //   ),),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(
                                                  height: Dimensions
                                                      .PADDING_SIZE_DEFAULT,
                                                ),
                                                SizedBox(
                                                  width: MediaQuery.of(context)
                                                      .size
                                                      .width,
                                                  height: 1,
                                                  child: Container(
                                                    color:
                                                        const Color(0x0ffe6e4a),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  )
                                ],
                              ),
                            ]),
                          ),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
          // endDrawer: Drawer(
          //   child: Column(
          //     crossAxisAlignment: CrossAxisAlignment.end,
          //     children: [
          //       Expanded(
          //         child: SizedBox(
          //           height: MediaQuery.of(context).size.height,
          //           width: MediaQuery.of(context).size.width * 1,
          //           child: SfPdfViewer.network(
          //             // pdfBaseUrl + pdfUrl,
          //             "https://www.africau.edu/images/default/sample.pdf",
          //             key: _pdfViewerKey,
          //           ),
          //         ),
          //       ),
          //     ],
          //   ),
          // ),
        ),
        ),
      ),
    );
  }

  String? convertSecondsToMinutesAndSeconds(String? timeString) {
    if (timeString != '') {
      // Split the time string by colon and parse each part
      // debugPrint("timeString:$timeString");
      List<String>? parts = timeString?.split(':');
      int hours = int.parse(parts![0]);
      int minutes = int.parse(parts[1]);
      int seconds = int.parse(parts[2]);

      // Convert everything to total seconds
      int totalSeconds = (hours * 3600) + (minutes * 60) + seconds;

      // Convert total seconds to minutes and remaining seconds
      int convertedMinutes = totalSeconds ~/ 60;
      int convertedSeconds = totalSeconds % 60;

      return "${convertedMinutes}m ${convertedSeconds}s";
    }
    return null;
  }
}
