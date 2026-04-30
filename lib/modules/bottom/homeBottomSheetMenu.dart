import 'package:flutter/material.dart';

/// Menu — one tile in the More-bottom-sheet.
///
/// Originally only carried an SVG asset path. The MCQ Review v3 work
/// introduced a handful of brand-new entries (review queue, study
/// plan, scheduled sessions, performance trends, reading preferences)
/// for which we don't have matching SVG assets, so the model now
/// optionally carries a Material `IconData`. The tile builder picks
/// whichever of `iconUrl` / `materialIcon` is non-empty/non-null.
class Menu {
  final String title;
  final String iconUrl;
  final IconData? materialIcon;

  Menu({
    this.iconUrl = '',
    this.materialIcon,
    required this.title,
  }) : assert(
          iconUrl != '' || materialIcon != null,
          'Menu needs either an SVG iconUrl or a Material icon',
        );
}

//To add all more menu here

final List<Menu> homeBottomSheetMenu = [
  Menu(iconUrl: "assets/image/videoIcon.svg", title: "Videos"),
  Menu(iconUrl: "assets/image/notesIcon.svg", title: "Notes"),
  Menu(iconUrl: "assets/image/testIcon.svg", title: "Tests"),
  Menu(iconUrl: "assets/image/downloadNotesIcon.svg", title: "My Plan"),
  Menu(iconUrl: "assets/image/subscriptionIcon.svg", title: "Subscription Plan"),
  Menu(iconUrl: "assets/image/reportIcon.svg", title: "Analysis & Solutions"),
  Menu(iconUrl: "assets/image/mockReportIcon.svg", title: "Mock Exam Analysis"),
  Menu(iconUrl: "assets/image/downloadNotesIcon.svg", title: "Offline Notes"),
  Menu(iconUrl: "assets/image/notificationIcon.svg", title: "Notification"),
  Menu(iconUrl: "assets/image/bookmarkIcon.svg", title: "Bookmarks"),
  Menu(iconUrl: "assets/image/mockBookmarkIcon.svg", title: "Mock Exam Bookmarks"),

  // ── MCQ Review v3 — spaced repetition + planning + reading prefs ──
  Menu(materialIcon: Icons.repeat,         title: "Review Queue"),
  Menu(materialIcon: Icons.calendar_month, title: "Study Plan"),
  Menu(materialIcon: Icons.schedule,       title: "Scheduled Sessions"),
  Menu(materialIcon: Icons.trending_up,    title: "Performance Trends"),
  Menu(materialIcon: Icons.tune,           title: "Reading Preferences"),

  Menu(iconUrl: "assets/image/contactIcon.svg", title: "Contact Us"),
  Menu(iconUrl: "assets/image/emailIcon.svg", title: "Email"),
  Menu(iconUrl: "assets/image/privacyIcon.svg", title: "Privacy Policy"),
  Menu(iconUrl: "assets/image/refundIcon.svg", title: "Refund Policy"),
  Menu(iconUrl: "assets/image/termIcon.svg", title: "Terms & Conditions"),
  Menu(iconUrl: "assets/image/logout.svg", title: "Logout"),
  Menu(iconUrl: "assets/image/deleteAccount.svg", title: "Delete Account"),
];
