// ignore_for_file: deprecated_member_use, library_private_types_in_public_api, unused_import, unused_field, unused_local_variable, experimental_member_use

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

import 'package:shusruta_lms/helpers/app_tokens.dart';
import 'package:shusruta_lms/helpers/colors.dart';

/// Shared widgets for the quill-powered note / explanation rendering used
/// across the reports module.
///
/// Preserved public contract:
///   • `CommonExplanationWidget({super.key, required controller,
///     textPercentage = 100})` — read-only quill viewer, scales text by
///     `textPercentage / 100` across all heading levels.
///   • `CommonTool({super.key, required controller, required onTap})` —
///     trimmed-down simple toolbar + a custom yellow-background
///     highlight button that calls `controller.formatSelection` then
///     `onTap()`.
///   • `DividerEmbedBuilder` / `ImageEmbedBuilder` with preserved
///     `key` strings ('divider' / 'image').
///   • `preprocessDocument(String json)` — replaces `"divider"` with
///     `"line-break"` and `--` with `-`.
class CommonExplanationWidget extends StatefulWidget {
  const CommonExplanationWidget(
      {super.key, required this.controller, this.textPercentage = 100});
  final int textPercentage;
  final QuillController controller;

  @override
  State<CommonExplanationWidget> createState() =>
      _CommonExplanationWidgetState();
}

class _CommonExplanationWidgetState extends State<CommonExplanationWidget> {
  final FocusNode _editorFocusNode = FocusNode();
  final ScrollController _editorScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    widget.controller.readOnly = true;
  }

  @override
  void dispose() {
    _editorFocusNode.dispose();
    _editorScrollController.dispose();
    super.dispose();
  }

  TextStyle _scaled(BuildContext context, double base, {double? height}) {
    return TextStyle(
      color: AppTokens.ink(context),
      fontSize: base * widget.textPercentage / 100,
      height: height,
    );
  }

  @override
  Widget build(BuildContext context) {
    return QuillEditor(
      focusNode: _editorFocusNode,
      scrollController: _editorScrollController,
      controller: widget.controller,
      config: QuillEditorConfig(
        readOnlyMouseCursor: SystemMouseCursors.text,
        enableAlwaysIndentOnTab: false,
        floatingCursorDisabled: true,
        checkBoxReadOnly: true,
        enableSelectionToolbar: false,
        placeholder: 'Start writing your notes...',
        paintCursorAboveText: true,
        customStyleBuilder: (attribute) {
          if (attribute == Attribute.h1) return _scaled(context, 22);
          if (attribute == Attribute.h2) return _scaled(context, 20);
          if (attribute == Attribute.h3) return _scaled(context, 18);
          if (attribute == Attribute.h4) return _scaled(context, 16);
          if (attribute == Attribute.h5) return _scaled(context, 14);
          if (attribute == Attribute.h6) return _scaled(context, 12);
          if (attribute == Attribute.blockQuote) {
            return _scaled(context, 16, height: 2.0);
          }
          if (attribute == Attribute.list) return _scaled(context, 16);
          if (attribute.key == Attribute.background.key &&
              ThemeManager.currentTheme == AppTheme.Dark) {
            return const TextStyle(color: Colors.black);
          }
          if (ThemeManager.currentTheme == AppTheme.Dark) {
            return TextStyle(color: ThemeManager.black);
          }
          return _scaled(context, 16);
        },
        embedBuilders: const [
          DividerEmbedBuilder(),
          ImageEmbedBuilder(),
        ],
        padding: const EdgeInsets.all(AppTokens.s16),
      ),
    );
  }
}

class CommonTool extends StatefulWidget {
  const CommonTool({super.key, required this.controller, required this.onTap});
  final QuillController controller;
  final void Function()? onTap;

  @override
  State<CommonTool> createState() => _CommonToolState();
}

class _CommonToolState extends State<CommonTool> {
  void _applyHighlightColor() {
    widget.controller.formatSelection(
        Attribute('background', AttributeScope.inline, '#FFFF00'));
    widget.onTap!();
  }

  @override
  Widget build(BuildContext context) {
    final iconColor = AppTokens.muted(context);
    return Row(
      children: [
        QuillSimpleToolbar(
          controller: widget.controller,
          config: QuillSimpleToolbarConfig(
            color: iconColor,
            buttonOptions: QuillSimpleToolbarButtonOptions(
              color: QuillToolbarColorButtonOptions(
                iconTheme: QuillIconTheme(
                  iconButtonUnselectedData: IconButtonData(color: iconColor),
                ),
              ),
            ),
            showClipboardPaste: false,
            showAlignmentButtons: false,
            showBoldButton: false,
            showCenterAlignment: false,
            showDividers: false,
            showCodeBlock: false,
            showFontSize: false,
            showClearFormat: false,
            showInlineCode: false,
            showFontFamily: false,
            showItalicButton: false,
            showSmallButton: false,
            showUnderLineButton: false,
            showStrikeThrough: false,
            showColorButton: false,
            showBackgroundColorButton: false,
            showLeftAlignment: false,
            showRightAlignment: false,
            showJustifyAlignment: false,
            showHeaderStyle: false,
            showListNumbers: false,
            showListBullets: false,
            showListCheck: false,
            showQuote: false,
            showIndent: false,
            showLink: false,
            showUndo: false,
            showRedo: false,
            showDirection: false,
            showSearchButton: false,
            showSubscript: false,
            showSuperscript: false,
            showClipboardCut: false,
            showClipboardCopy: false,
          ),
        ),
        IconButton(
          icon: Icon(Icons.format_color_fill,
              color: AppTokens.ink(context)),
          onPressed: _applyHighlightColor,
        ),
      ],
    );
  }
}

class DividerEmbedBuilder extends EmbedBuilder {
  const DividerEmbedBuilder();

  @override
  String get key => 'divider';

  @override
  Widget build(BuildContext context, EmbedContext embedContext) {
    return Divider(
      thickness: 2,
      height: 2,
      color: AppTokens.border(context),
    );
  }
}

class ImageEmbedBuilder extends EmbedBuilder {
  const ImageEmbedBuilder();

  @override
  String get key => 'image';

  @override
  Widget build(BuildContext context, EmbedContext embedContext) {
    final data = embedContext.node.value.data;
    if (data == null || data.toString().isEmpty) {
      return const SizedBox.shrink();
    }

    Widget imageWidget;
    if (data.startsWith('http')) {
      imageWidget = Image.network(data, fit: BoxFit.contain);
    } else {
      try {
        Uint8List bytes = base64Decode(data);
        imageWidget = Image.memory(bytes, fit: BoxFit.contain);
      } catch (_) {
        imageWidget = const SizedBox.shrink();
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTokens.s8),
      child: GestureDetector(
        onTap: () {
          showDialog(
            context: context,
            builder: (context) {
              return Dialog(
                backgroundColor: AppTokens.scaffold(context),
                child: InteractiveViewer(child: imageWidget),
              );
            },
          );
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppTokens.r8),
          child: imageWidget,
        ),
      ),
    );
  }
}

String preprocessDocument(String json) {
  return json
      .replaceAll('"divider"', '"line-break"')
      .replaceAll("--", "-"); // Replace with a supported type
}
