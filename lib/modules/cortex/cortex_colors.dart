// Cortex AI — local color tokens.
//
// The Cortex feature uses the app's brand primary color throughout. The
// app's `helpers/colors.dart` exposes it as `ThemeManager.primaryColor`
// (a static getter, not a top-level constant) — so importing the bare
// name doesn't work. This file gives Cortex code a clean top-level alias.
//
// If your app theme changes, this is the only file to update.

import 'package:flutter/material.dart';
import '../../helpers/colors.dart';

/// Cortex-feature primary brand color. Resolves through ThemeManager so
/// it tracks dark / light mode automatically.
Color get primaryColor => ThemeManager.primaryColor;
