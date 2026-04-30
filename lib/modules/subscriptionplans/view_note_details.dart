// ignore_for_file: deprecated_member_use, unused_import, unnecessary_import

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shusruta_lms/modules/subscriptionplans/save_address_bottom_sheet.dart';
import '../../helpers/app_tokens.dart';
import '../../helpers/colors.dart';
import '../../helpers/dimensions.dart';
import '../../helpers/styles.dart';
import 'model/book_by_subscription_id_model.dart';

/// ViewNoteDetailsScreen — preview of a book's notes overview for a
/// given subscription. Reads [getBookSub] (a [BookBySubscriptionIdModel])
/// and renders cover art, a price tag, and a chapter-by-chapter list.
///
/// Public surface preserved exactly:
///   • class [ViewNoteDetailsScreen] + const constructor
///     `{super.key, required getBookSub}`
///   • static [route] factory reading `arguments['bookDetails']`
///   • No data flow / API calls inside this screen — purely a
///     read-only renderer.
class ViewNoteDetailsScreen extends StatefulWidget {
  final BookBySubscriptionIdModel getBookSub;
  const ViewNoteDetailsScreen({super.key, required this.getBookSub});

  @override
  State<ViewNoteDetailsScreen> createState() => _ViewNoteDetailsScreenState();
  static Route<dynamic> route(RouteSettings routeSettings) {
    final arguments = routeSettings.arguments as Map<String, dynamic>;
    return CupertinoPageRoute(
      builder: (_) => ViewNoteDetailsScreen(
        getBookSub: arguments['bookDetails'],
      ),
    );
  }
}

class _ViewNoteDetailsScreenState extends State<ViewNoteDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTokens.scaffold(context),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppTokens.surface(context),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Row(
          children: [
            IconButton(
              highlightColor: Colors.transparent,
              hoverColor: Colors.transparent,
              onPressed: () {
                Navigator.pop(context);
              },
              icon: Icon(
                Icons.arrow_back_ios,
                color: AppTokens.ink(context),
                size: 18,
              ),
            ),
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.4,
              child: Text(
                "Select Notes",
                style: AppTokens.titleMd(context).copyWith(
                  color: AppTokens.ink(context),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
      body: Container(
        height: MediaQuery.of(context).size.height,
        color: AppTokens.scaffold(context),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: Dimensions.PADDING_SIZE_DEFAULT),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(
                  height: Dimensions.PADDING_SIZE_LARGE * 1.1,
                ),
                // Book hero card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppTokens.s16),
                  decoration: BoxDecoration(
                    color: AppTokens.surface(context),
                    borderRadius: BorderRadius.circular(AppTokens.r20),
                    border: Border.all(color: AppTokens.border(context)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width,
                    child: Image.asset(
                      "assets/image/viewNote.png",
                      fit: BoxFit.fitWidth,
                    ),
                  ),
                ),
                const SizedBox(
                  height: Dimensions.PADDING_SIZE_LARGE * 1.1,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.getBookSub.bookName ?? '',
                            style: AppTokens.titleMd(context).copyWith(
                              color: AppTokens.ink(context),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(
                            height: Dimensions.PADDING_SIZE_SMALL * 1.2,
                          ),
                          Row(
                            children: [
                              Text(
                                widget.getBookSub.bookType ?? '',
                                style: AppTokens.caption(context).copyWith(
                                  color: AppTokens.muted(context),
                                ),
                              ),
                              const SizedBox(
                                  width:
                                      Dimensions.PADDING_SIZE_EXTRA_SMALL),
                              Container(
                                height: Dimensions.PADDING_SIZE_SMALL * 1.7,
                                alignment: Alignment.center,
                                padding: const EdgeInsets.symmetric(
                                  horizontal:
                                      Dimensions.PADDING_SIZE_EXTRA_SMALL *
                                          1.6,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius:
                                      BorderRadius.circular(AppTokens.r8),
                                  gradient: const LinearGradient(
                                    colors: [
                                      AppTokens.brand,
                                      AppTokens.brand2,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                child: Text(
                                  "${widget.getBookSub.volume} Volumes",
                                  style: AppTokens.caption(context).copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                    const SizedBox(width: AppTokens.s12),
                    Text(
                      "\u20B9 ${widget.getBookSub.price?.toInt()}/-",
                      style: AppTokens.titleLg(context).copyWith(
                        color: AppTokens.ink(context),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  height: Dimensions.PADDING_SIZE_LARGE * 1.2,
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "Notes Overview ",
                      style: AppTokens.titleSm(context).copyWith(
                        color: AppTokens.ink(context),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      "(Volumes)",
                      style: AppTokens.caption(context).copyWith(
                        color: AppTokens.muted(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  height: Dimensions.PADDING_SIZE_SMALL * 1.2,
                ),
                ListView.builder(
                  itemCount: widget.getBookSub.notesOverview?.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (BuildContext context, int index) {
                    NotesOverviewModel? noteView =
                        widget.getBookSub.notesOverview?[index];
                    return Container(
                      margin: const EdgeInsets.only(
                          bottom: Dimensions.PADDING_SIZE_SMALL * 1.2),
                      padding: const EdgeInsets.fromLTRB(
                          4, 4, Dimensions.PADDING_SIZE_DEFAULT, 4),
                      decoration: BoxDecoration(
                        color: AppTokens.surface(context),
                        borderRadius: BorderRadius.circular(AppTokens.r16),
                        border: Border.all(color: AppTokens.border(context)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            height: Dimensions.PADDING_SIZE_SMALL * 2.7,
                            width: Dimensions.PADDING_SIZE_SMALL * 2.7,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppTokens.brand,
                                  AppTokens.brand2,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              (index + 1).toString().padLeft(2, '0'),
                              style: AppTokens.caption(context).copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(
                            width: Dimensions.PADDING_SIZE_EXTRA_SMALL * 1.6,
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  noteView?.chapterName ?? '',
                                  style: AppTokens.body(context).copyWith(
                                    color: AppTokens.ink(context),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  "Chapter - ${noteView?.chapter}",
                                  style: AppTokens.caption(context).copyWith(
                                    color: AppTokens.muted(context),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppTokens.s8),
                          Text(
                            noteView?.pageNumber ?? '',
                            style: AppTokens.caption(context).copyWith(
                              color: AppTokens.muted(context),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
