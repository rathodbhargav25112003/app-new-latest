// ignore_for_file: prefer_const_constructors, use_key_in_widget_constructors, prefer_const_constructors_in_immutables

import 'package:flutter/material.dart';
import '../helpers/app_tokens.dart';

/// [MarkdownParser] — lightweight markdown-to-widget renderer used by
/// downstream explanation / note previews.
///
/// UPGRADE (ruchir-new-app-upgrade-ui): visual polish only. Scaffold,
/// AppBar, typography, and bullet icons now read from [AppTokens]. The
/// public API is unchanged:
///   • constructor: `MarkdownParser({required this.content})`
///   • field: `final String content`
///   • method: `List<Widget> parseContent(String content)`
/// The content-parsing regex, line-prefix dispatch rules, and widget
/// ordering are preserved byte-for-byte.
class MarkdownParser extends StatelessWidget {
  final String content;

  MarkdownParser({required this.content});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTokens.scaffold(context),
      appBar: AppBar(
        backgroundColor: AppTokens.surface(context),
        foregroundColor: AppTokens.ink(context),
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: AppTokens.ink(context)),
        title: Text(
          "Formatted Content",
          style: AppTokens.titleMd(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: AppTokens.border(context),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppTokens.s16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: parseContent(content),
          ),
        ),
      ),
    );
  }

  // Function to parse content and return widgets
  List<Widget> parseContent(String content) {
    List<Widget> widgets = [];
    RegExp exp = RegExp(r'(^|\n)(#.*|\*\*.*\*\*|_.*_|~.*~|--.*|\$\$.*\$\$|[0-9]+[\.]+.*|\[.*\])');
    var matches = exp.allMatches(content);

    for (var match in matches) {
      String line = match.group(0)?.trim() ?? "";

      if (line.startsWith("# ")) {
        // Heading 1
        widgets.add(Builder(
          builder: (context) => Padding(
            padding: const EdgeInsets.only(bottom: AppTokens.s8),
            child: Text(
              line.substring(2),
              style: AppTokens.displayMd(context),
            ),
          ),
        ));
      } else if (line.startsWith("## ")) {
        // Heading 2
        widgets.add(Builder(
          builder: (context) => Padding(
            padding: const EdgeInsets.only(bottom: AppTokens.s8),
            child: Text(
              line.substring(3),
              style: AppTokens.titleLg(context),
            ),
          ),
        ));
      } else if (line.startsWith("### ")) {
        // Heading 3
        widgets.add(Builder(
          builder: (context) => Padding(
            padding: const EdgeInsets.only(bottom: AppTokens.s8),
            child: Text(
              line.substring(4),
              style: AppTokens.titleMd(context),
            ),
          ),
        ));
      } else if (line.startsWith("**") && line.endsWith("**")) {
        // Bold Text
        widgets.add(Builder(
          builder: (context) => Padding(
            padding: const EdgeInsets.only(bottom: AppTokens.s4),
            child: Text(
              line.substring(2, line.length - 2),
              style: AppTokens.titleSm(context).copyWith(
                fontWeight: FontWeight.w700,
                color: AppTokens.ink(context),
              ),
            ),
          ),
        ));
      } else if (line.startsWith("_") && line.endsWith("_")) {
        // Italic Text
        widgets.add(Builder(
          builder: (context) => Padding(
            padding: const EdgeInsets.only(bottom: AppTokens.s4),
            child: Text(
              line.substring(1, line.length - 1),
              style: AppTokens.body(context).copyWith(
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ));
      } else if (line.startsWith("~") && line.endsWith("~")) {
        // Underlined Text
        widgets.add(Builder(
          builder: (context) => Padding(
            padding: const EdgeInsets.only(bottom: AppTokens.s4),
            child: Text(
              line.substring(1, line.length - 1),
              style: AppTokens.body(context).copyWith(
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ));
      } else if (line.startsWith("/\$/\$") && line.endsWith("/\$/\$")) {
        // Text for textbook reference (underlined + bold)
        widgets.add(Builder(
          builder: (context) => Padding(
            padding: const EdgeInsets.only(bottom: AppTokens.s4),
            child: Text(
              line.substring(2, line.length - 2),
              style: AppTokens.titleSm(context).copyWith(
                fontWeight: FontWeight.w700,
                decoration: TextDecoration.underline,
                color: AppTokens.accent(context),
              ),
            ),
          ),
        ));
      } else if (line.startsWith("-- ")) {
        // Bullet points
        widgets.add(Builder(
          builder: (context) => Padding(
            padding: const EdgeInsets.only(bottom: AppTokens.s4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Icon(
                    Icons.circle,
                    size: 8,
                    color: AppTokens.ink2(context),
                  ),
                ),
                const SizedBox(width: AppTokens.s8),
                Expanded(
                  child: Text(
                    line.substring(3),
                    style: AppTokens.body(context),
                  ),
                ),
              ],
            ),
          ),
        ));
      } else if (line.startsWith("> --")) {
        // Subpoints (Level 1)
        widgets.add(Builder(
          builder: (context) => Padding(
            padding: const EdgeInsets.only(
              left: AppTokens.s16,
              bottom: AppTokens.s4,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Icon(
                    Icons.arrow_right,
                    size: 14,
                    color: AppTokens.muted(context),
                  ),
                ),
                const SizedBox(width: AppTokens.s8),
                Expanded(
                  child: Text(
                    line.substring(4),
                    style: AppTokens.body(context),
                  ),
                ),
              ],
            ),
          ),
        ));
      } else if (line.startsWith(">> --")) {
        // Subpoints (Level 2)
        widgets.add(Builder(
          builder: (context) => Padding(
            padding: const EdgeInsets.only(
              left: AppTokens.s24,
              bottom: AppTokens.s4,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Icon(
                    Icons.arrow_forward,
                    size: 12,
                    color: AppTokens.muted(context),
                  ),
                ),
                const SizedBox(width: AppTokens.s8),
                Expanded(
                  child: Text(
                    line.substring(5),
                    style: AppTokens.body(context),
                  ),
                ),
              ],
            ),
          ),
        ));
      } else if (line.startsWith("[ ]")) {
        // Unchecked checkbox
        widgets.add(Builder(
          builder: (context) => Padding(
            padding: const EdgeInsets.only(bottom: AppTokens.s4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: false,
                  onChanged: (_) {},
                  activeColor: AppTokens.accent(context),
                  side: BorderSide(
                    color: AppTokens.borderStrong(context),
                  ),
                ),
                const SizedBox(width: AppTokens.s8),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      line.substring(3),
                      style: AppTokens.body(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ));
      } else if (line.startsWith("[x]")) {
        // Checked checkbox
        widgets.add(Builder(
          builder: (context) => Padding(
            padding: const EdgeInsets.only(bottom: AppTokens.s4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: true,
                  onChanged: (_) {},
                  activeColor: AppTokens.accent(context),
                  side: BorderSide(
                    color: AppTokens.borderStrong(context),
                  ),
                ),
                const SizedBox(width: AppTokens.s8),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      line.substring(3),
                      style: AppTokens.body(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ));
      }
    }

    return widgets;
  }
}
