import 'dart:developer';
import 'package:lottie/lottie.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:shusruta_lms/helpers/colors.dart';
import 'package:shusruta_lms/helpers/styles.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:markdown_quill/markdown_quill.dart';
import 'package:shusruta_lms/helpers/dimensions.dart';
import 'package:shusruta_lms/modules/dashboard/search_screen.dart';

class SearchFiled extends StatelessWidget {
  const SearchFiled({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: Dimensions.PADDING_SIZE_EXTRA_LARGE * 2,
      child: TextField(
        enableInteractiveSelection: false,
        onTap: () {
          Navigator.push(
              context,
              CupertinoPageRoute(
                builder: (context) => const SearchScreen(
                  text: "",
                  selectedValue: "All Category",
                ),
              ));
        },
        cursorColor: ThemeManager.grey,
        readOnly: true,
        decoration: InputDecoration(
          suffixIcon: const Icon(CupertinoIcons.search),
          suffixIconColor: ThemeManager.black,
          hintStyle: interRegular.copyWith(
              fontSize: Dimensions.fontSizeDefault,
              color: ThemeManager.grey,
              fontWeight: FontWeight.w500,
              fontFamily: 'DM Sans'),
          hintText: 'Search',
          fillColor: ThemeManager.white,
          filled: true,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Dimensions.RADIUS_DEFAULT),
              borderSide: BorderSide(
                color: ThemeManager.mainBorder,
              )),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(Dimensions.RADIUS_DEFAULT),
            borderSide: BorderSide(
              color: ThemeManager.mainBorder,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(Dimensions.RADIUS_DEFAULT),
            borderSide: BorderSide(
              color: ThemeManager.mainBorder,
            ),
          ),
        ),
      ),
    );
  }
}

class BookmarkWidget extends StatelessWidget {
  const BookmarkWidget({super.key, required this.isSelected});
  final bool isSelected;
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      width: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: ThemeManager.grey4, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(0.0),
        child: Icon(
          isSelected ? Icons.bookmark : Icons.bookmark_outline,
          color: ThemeManager.grey4,
          size: 15,
        ),
      ),
    );
  }
}

List<dynamic> parseCustomSyntax(String input) {
  final List<dynamic> result = [];
  final mdDocument = md.Document(encodeHtml: false);
  final mdToDelta = MarkdownToDelta(
    markdownDocument: mdDocument,
  );

  final delta = mdToDelta.convert(input);
  // log(delta.toString());
  for (final line in delta.operations) {
    result.add(line.toJson());
  }
  return result;
}

class LottieLoadingBox extends StatelessWidget {
  final double width;
  final double height;

  const LottieLoadingBox({
    super.key,
    this.width = 100.0, // Default size
    this.height = 100.0, // Default size
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white, // Background color of the box
      ),
      child: Center(
        child: Lottie.asset(
          "assets/image/loading.json",
          width: width * 0.8, // Scale animation to fit inside the box
          height: height * 0.8,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
