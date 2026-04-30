// ignore_for_file: deprecated_member_use, unused_import, unused_field, unused_element, avoid_print, use_build_context_synchronously, library_private_types_in_public_api, non_constant_identifier_names

import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:overlay_pop_up/overlay_pop_up.dart';
import 'package:provider/provider.dart';
import 'package:store_redirect/store_redirect.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/routes.dart';
import '../../helpers/app_tokens.dart';
import '../../helpers/colors.dart';
import '../../models/zoom_meeting_live_model.dart';
import '../widgets/no_internet_connection.dart';
import 'store/live_class_main_screen_store.dart';

/// Live classes list — redesigned with AppTokens. Preserves the constructor,
/// static route factory, MeetingStore Provider lookup + fetchMeetings /
/// fetchUpComingMeeting calls from didChangeDependencies, overlay status
/// probe, launchZoomMeeting() platform-guarded launcher, and the original
/// meetingStore.meetings empty-state copy.
class LiveClass extends StatefulWidget {
  const LiveClass({super.key});

  @override
  State<LiveClass> createState() => _LiveClassState();

  static Route<dynamic> route(RouteSettings routeSettings) {
    return CupertinoPageRoute(
      builder: (_) => const LiveClass(),
    );
  }
}

class _LiveClassState extends State<LiveClass> {
  bool isActivex = false;
  late MeetingStore meetingStore;

  @override
  void initState() {
    super.initState();
    overlayStatus();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    meetingStore = Provider.of<MeetingStore>(context);
    meetingStore.fetchMeetings();
    meetingStore.fetchUpComingMeeting();
  }

  Future<void> overlayStatus() async {
    isActivex = await OverlayPopUp.isActive();
    setState(() {});
  }

  Future<void> launchZoomMeeting(
      String zoomlink, String pdfUrl, String title) async {
    final meetingUrl = zoomlink;

    if (Platform.isIOS) {
      debugPrint("zoomurl$meetingUrl");
      await canLaunchUrl(Uri.parse(meetingUrl));
      await launchUrl(Uri.parse(meetingUrl));
      StoreRedirect.redirect(iOSAppId: "id546505307");
    } else if (Platform.isAndroid) {
      if (await canLaunchUrl(Uri.parse(meetingUrl))) {
        await launchUrl(Uri.parse(meetingUrl));
      } else {
        const zoomPlayStoreUrl =
            'https://play.google.com/store/apps/details?id=us.zoom.videomeetings';
        if (await canLaunch(zoomPlayStoreUrl)) {
          await launch(zoomPlayStoreUrl);
        } else {
          print('Could not open the play store link.');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) {
        if (meetingStore.meetings.isEmpty) {
          return const _EmptyLive();
        }
        return ListView.builder(
          itemCount: meetingStore.meetings.length,
          padding: const EdgeInsets.fromLTRB(
            AppTokens.s16,
            AppTokens.s16,
            AppTokens.s16,
            AppTokens.s24,
          ),
          itemBuilder: (context, index) {
            final ZoomLiveModel meeting = meetingStore.meetings[index];

            final dateString = meeting.start_time ?? "";
            String formattedDate = "";
            String dateStringhours = "";

            try {
              final dateTime =
                  DateFormat("d MMM, h:mm a").parse(dateString);
              formattedDate = DateFormat("d MMM, h:mm a").format(dateTime);
              dateStringhours =
                  DateFormat('a').format(dateTime).toUpperCase();
            } catch (e) {
              print("Date parsing error: $e");
              formattedDate =
                  dateString.isNotEmpty ? dateString : "Date not available";
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: AppTokens.s12),
              child: _LiveClassCard(
                topic: meeting.topic ?? "",
                description: meeting.description ?? "",
                formattedDate: formattedDate,
                meridiem: dateStringhours,
                onJoin: () => launchZoomMeeting(
                  meeting.mobileAppUrl ?? "",
                  meeting.pdf_url ?? "",
                  meeting.topic ?? "",
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ============================================================
//                        Primitives
// ============================================================

class _LiveClassCard extends StatelessWidget {
  const _LiveClassCard({
    required this.topic,
    required this.description,
    required this.formattedDate,
    required this.meridiem,
    required this.onJoin,
  });

  final String topic;
  final String description;
  final String formattedDate;
  final String meridiem;
  final VoidCallback onJoin;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTokens.surface(context),
        borderRadius: AppTokens.radius16,
        border: Border.all(color: AppTokens.border(context)),
        boxShadow: AppTokens.shadow1(context),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTokens.s16,
              AppTokens.s16,
              AppTokens.s12,
              AppTokens.s12,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        topic,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTokens.titleSm(context),
                      ),
                    ),
                    const SizedBox(width: AppTokens.s8),
                    const _LivePill(),
                  ],
                ),
                const SizedBox(height: AppTokens.s12),
                Row(
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      size: 16,
                      color: AppTokens.accent(context),
                    ),
                    const SizedBox(width: AppTokens.s4),
                    Flexible(
                      child: Text(
                        formattedDate.isNotEmpty
                            ? (meridiem.isNotEmpty
                                ? "$formattedDate $meridiem"
                                : formattedDate)
                            : "",
                        style: AppTokens.caption(context).copyWith(
                          color: AppTokens.ink(context),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                if (description.trim().isNotEmpty) ...[
                  const SizedBox(height: AppTokens.s8),
                  Text(
                    description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: AppTokens.body(context).copyWith(
                      color: AppTokens.ink2(context),
                    ),
                  ),
                ],
              ],
            ),
          ),
          _JoinNowBar(onTap: onJoin),
        ],
      ),
    );
  }
}

class _LivePill extends StatelessWidget {
  const _LivePill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.s8,
        vertical: AppTokens.s4,
      ),
      decoration: BoxDecoration(
        color: AppTokens.danger(context),
        borderRadius: BorderRadius.circular(64),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppTokens.s4),
          Text(
            "Live",
            style: AppTokens.caption(context).copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _JoinNowBar extends StatelessWidget {
  const _JoinNowBar({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Ink(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTokens.brand, AppTokens.brand2],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: AppTokens.s12),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.play_circle_fill_rounded,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: AppTokens.s8),
              Text(
                "Join Now",
                style: AppTokens.titleSm(context).copyWith(
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyLive extends StatelessWidget {
  const _EmptyLive();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.s24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: AppTokens.accentSoft(context),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.videocam_off_rounded,
                color: AppTokens.accent(context),
                size: 36,
              ),
            ),
            const SizedBox(height: AppTokens.s16),
            Text(
              "No Live Classes Scheduled",
              textAlign: TextAlign.center,
              style: AppTokens.titleSm(context),
            ),
            const SizedBox(height: AppTokens.s4),
            Text(
              "Stay tuned for upcoming sessions!",
              textAlign: TextAlign.center,
              style: AppTokens.body(context).copyWith(
                color: AppTokens.ink2(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
