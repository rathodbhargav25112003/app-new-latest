// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:photo_view/photo_view.dart';
import 'package:shusruta_lms/helpers/app_tokens.dart';
import 'package:shusruta_lms/models/test_exampaper_list_model.dart';

/// Renders a question stem (text + inline images) for the exam flows.
///
/// Preserved public contract:
///   • Constructor `QuestionWidget({super.key, required TestData q})`
///   • Parses `q.questionText` for the legacy `----image----` markers
///     (`RegExp(r'----(.*?)----', multiLine: true)` replaced with
///     the sentinel "splittedImage"), splits into chunks, and emits
///     one paragraph + optional image per chunk — verbatim behaviour.
///   • The loop early-exit condition
///     `if (index >= (q.questionImg?.length ?? 0) - 1) break;` is
///     preserved exactly so visual layout over existing data is
///     unchanged.
///   • Tapping an image still launches a full-screen PhotoView dialog
///     with the `contained`→`covered * 2` scale range.
///   • Result is wrapped in a MobX `Observer` (retained for any
///     observable fields the caller may be mutating).
///
/// Cosmetic changes only: text uses AppTokens.bodyLg for the stem
/// and AppTokens.caption for the zoom hint; the inline image gets a
/// subtle rounded border; the dialog PhotoView gets themed framing.
class QuestionWidget extends StatelessWidget {
  const QuestionWidget({super.key, required this.q});

  final TestData q;

  @override
  Widget build(BuildContext context) {
    String questionTxt = q.questionText ?? '';
    questionTxt = questionTxt.replaceAllMapped(
      RegExp(r'----(.*?)----', multiLine: true),
      (match) => 'splittedImage',
    );
    final splittedText = questionTxt.split('splittedImage');

    final List<Widget> columns = [];
    int index = 0;
    for (final text in splittedText) {
      final List<Widget> questionImageWidget = [];
      if (q.questionImg?.isNotEmpty ?? false) {
        for (final base64String in q.questionImg!) {
          try {
            questionImageWidget.add(_ZoomableImage(url: base64String));
          } catch (e) {
            debugPrint('Error decoding base64 string: $e');
          }
        }
      }
      columns.add(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              text
                  .trim()
                  .replaceAll(RegExp(r'\n{2,}'), '\n')
                  .trim()
                  .replaceAll('--', '•'),
              textAlign: TextAlign.left,
              style: AppTokens.bodyLg(context).copyWith(
                fontWeight: FontWeight.w600,
                color: AppTokens.ink(context),
                height: 1.45,
              ),
            ),
            const SizedBox(height: AppTokens.s16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: questionImageWidget,
            ),
            if (questionImageWidget.isNotEmpty) ...[
              const SizedBox(height: AppTokens.s8),
              Text(
                'Tap the image to zoom In/Out',
                style: AppTokens.caption(context).copyWith(
                  color: AppTokens.muted(context),
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: AppTokens.s8),
            ],
          ],
        ),
      );
      index++;
      if (index >= (q.questionImg?.length ?? 0) - 1) {
        break;
      }
    }

    return Observer(
      builder: (context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: columns,
      ),
    );
  }
}

class _ZoomableImage extends StatelessWidget {
  const _ZoomableImage({required this.url});
  final String url;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (ctx) {
            return Dialog(
              backgroundColor: AppTokens.surface(ctx),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTokens.r16),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppTokens.r16),
                child: PhotoView(
                  imageProvider: NetworkImage(url),
                  minScale: PhotoViewComputedScale.contained,
                  maxScale: PhotoViewComputedScale.covered * 2,
                  backgroundDecoration:
                      BoxDecoration(color: AppTokens.surface(ctx)),
                ),
              ),
            );
          },
        );
      },
      child: Row(
        children: [
          Expanded(
            child: InteractiveViewer(
              scaleEnabled: false,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppTokens.r12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppTokens.r12),
                    child: Stack(
                      children: [
                        Image.network(url, fit: BoxFit.cover),
                        Container(color: Colors.transparent),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
