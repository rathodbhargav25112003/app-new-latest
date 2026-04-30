import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shusruta_lms/modules/dashboard/store/home_store.dart';
import '../../app/routes.dart';
import '../../helpers/colors.dart';
import '../../helpers/dimensions.dart';
import '../../helpers/styles.dart';
import '../../helpers/app_tokens.dart';
import '../../models/notification_list_model.dart';
import '../widgets/no_internet_connection.dart';

class NotificationsScreen extends StatefulWidget {
  final bool? fromHome;
  const NotificationsScreen({Key? key, this.fromHome}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
  static Route<dynamic> route(RouteSettings routeSettings) {
    final arguments = routeSettings.arguments as Map<String, dynamic>;
    return CupertinoPageRoute(
      builder: (_) => NotificationsScreen(fromHome: arguments['fromhome']),
    );
  }
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    final store = Provider.of<HomeStore>(context, listen: false);
    store.onGetNotificationListApiCall();
  }

  Future<void> _clearNotification() async {
    final store = Provider.of<HomeStore>(context, listen: false);
    await store.onDeleteNotificationCall();
    await store.onGetNotificationListApiCall();
    Navigator.pop(context);
  }

  Future<void> showDialogs(context) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ThemeManager.white,
        surfaceTintColor: ThemeManager.white,
        contentPadding: EdgeInsets.only(
            top: Dimensions.PADDING_SIZE_LARGE * 1.1,
            left: Dimensions.PADDING_SIZE_DEFAULT * 2,
            right: Dimensions.PADDING_SIZE_DEFAULT * 2,
            bottom: Dimensions.PADDING_SIZE_SMALL * 2.3),
        alignment: Alignment.center,
        actionsPadding: EdgeInsets.only(
            left: Dimensions.PADDING_SIZE_LARGE,
            right: Dimensions.PADDING_SIZE_LARGE,
            bottom: Dimensions.PADDING_SIZE_EXTRA_LARGE),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Text(
          'Do you want to clear notifications? ',
          style: interRegular.copyWith(
            fontSize: Dimensions.fontSizeExtraLarge,
            fontWeight: FontWeight.w400,
            color: ThemeManager.black,
          ),
          textAlign: TextAlign.center,
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => Navigator.pop(context, false),
                  child: Container(
                    height: Dimensions.PADDING_SIZE_DEFAULT * 3,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: ThemeManager.primaryColor,
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [
                        ///first
                        BoxShadow(
                            offset: Offset(0, 0),
                            color: ThemeManager.black.withOpacity(0.04),
                            blurRadius: 0,
                            spreadRadius: 0),

                        ///second
                        BoxShadow(
                            offset: Offset(0, 4.62),
                            color: ThemeManager.black.withOpacity(0.04),
                            blurRadius: 10.165,
                            spreadRadius: 0),

                        ///third
                        BoxShadow(
                            offset: Offset(0, 19.40),
                            color: ThemeManager.black.withOpacity(0.03),
                            blurRadius: 19.40,
                            spreadRadius: 0),

                        ///four
                        BoxShadow(
                            offset: Offset(0, 43.436),
                            color: ThemeManager.black.withOpacity(0.02),
                            blurRadius: 25.876,
                            spreadRadius: 0),

                        ///five
                        BoxShadow(
                            offset: Offset(0, 76.706),
                            color: ThemeManager.black.withOpacity(0.01),
                            blurRadius: 30.497,
                            spreadRadius: 0),

                        ///six
                        BoxShadow(
                            offset: Offset(0, 120.142),
                            color: ThemeManager.black.withOpacity(0),
                            blurRadius: 33.270,
                            spreadRadius: 0),
                      ],
                    ),
                    child: Text('No',
                        style: interRegular.copyWith(
                          fontSize: Dimensions.fontSizeDefault,
                          fontWeight: FontWeight.w500,
                          color: ThemeManager.white,
                        )),
                  ),
                ),
              ),
              SizedBox(
                width: Dimensions.PADDING_SIZE_SMALL * 1.6,
              ),
              Expanded(
                child: InkWell(
                  onTap: () {
                    _clearNotification();
                  },
                  child: Container(
                    height: Dimensions.PADDING_SIZE_DEFAULT * 3,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: ThemeManager.primaryColor),
                      boxShadow: [
                        ///first
                        BoxShadow(
                            offset: Offset(0, 0),
                            color: ThemeManager.black.withOpacity(0.04),
                            blurRadius: 0,
                            spreadRadius: 0),

                        ///second
                        BoxShadow(
                            offset: Offset(0, 4.62),
                            color: ThemeManager.black.withOpacity(0.04),
                            blurRadius: 10.165,
                            spreadRadius: 0),

                        ///third
                        BoxShadow(
                            offset: Offset(0, 19.40),
                            color: ThemeManager.black.withOpacity(0.03),
                            blurRadius: 19.40,
                            spreadRadius: 0),

                        ///four
                        BoxShadow(
                            offset: Offset(0, 43.436),
                            color: ThemeManager.black.withOpacity(0.02),
                            blurRadius: 25.876,
                            spreadRadius: 0),

                        ///five
                        BoxShadow(
                            offset: Offset(0, 76.706),
                            color: ThemeManager.black.withOpacity(0.01),
                            blurRadius: 30.497,
                            spreadRadius: 0),

                        ///six
                        BoxShadow(
                            offset: Offset(0, 120.142),
                            color: ThemeManager.black.withOpacity(0),
                            blurRadius: 33.270,
                            spreadRadius: 0),
                      ],
                    ),
                    child: Text('Yes',
                        style: interRegular.copyWith(
                          fontSize: Dimensions.fontSizeDefault,
                          fontWeight: FontWeight.w500,
                          color: ThemeManager.primaryColor,
                        )),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = Provider.of<HomeStore>(context, listen: false);
    return Scaffold(
      backgroundColor: AppTokens.scaffold(context),
      // Apple-style transparent app bar — title + back + clear-all
      // action. No more "blue strip + rounded-white container" trick.
      appBar: AppBar(
        backgroundColor: AppTokens.scaffold(context),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: AppTokens.ink(context), size: 18),
          onPressed: () => Navigator.of(context).pushNamed(Routes.dashboard),
        ),
        title: Text(
          "Notifications",
          style: AppTokens.titleLg(context),
        ),
        centerTitle: false,
        actions: [
          Observer(builder: (_) {
            if (store.getNotificationList.isEmpty) return const SizedBox.shrink();
            return IconButton(
              tooltip: "Clear all",
              icon: Icon(Icons.delete_outline_rounded,
                  color: AppTokens.ink(context), size: 22),
              onPressed: () => showDialogs(context),
            );
          }),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Observer(builder: (context) {
                          if (store.isLoading) {
                            return Center(
                                child: CircularProgressIndicator(
                              color: Theme.of(context).primaryColor,
                            ));
                          }
                          if (store.getNotificationList.isEmpty) {
                            return Center(
                              child: Text(
                                'No Notifications Found',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: ThemeManager.black),
                              ),
                            );
                          }
                          return store.isConnected
                              ? ListView.builder(
                                  padding: EdgeInsets.zero,
                                  itemCount: store.getNotificationList.length,
                                  shrinkWrap: true,
                                  physics: const BouncingScrollPhysics(),
                                  itemBuilder:
                                      (BuildContext context, int index) {
                                    store.getNotificationList.sort((a, b) {
                                      DateTime dateA =
                                          DateTime.parse(a?.createdAt ?? '');
                                      DateTime dateB =
                                          DateTime.parse(b?.createdAt ?? '');
                                      return dateB.compareTo(dateA);
                                    });
                                    NotificationListModel? notification =
                                        store.getNotificationList[index];
                                    String originalDate =
                                        notification?.createdAt ?? "";
                                    DateTime parsedDate =
                                        DateTime.parse(originalDate);
                                    final formatter =
                                        DateFormat('dd/MM/yyyy hh:mm a');
                                    final todayFormatter =
                                        DateFormat('dd/MM/yyyy');
                                    final todayFormatterTime =
                                        DateFormat('hh:mm a');
                                    String date = todayFormatter
                                                .format(parsedDate) ==
                                            DateFormat('dd/MM/yyyy')
                                                .format(DateTime.now())
                                        ? 'Today at ${todayFormatterTime.format(parsedDate)}'
                                        : formatter.format(parsedDate);

                                    // return Container(
                                    //   padding: const EdgeInsets.only(
                                    //     left: Dimensions.PADDING_SIZE_LARGE,
                                    //     right: Dimensions.PADDING_SIZE_LARGE,
                                    //     bottom: Dimensions.PADDING_SIZE_LARGE,
                                    //   ),
                                    //   child: Column(
                                    //     crossAxisAlignment: CrossAxisAlignment.start,
                                    //     children: [
                                    //       Row(
                                    //         children: [
                                    //           SizedBox(
                                    //             width: MediaQuery.of(context).size.width * 0.85,
                                    //             child: Column(
                                    //               crossAxisAlignment: CrossAxisAlignment.start,
                                    //               children: [
                                    //                 Row(
                                    //                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    //                   children: [
                                    //                     SizedBox(
                                    //                       width: MediaQuery.of(context).size.width * 0.5,
                                    //                       child: Text(store.getNotificationList[index]?.title??"",
                                    //                         style: interSemiBold.copyWith(
                                    //                           fontSize: Dimensions.fontSizeDefault,
                                    //                           fontWeight: FontWeight.w600,
                                    //                           color: ThemeManager.black,
                                    //                         ),),
                                    //                     ),
                                    //                     Text(date,
                                    //                       style: interSemiBold.copyWith(
                                    //                         fontSize: Dimensions.fontSizeSmall,
                                    //                         fontWeight: FontWeight.w400,
                                    //                         color: Theme.of(context).hintColor,
                                    //                       ),),
                                    //                   ],
                                    //                 ),
                                    //                 const SizedBox(height: Dimensions.PADDING_SIZE_EXTRA_SMALL),
                                    //                 Text(store.getNotificationList[index]?.notification??"",
                                    //                   style: interRegular.copyWith(
                                    //                     fontSize: Dimensions.fontSizeSmall,
                                    //                     fontWeight: FontWeight.w400,
                                    //                     color: Theme.of(context).hintColor,
                                    //                   ),),
                                    //               ],
                                    //             ),
                                    //           ),
                                    //         ],
                                    //       ),
                                    //       const SizedBox(height: Dimensions.PADDING_SIZE_DEFAULT,),
                                    //       SizedBox(
                                    //         width: MediaQuery.of(context).size.width,
                                    //         height:1,
                                    //         child: Container(
                                    //           color: const Color(0xFFE6E4A),
                                    //         ),
                                    //       ),
                                    //     ],
                                    //   ),
                                    // );
                                    return Container(
                                      padding: const EdgeInsets.only(
                                        top: Dimensions
                                                .PADDING_SIZE_EXTRA_SMALL *
                                            1.4,
                                        left:
                                            Dimensions.PADDING_SIZE_SMALL * 1.4,
                                        right: Dimensions.PADDING_SIZE_SMALL,
                                      ),
                                      decoration: const BoxDecoration(
                                          border: Border(
                                              bottom: BorderSide(
                                                  color: Color(0xFFE4E8EE)))),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Container(
                                            width: Dimensions
                                                    .PADDING_SIZE_EXTRA_SMALL *
                                                1.4,
                                            height: Dimensions
                                                    .PADDING_SIZE_EXTRA_SMALL *
                                                1.4,
                                            decoration: const BoxDecoration(
                                                color: Color(0xFF1AD285),
                                                shape: BoxShape.circle),
                                          ),
                                          const SizedBox(
                                            height: Dimensions
                                                .PADDING_SIZE_EXTRA_SMALL,
                                          ),
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Container(
                                                width: Dimensions
                                                        .PADDING_SIZE_LARGE *
                                                    1.3,
                                                height: Dimensions
                                                        .PADDING_SIZE_LARGE *
                                                    1.3,
                                                decoration: const BoxDecoration(
                                                    shape: BoxShape.circle),
                                                child: Image.asset(
                                                    "assets/image/avatar.png"),
                                              ),
                                              const SizedBox(
                                                width: Dimensions
                                                        .PADDING_SIZE_SMALL *
                                                    1.3,
                                              ),
                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  SizedBox(
                                                    width:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width *
                                                            0.8,
                                                    child: Text(
                                                      store
                                                              .getNotificationList[
                                                                  index]
                                                              ?.notification ??
                                                          "",
                                                      style:
                                                          interRegular.copyWith(
                                                        fontSize: Dimensions
                                                            .fontSizeSmall,
                                                        fontWeight:
                                                            FontWeight.w400,
                                                        color: ThemeManager
                                                            .notificationText,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(
                                                      height: Dimensions
                                                          .PADDING_SIZE_SMALL),
                                                  Text(
                                                    date,
                                                    style:
                                                        interRegular.copyWith(
                                                      fontSize: Dimensions
                                                          .fontSizeSmall,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color: ThemeManager
                                                          .notificationDateText,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                          const SizedBox(
                                              height: Dimensions
                                                      .PADDING_SIZE_SMALL *
                                                  1.4),
                                        ],
                                      ),
                                    );
                                  },
                                )
                              : const NoInternetScreen();
                        }),
            ),
          ],
        ),
      ),
    );
  }
}
