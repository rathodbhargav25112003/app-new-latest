// ignore_for_file: deprecated_member_use, library_private_types_in_public_api, unused_import, use_super_parameters, unused_field, unused_local_variable, non_constant_identifier_names, dead_code, prefer_final_fields, unnecessary_import

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

import 'package:shusruta_lms/helpers/app_tokens.dart';
import 'package:shusruta_lms/helpers/colors.dart';
import 'package:shusruta_lms/helpers/dimensions.dart';

/// Compact description widget for testimonial cards — truncates long quotes,
/// measures overflow with `TextPainter` and reveals the full quote in an
/// `AlertDialog` (with name + star rating) when "See more" is tapped.
///
/// Preserved public contract:
///   • `CustomTestimonialDescriptionWidget({super.key, required description,
///     required name, required rating})`.
///   • Dialog shows name, star rating, full description, "Close" button.
///   • Internal 100-char visual truncation for the card preview.
class CustomTestimonialDescriptionWidget extends StatefulWidget {
  final String name;
  final String description;
  final int rating;

  const CustomTestimonialDescriptionWidget({
    super.key,
    required this.description,
    required this.name,
    required this.rating,
  });

  @override
  _CustomTestimonialDescriptionWidgetState createState() =>
      _CustomTestimonialDescriptionWidgetState();
}

class _CustomTestimonialDescriptionWidgetState
    extends State<CustomTestimonialDescriptionWidget> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final baseStyle = AppTokens.caption(context).copyWith(
          color: AppTokens.muted(context),
          fontWeight: FontWeight.w400,
          height: 1.35,
        );

        final textSpan = TextSpan(
          text: widget.description,
          style: baseStyle,
        );
        final textPainter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
          maxLines: _expanded ? null : 4,
        );
        textPainter.layout(maxWidth: constraints.maxWidth);

        final isLongText = textPainter.didExceedMaxLines;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _expanded
                  ? widget.description
                  : _truncateDescription(widget.description),
              style: baseStyle,
              maxLines: _expanded ? null : 4,
              overflow: TextOverflow.ellipsis,
            ),
            if (isLongText)
              GestureDetector(
                onTap: () => _openFullQuote(context),
                child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    'See more',
                    style: AppTokens.caption(context).copyWith(
                      color: AppTokens.accent(context),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  void _openFullQuote(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTokens.surface(context),
          surfaceTintColor: AppTokens.surface(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.r16),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.name,
                style: AppTokens.titleSm(context).copyWith(
                  color: AppTokens.ink(context),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppTokens.s8),
              RatingBar.builder(
                initialRating: widget.rating.toDouble(),
                direction: Axis.horizontal,
                itemCount: 5,
                itemSize: 20,
                itemPadding: const EdgeInsets.only(right: 4),
                itemBuilder: (context, _) => const Icon(
                  Icons.star,
                  color: Colors.amber,
                ),
                ignoreGestures: true,
                onRatingUpdate: (_) {},
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Text(
              widget.description,
              style: AppTokens.body(context).copyWith(
                color: AppTokens.muted(context),
                fontWeight: FontWeight.w400,
                height: 1.4,
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Close',
                style: AppTokens.body(context).copyWith(
                  color: AppTokens.accent(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  String _truncateDescription(String description) {
    if (description.length <= 100) {
      return description;
    } else {
      return "${description.substring(0, 100)}...";
    }
  }
}
