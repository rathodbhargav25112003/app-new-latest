import 'dart:io';
import 'package:flutter/material.dart';


/// Prevents default menu.
void preventDefaultContextMenu() {
  // ignore: avoid_returning_null_for_void
  return null;
}

/// Gets platform type.
String getPlatformType() {
  return Platform.operatingSystem;
}

void scrollToTop(ScrollController scrollController) {
  scrollController.animateTo(
    0, // Offset to scroll to (0 = top)
    duration: Duration(milliseconds: 300), // Smooth scrolling duration
    curve: Curves.easeInOut, // Animation curve
  );
}
