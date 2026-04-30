import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shusruta_lms/modules/bookmarks/store/bookmark_store.dart';

import '../../app/routes.dart';
import '../../helpers/colors.dart';
import '../../helpers/dimensions.dart';
import '../../helpers/empty_state.dart';
import '../../helpers/styles.dart';
import '../../models/bookmark_mainlist_model.dart';
import '../widgets/no_internet_connection.dart';

class BookMarkMainListScreen extends StatefulWidget {
  final bool? fromHome;
  const BookMarkMainListScreen({Key? key, this.fromHome}) : super(key: key);

  @override
  State<BookMarkMainListScreen> createState() => _BookMarkMainListScreenState();
  static Route<dynamic> route(RouteSettings routeSettings) {
    final arguments = routeSettings.arguments as Map<String, dynamic>;
    return CupertinoPageRoute(
      builder: (_) => BookMarkMainListScreen(fromHome: arguments['fromhome']),
    );
  }
}

class _BookMarkMainListScreenState extends State<BookMarkMainListScreen> {
  String query = '';

  @override
  void initState() {
    super.initState();
    final store = Provider.of<BookMarkStore>(context, listen: false);
    store.onBookMarkListAllApiCall(context);
  }

  @override
  Widget build(BuildContext context) {
    final store = Provider.of<BookMarkStore>(context, listen: false);
    return Scaffold(
        backgroundColor: ThemeManager.white,
        appBar: AppBar(
          elevation: 0,
          automaticallyImplyLeading: false,
          backgroundColor: ThemeManager.white,
          leading: widget.fromHome == true
              ? Padding(
                  padding: const EdgeInsets.only(
                      left: Dimensions.PADDING_SIZE_SMALL),
                  child: IconButton(
                    highlightColor: Colors.transparent,
                    hoverColor: Colors.transparent,
                    icon: Icon(Icons.arrow_back_ios,
                        color: ThemeManager.iconColor),
                    onPressed: () {
                      Navigator.of(context).pushNamed(Routes.dashboard);
                    },
                  ),
                )
              : const SizedBox(),
          centerTitle: true,
          title: Text(
            "Bookmarks",
            style: interRegular.copyWith(
              fontSize: Dimensions.fontSizeLarge,
              fontWeight: FontWeight.w500,
              color: ThemeManager.black,
            ),
          ),
        ),
        body: Column(
          children: [
            ///Search
            Padding(
              padding: const EdgeInsets.only(
                left: Dimensions.PADDING_SIZE_LARGE,
                top: Dimensions.PADDING_SIZE_SMALL,
                right: Dimensions.PADDING_SIZE_LARGE,
                bottom: Dimensions.PADDING_SIZE_LARGE,
              ),
              child: SizedBox(
                height: Dimensions.PADDING_SIZE_EXTRA_LARGE * 2,
                child: TextField(
                  cursorColor: Theme.of(context).disabledColor,
                  onChanged: (value) {
                    setState(() {
                      query = value;
                    });
                  },
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    prefixIconColor: Theme.of(context).disabledColor,
                    hintStyle: interRegular.copyWith(
                      fontSize: Dimensions.fontSizeSmall,
                      color: Theme.of(context).disabledColor,
                      fontWeight: FontWeight.w500,
                    ),
                    hintText: 'Search',
                    fillColor: Colors.white,
                    filled: true,
                    border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(Dimensions.RADIUS_DEFAULT),
                        borderSide: BorderSide(
                          color: Theme.of(context).disabledColor,
                        )),
                    focusedBorder: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(Dimensions.RADIUS_DEFAULT),
                      borderSide:
                          BorderSide(color: Theme.of(context).disabledColor),
                    ),
                  ),
                ),
              ),
            ),

            ///report list
            Expanded(
              child: Observer(
                builder: (_) {
                  if (store.bookmarkListAll.isEmpty) {
                    return const EmptyState(
                      icon: Icons.bookmark_outline_rounded,
                      title: 'No bookmarks yet',
                      subtitle:
                          'Tap the bookmark icon on any question while '
                          'reviewing solutions to save it here.',
                    );
                  }
                  return store.isConnected
                      ? store.isLoading
                          ? Center(
                              child: CircularProgressIndicator(
                              color: ThemeManager.primaryColor,
                            ))
                          : ListView.builder(
                              itemCount: store.bookmarkListAll.length,
                              shrinkWrap: true,
                              physics: const BouncingScrollPhysics(),
                              itemBuilder: (BuildContext context, int index) {
                                BookMarkMainListModel? bookMarkList =
                                    store.bookmarkListAll[index];
                                String categoryName =
                                    bookMarkList?.categoryName ?? "";
                                String subcategoryName =
                                    bookMarkList?.subcategoryName ?? "";
                                String topicName =
                                    bookMarkList?.topicName ?? "";

                                String displayText = categoryName;
                                String originalDate =
                                    bookMarkList?.createdAt ?? "";
                                DateTime parsedDate =
                                    DateTime.parse(originalDate);
                                final formatter = DateFormat('dd/MMMM/yyyy');
                                String formattedDate =
                                    formatter.format(parsedDate);

                                if (subcategoryName.isNotEmpty &&
                                    topicName.isNotEmpty) {
                                  displayText +=
                                      " | $subcategoryName | $topicName";
                                } else if (subcategoryName.isNotEmpty) {
                                  displayText += " | $subcategoryName";
                                } else if (topicName.isNotEmpty) {
                                  displayText += " | $topicName";
                                }
                                if (query.isNotEmpty &&
                                    (!displayText
                                        .toLowerCase()
                                        .contains(query.toLowerCase()))) {
                                  return Container();
                                }
                                return InkWell(
                                  onTap: () {
                                    String id = "";
                                    String type = "";
                                    String title = "";
                                    id = bookMarkList?.topicId != null
                                        ? bookMarkList?.topicId ?? ""
                                        : bookMarkList?.subcategoryId != null
                                            ? bookMarkList?.subcategoryId ?? ""
                                            : bookMarkList?.categoryId ?? "";

                                    type = bookMarkList?.topicId != null
                                        ? "topic"
                                        : bookMarkList?.subcategoryId != null
                                            ? "subcategory"
                                            : "category";

                                    title = bookMarkList?.topicId != null
                                        ? bookMarkList?.topicName ?? ""
                                        : bookMarkList?.subcategoryId != null
                                            ? bookMarkList?.subcategoryName ??
                                                ""
                                            : bookMarkList?.categoryName ?? "";

                                    Navigator.of(context).pushNamed(
                                        Routes.bookMarkExamList,
                                        arguments: {
                                          'id': id,
                                          'type': type,
                                          'title': title,
                                        });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.only(
                                      left: Dimensions.PADDING_SIZE_EXTRA_LARGE,
                                      top: Dimensions.PADDING_SIZE_SMALL,
                                      right:
                                          Dimensions.PADDING_SIZE_EXTRA_LARGE,
                                      // bottom: Dimensions.PADDING_SIZE_LARGE,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          displayText,
                                          style: interSemiBold.copyWith(
                                            fontSize:
                                                Dimensions.fontSizeDefault,
                                            fontWeight: FontWeight.w400,
                                            color: ThemeManager.black,
                                          ),
                                        ),
                                        const SizedBox(
                                          height:
                                              Dimensions.PADDING_SIZE_DEFAULT,
                                        ),
                                        Text(
                                          formattedDate,
                                          style: interRegular.copyWith(
                                            fontSize:
                                                Dimensions.fontSizeDefault,
                                            fontWeight: FontWeight.w400,
                                            color: Theme.of(context).hintColor,
                                          ),
                                        ),
                                        const SizedBox(
                                          height:
                                              Dimensions.PADDING_SIZE_DEFAULT,
                                        ),
                                        SizedBox(
                                          width:
                                              MediaQuery.of(context).size.width,
                                          height: 1,
                                          child: Container(
                                            color: const Color(0xFFE6E4A),
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                );
                              },
                            )
                      : const NoInternetScreen();
                },
              ),
            )
          ],
        ));
  }
}
