// ignore_for_file: deprecated_member_use, unused_import, unused_field, unused_element, avoid_print, use_build_context_synchronously, library_private_types_in_public_api, non_constant_identifier_names

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../helpers/app_tokens.dart';
import '../../helpers/colors.dart';
import '../../models/zoom_meeting_live_model.dart';
import 'store/live_class_main_screen_store.dart';

/// Upcoming live classes list — redesigned with AppTokens. Preserves the
/// constructor, static route factory, and MeetingStore wiring (Provider.of +
/// fetchUpComingMeeting from didChangeDependencies), plus the original
/// meetingStore.meetingUpcoming empty-state copy.
class LiveClassesUpcoming extends StatefulWidget {
  const LiveClassesUpcoming({super.key});

  static Route<dynamic> route(RouteSettings routeSettings) {
    return CupertinoPageRoute(
      builder: (_) => const LiveClassesUpcoming(),
    );
  }

  @override
  State<LiveClassesUpcoming> createState() => _LiveClassesUpcomingState();
}

class _LiveClassesUpcomingState extends State<LiveClassesUpcoming> {
  late MeetingStore meetingStore;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    meetingStore = Provider.of<MeetingStore>(context);
    meetingStore.fetchUpComingMeeting();
  }

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) {
        if (meetingStore.meetingUpcoming.isEmpty) {
          return const _EmptyUpcoming();
        }
        return ListView.builder(
          itemCount: meetingStore.meetingUpcoming.length,
          padding: const EdgeInsets.fromLTRB(
            AppTokens.s16,
            AppTokens.s16,
            AppTokens.s16,
            AppTokens.s24,
          ),
          itemBuilder: (context, index) {
            final ZoomLiveModel meeting = meetingStore.meetingUpcoming[index];

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
              child: _UpcomingCard(
                topic: meeting.topic ?? "",
                description: meeting.description ?? "",
                formattedDate: formattedDate,
                meridiem: dateStringhours,
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

class _UpcomingCard extends StatelessWidget {
  const _UpcomingCard({
    required this.topic,
    required this.description,
    required this.formattedDate,
    required this.meridiem,
  });

  final String topic;
  final String description;
  final String formattedDate;
  final String meridiem;

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
                    const _UpcomingPill(),
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
          _ScheduleBar(
            formattedDate: formattedDate,
            meridiem: meridiem,
          ),
        ],
      ),
    );
  }
}

class _UpcomingPill extends StatelessWidget {
  const _UpcomingPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.s8,
        vertical: AppTokens.s4,
      ),
      decoration: BoxDecoration(
        color: AppTokens.warningSoft(context),
        borderRadius: BorderRadius.circular(64),
        border: Border.all(
          color: AppTokens.warning(context).withOpacity(0.35),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.schedule_rounded,
            size: 12,
            color: AppTokens.warning(context),
          ),
          const SizedBox(width: AppTokens.s4),
          Text(
            "Upcoming",
            style: AppTokens.caption(context).copyWith(
              color: AppTokens.warning(context),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScheduleBar extends StatelessWidget {
  const _ScheduleBar({
    required this.formattedDate,
    required this.meridiem,
  });

  final String formattedDate;
  final String meridiem;

  @override
  Widget build(BuildContext context) {
    final displayText = formattedDate.isNotEmpty
        ? (meridiem.isNotEmpty ? "$formattedDate $meridiem" : formattedDate)
        : "";

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: AppTokens.s12),
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTokens.brand, AppTokens.brand2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.event_rounded,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: AppTokens.s8),
          Flexible(
            child: Text(
              displayText,
              overflow: TextOverflow.ellipsis,
              style: AppTokens.titleSm(context).copyWith(
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyUpcoming extends StatelessWidget {
  const _EmptyUpcoming();

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
                color: AppTokens.warningSoft(context),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.event_available_rounded,
                color: AppTokens.warning(context),
                size: 36,
              ),
            ),
            const SizedBox(height: AppTokens.s16),
            Text(
              "Stay Tuned!",
              textAlign: TextAlign.center,
              style: AppTokens.titleSm(context),
            ),
            const SizedBox(height: AppTokens.s4),
            Text(
              "Currently there are no classes scheduled.",
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
