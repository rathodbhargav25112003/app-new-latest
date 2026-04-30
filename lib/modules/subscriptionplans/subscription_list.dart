// ignore_for_file: deprecated_member_use, unused_import, unnecessary_import, unused_field, unused_local_variable, dead_null_aware_expression, prefer_interpolation_to_compose_strings, use_build_context_synchronously, avoid_unnecessary_containers, library_private_types_in_public_api, duplicate_ignore, unused_element

import 'dart:io';
import '../../app/routes.dart';
import '../../helpers/app_tokens.dart';
import '../../helpers/colors.dart';
import '../../helpers/styles.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';
import '../../helpers/dimensions.dart';
import '../widgets/custom_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../login/store/login_store.dart';
import 'ini_ss_group_subscriptionlist.dart';
import '../widgets/custom_bottom_sheet.dart';
import 'neet_ss_group_subscriptionlist.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/no_internet_connection.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shusruta_lms/models/subscription_model.dart';
import 'package:shusruta_lms/helpers/custom_dynamic_height_gridview.dart';
import 'package:shusruta_lms/modules/subscriptionplans/store/subscription_store.dart';

class SubscriptionList extends StatefulWidget {
  final bool isHome;
  const SubscriptionList({super.key, this.isHome = false});
  @override
  State<SubscriptionList> createState() => _SubscriptionListState();
  static Route<dynamic> route(RouteSettings routeSettings) {
    return CupertinoPageRoute(
      builder: (_) => const SubscriptionList(),
    );
  }
}

class _SubscriptionListState extends State<SubscriptionList>
    with SingleTickerProviderStateMixin {
  final int _selectedIndex = 0;
  TabController? _controller;
  int tabIndex = 0;
  bool loggedIn = false;
  bool isExpanded = false;
  Future<bool>? isLogged;
  List<SubscriptionModel?>? filteredSolutionReport;
  @override
  void initState() {
    super.initState();
    _controller = TabController(length: 2, vsync: this, initialIndex: tabIndex);
    _controller?.addListener(() {
      setState(() {
        tabIndex = _controller?.index ?? 0;
        // final store = Provider.of<SubscriptionStore>(context, listen: false);
        // store.onRegisterApiCall(context,'');
      });
    });
    // isLogged = _checkIsLoggedIn();
    // isLogged!.then((value) {
    //   setState(() {
    //     loggedIn = value;
    //   });
    // });
    // _settingsData();
  }

  // Future<bool> _checkIsLoggedIn() async {
  //   SharedPreferences prefs = await SharedPreferences.getInstance();
  //   bool? loggedInEmail = prefs.getBool('isloggedInEmail');
  //   bool? signInGoogle = prefs.getBool('isSignInGoogle');
  //   bool? loggedInWt = prefs.getBool('isLoggedInWt');
  //   if(loggedInEmail==true || signInGoogle==true || loggedInWt==true){
  //     return loggedIn=true;
  //   }else {
  //     return loggedIn=false;
  //   }
  // }

  Future<void> _settingsData() async {
    final store = Provider.of<LoginStore>(context, listen: false);
    await store.onGetSettingsData();
  }

  List<bool?> isExpandedList = [];
  String filterValue = '';
  // int currentIndex = 0;
  // List<String> filterValue = [];
  // List<String> checkItems = ['All','Live Classes','Mock Exams',"Only MCQ's",'Only Videos','Only Notes'];
  @override
  Widget build(BuildContext context) {
    final store = Provider.of<SubscriptionStore>(context);
    final loginStore = Provider.of<LoginStore>(context, listen: false);
    return WillPopScope(
      onWillPop: () async {
        if (Navigator.canPop(context)) {
          Navigator.of(context).pushNamed(Routes.dashboard);
          return false;
        } else {
          return false;
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.black,
        appBar: AppBar(
          elevation: 0,
          automaticallyImplyLeading: false,
          backgroundColor: AppColors.black,
          leading: Navigator.canPop(context) && !widget.isHome
              ? Padding(
                  padding: const EdgeInsets.only(
                      left: Dimensions.PADDING_SIZE_SMALL),
                  child: IconButton(
                    highlightColor: Colors.transparent,
                    hoverColor: Colors.transparent,
                    icon: const Icon(
                      Icons.arrow_back_ios,
                      color: AppColors.white,
                      size: 18,
                    ),
                    onPressed: () {
                      Navigator.of(context).pushNamed(Routes.dashboard);
                    },
                  ),
                )
              : SizedBox(),
          title: Text(
            "Subscription Plans",
            style: interRegular.copyWith(
              fontSize: Dimensions.fontSizeDefault,
              fontWeight: FontWeight.w600,
              color: AppColors.white,
            ),
          ),
          // actions: [
          //   InkWell(
          //       onTap: (){
          //         showModalBottomSheet<String>(
          //           shape: const RoundedRectangleBorder(
          //             borderRadius: BorderRadius.vertical(
          //               top: Radius.circular(25),
          //             ),
          //           ),
          //           clipBehavior: Clip.antiAliasWithSaveLayer,
          //           context: context,
          //           builder: (BuildContext context) {
          //             return CustomBottomSheet(
          //                 heightSize: MediaQuery.of(context).size.height *0.5,
          //                 selectedVal: filterValue,
          //                 checkboxItems: const ['liveClass','mockExam','exam','videos','notes']);
          //           },
          //         ).then((selectedValues) {
          //           if (selectedValues != null) {
          //             setState(() {
          //               filterValue = selectedValues;
          //               if (filterValue.isNotEmpty) {
          //                 debugPrint("filterValue:${filterValue}");
          //                 store.onRegisterApiCall(context, filterValue);
          //               } else {
          //                 store.onRegisterApiCall(context, '');
          //               }
          //               debugPrint('Selected value: $filterValue');
          //             });
          //           }
          //         });
          //       },
          //       child: SvgPicture.asset("assets/image/filter_icon.svg",color:AppColors.currentTheme==AppTheme.Dark ?AppColors.black : null,)),
          //   SizedBox(width: Dimensions.PADDING_SIZE_LARGE,),
          // ],
        ),
        // body: SingleChildScrollView(
        //   physics: const BouncingScrollPhysics(),
        //   child: SizedBox(
        //     height: MediaQuery.of(context).size.height,
        //     child: Padding(
        //       padding: const EdgeInsets.only(
        //         left: Dimensions.PADDING_SIZE_LARGE + Dimensions.PADDING_SIZE_EXTRA_SMALL,
        //         top: Dimensions.PADDING_SIZE_EXTRA_SMALL,
        //         right: Dimensions.PADDING_SIZE_LARGE + Dimensions.PADDING_SIZE_EXTRA_SMALL,
        //         bottom: Dimensions.PADDING_SIZE_LARGE,
        //       ),
        //       child: Column(
        //         children: [
        //           loggedIn!=true?
        //           Align(
        //             alignment: Alignment.topRight,
        //             child: Row(
        //               mainAxisAlignment: MainAxisAlignment.end,
        //               children: [
        //                 TextButton.icon(
        //                   onPressed: () {
        //                     // Navigator.of(context).pushNamed(Routes.loginWithPass);
        //                     Navigator.of(context).pushNamed(Routes.login);
        //                   },
        //                   label: Icon(
        //                     Icons.arrow_forward_outlined,
        //                     color: Theme.of(context).primaryColor,
        //                   ),
        //                   icon: Text('Login or Register',
        //                       style: interRegular.copyWith(
        //                         fontSize: Dimensions.fontSizeSmall,
        //                         color: Theme.of(context).primaryColor,
        //                         fontWeight: FontWeight.w500,
        //                       )),
        //                 ),
        //               ],
        //             ),
        //           ):const SizedBox(),
        //           Flexible(
        //             child: Observer(
        //               builder: (_) {
        //                 if (store.subscription.isEmpty) {
        //                   return const Center(
        //                     child: Text(
        //                       'No Subscription Plans Found',
        //                       style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        //                     ),
        //                   );
        //                 }
        //                 return store.isLoading ?
        //                 Center(child: CircularProgressIndicator(color: Theme.of(context).primaryColor,)) :
        //                 store.isConnected?
        //                 ListView.builder(
        //                   padding: const EdgeInsets.only(
        //                       top: Dimensions.PADDING_SIZE_DEFAULT,bottom: Dimensions.PADDING_SIZE_EXTRA_LARGE),
        //                   itemCount: store.subscription.length,
        //                   shrinkWrap: true,
        //                   physics: const BouncingScrollPhysics(),
        //                   itemBuilder: (BuildContext context, int index) {
        //                     List<SubscriptionModel?> subscriptionList = store.subscription;
        //
        //                     subscriptionList.sort((a, b) {
        //                       final aOrder = a?.order ?? 0;
        //                       final bOrder = b?.order ?? 0;
        //                       return aOrder.compareTo(bOrder);
        //                     });
        //
        //                     if (subscriptionList[index]?.duration?.any((e) => e.price == 0) ?? false) {
        //                       return Container();
        //                     }
        //                     bool isSelected = index == _selectedIndex;
        //                     // return InkWell(
        //                     //   onTap: () {
        //                     //     setState(() {
        //                     //       _selectedIndex = index;
        //                     //     });
        //                     //     // Navigator.of(context).pushNamed(Routes.subscriptionDetailPlan);
        //                     //   },
        //                     //   child: Container(
        //                     //     height: Dimensions.PADDING_SIZE_EXTRA_LARGE * 9,
        //                     //     decoration: BoxDecoration(
        //                     //       border: Border.all(color: Theme.of(context).disabledColor),
        //                     //       borderRadius: BorderRadius.circular(Dimensions.RADIUS_DEFAULT),
        //                     //       color: isSelected ? const Color(0xFFAFA8FD) : Colors.white,
        //                     //       gradient: isSelected ? const LinearGradient(
        //                     //         begin: Alignment.topLeft,
        //                     //         end: Alignment.bottomRight,
        //                     //         colors: [
        //                     //           Color(0xFFAFA8FD),
        //                     //           Color(0xFF8E84FF)
        //                     //         ],
        //                     //       )
        //                     //           : const LinearGradient(
        //                     //         begin: Alignment.topLeft,
        //                     //         end: Alignment.bottomRight,
        //                     //         colors: [
        //                     //           Color(0xFFFFFFFF),
        //                     //           Color(0xFFFFFFFF)
        //                     //         ],
        //                     //       ),
        //                     //     ),
        //                     //     child: Padding(
        //                     //       padding: const EdgeInsets.only(
        //                     //         top: Dimensions.PADDING_SIZE_DEFAULT,
        //                     //         bottom: Dimensions.PADDING_SIZE_DEFAULT,
        //                     //         left: Dimensions.PADDING_SIZE_DEFAULT,
        //                     //         right: Dimensions.PADDING_SIZE_SMALL,
        //                     //       ),
        //                     //       child: Row(
        //                     //         crossAxisAlignment: CrossAxisAlignment.center,
        //                     //         children: [
        //                     //           Expanded(
        //                     //             child: Column(
        //                     //               crossAxisAlignment: CrossAxisAlignment.start,
        //                     //               children: [
        //                     //                 Row(
        //                     //                   crossAxisAlignment: CrossAxisAlignment.center,
        //                     //                   children: [
        //                     //                     SvgPicture.asset("assets/image/bookmark_plan.svg"),
        //                     //                     const SizedBox(
        //                     //                         width: Dimensions.PADDING_SIZE_SMALL),
        //                     //                     SizedBox(
        //                     //                       width: Dimensions.PADDING_SIZE_EXTRA_LARGE * 3,
        //                     //                       child: Text(
        //                     //                         subscriptionList[index]?.plan_name ??"",
        //                     //                         style: interRegular.copyWith(
        //                     //                           fontSize: Dimensions.fontSizeLarge,
        //                     //                           fontWeight: FontWeight.w500,
        //                     //                           color: isSelected ? Colors.white : Colors.black,
        //                     //                         ),
        //                     //                       ),
        //                     //                     ),
        //                     //                   ],
        //                     //                 ),
        //                     //                 Expanded(
        //                     //                   child: ListView.builder(
        //                     //                     itemCount: subscriptionList[index]?.benifit?.length,
        //                     //                     padding: EdgeInsets.zero,
        //                     //                     shrinkWrap: true,
        //                     //                     itemBuilder: (BuildContext context, int bindex) {
        //                     //                       String? benefits = subscriptionList[index]?.benifit![bindex];
        //                     //                       return Padding(
        //                     //                         padding: const EdgeInsets.only(
        //                     //                             left: Dimensions.PADDING_SIZE_LARGE,
        //                     //                             top: Dimensions.PADDING_SIZE_EXTRA_SMALL),
        //                     //                         child: Text(
        //                     //                           '\u2022 $benefits',
        //                     //                           style: interRegular.copyWith(
        //                     //                               fontSize: Dimensions.fontSizeSmall,
        //                     //                               fontWeight: FontWeight.w400,
        //                     //                               color: isSelected ? Colors.white : Colors.black),
        //                     //                         ),
        //                     //                       );
        //                     //                     },
        //                     //                   ),
        //                     //                 ),
        //                     //                 Row(
        //                     //                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
        //                     //                   children: [
        //                     //                     loginStore.settingsData.value?.showActiveUser==true?
        //                     //                     Padding(
        //                     //                       padding: const EdgeInsets.only(
        //                     //                           left: Dimensions.PADDING_SIZE_DEFAULT),
        //                     //                       child: Row(
        //                     //                         children: [
        //                     //                           Text(
        //                     //                             "${subscriptionList[index]?.active_user.toString()} Active Students",
        //                     //                             style: interRegular.copyWith(
        //                     //                               fontSize: Dimensions.fontSizeSmall,
        //                     //                               fontWeight: FontWeight.w400,
        //                     //                               color: isSelected ? Colors.white : Colors.black,
        //                     //                             ),
        //                     //                           ),
        //                     //                         ],
        //                     //                       ),
        //                     //                     ):const SizedBox(),
        //                     //
        //                     //                     if(Platform.isIOS)
        //                     //                     TextButton.icon(
        //                     //                       style: TextButton.styleFrom(
        //                     //                         backgroundColor: AppColors.borderBlue,
        //                     //                         side:  BorderSide(color: AppColors.borderBlue),
        //                     //                         shape: RoundedRectangleBorder(
        //                     //                           borderRadius: BorderRadius.circular(Dimensions.RADIUS_DEFAULT),
        //                     //                         ),
        //                     //                       ),
        //                     //                       onPressed: () {
        //                     //                         loggedIn==true?
        //                     //                         openUrlWithToken():
        //                     //                         Navigator.of(context).pushNamed(Routes.loginWithPass);
        //                     //                       },
        //                     //                       label:  Icon(
        //                     //                           Icons.arrow_forward_outlined,
        //                     //                           color: AppColors.black),
        //                     //                       icon: Text('Subscribe now',
        //                     //                           style: interRegular.copyWith(
        //                     //                             fontSize: Dimensions.fontSizeSmall,
        //                     //                             color: AppColors.black,
        //                     //                             fontWeight: FontWeight.w500,
        //                     //                           )),
        //                     //                     ),
        //                     //
        //                     //                     if(Platform.isAndroid)
        //                     //                     TextButton.icon(
        //                     //                       style: TextButton.styleFrom(
        //                     //                         backgroundColor: AppColors.borderBlue,
        //                     //                         side:  BorderSide(color: AppColors.borderBlue),
        //                     //                         shape: RoundedRectangleBorder(
        //                     //                           borderRadius: BorderRadius.circular(Dimensions.RADIUS_DEFAULT),
        //                     //                         ),
        //                     //                       ),
        //                     //                       onPressed: () {
        //                     //                         Navigator.of(context)
        //                     //                             .pushNamed(Routes.subscriptionDetailPlan,
        //                     //                             arguments: {
        //                     //                               "subscription": subscriptionList[index],
        //                     //                               "store": store
        //                     //                             });
        //                     //                       },
        //                     //                       label:  Icon(
        //                     //                           Icons.arrow_forward_outlined,
        //                     //                           color: AppColors.black),
        //                     //                       icon: Text('Subscribe now',
        //                     //                           style: interRegular.copyWith(
        //                     //                             fontSize: Dimensions.fontSizeSmall,
        //                     //                             color: AppColors.black,
        //                     //                             fontWeight: FontWeight.w500,
        //                     //                           )),
        //                     //                     ),
        //                     //                   ],
        //                     //                 ),
        //                     //               ],
        //                     //             ),
        //                     //           ),
        //                     //           // Expanded(
        //                     //           //   child: SingleChildScrollView(
        //                     //           //     child: Column(
        //                     //           //       crossAxisAlignment: CrossAxisAlignment.end,
        //                     //           //       children: [
        //                     //           //         SizedBox(
        //                     //           //           height: MediaQuery.of(context).size.height * 0.16,
        //                     //           //           child: ListView.builder(
        //                     //           //             itemCount: store.subscription[index]?.duration?.length,
        //                     //           //             padding: const EdgeInsets.only(
        //                     //           //               top: Dimensions.PADDING_SIZE_SMALL,
        //                     //           //             ),
        //                     //           //             itemBuilder: (BuildContext context, int i) {
        //                     //           //               if (i >= 2) {
        //                     //           //                 return Container();
        //                     //           //               }
        //                     //           //               Duration? subPlan = store.subscription[index]?.duration?[i];
        //                     //           //               String? subPlanOffer = subPlan?.offer?.replaceAll("%", "");
        //                     //           //
        //                     //           //               num offerPrice = (subPlan?.price ?? 0);
        //                     //           //
        //                     //           //               if (subPlanOffer != null && subPlanOffer.isNotEmpty) {
        //                     //           //                 try {
        //                     //           //                   double discountPercentage = double.parse(subPlanOffer);
        //                     //           //                   offerPrice *= (1 - (discountPercentage / 100));
        //                     //           //                 } catch (e) {
        //                     //           //                   debugPrint("catch");
        //                     //           //                 }
        //                     //           //               }
        //                     //           //               return Column(
        //                     //           //                 crossAxisAlignment: CrossAxisAlignment.end,
        //                     //           //                 children: [
        //                     //           //                   subPlanOffer == "" ? Container()
        //                     //           //                       : Container(
        //                     //           //                     decoration: BoxDecoration(color: isSelected ? Colors.white: AppColors.black,
        //                     //           //                         borderRadius: BorderRadius.circular(Dimensions.RADIUS_DEFAULT)),
        //                     //           //                     child: Padding(padding: const EdgeInsets.only(
        //                     //           //                         left: 10, right: 10, top: 6, bottom: 6),
        //                     //           //                       child:
        //                     //           //                       Text(
        //                     //           //                         "Offer ${subPlan?.offer} off",
        //                     //           //                         style:
        //                     //           //                         interRegular.copyWith(
        //                     //           //                           fontSize: Dimensions.fontSizeExtraSmall,
        //                     //           //                           fontWeight: FontWeight.w400,
        //                     //           //                           color: isSelected ? AppColors.black : Colors.white,
        //                     //           //                         ),
        //                     //           //                       ),
        //                     //           //                     ),
        //                     //           //                   ),
        //                     //           //                   Column(
        //                     //           //                     crossAxisAlignment: CrossAxisAlignment.end,
        //                     //           //                     children: [
        //                     //           //                       subPlan?.offer == "" ? Container() : Padding(
        //                     //           //                         padding: const EdgeInsets.only(top: Dimensions.PADDING_SIZE_SMALL),
        //                     //           //                         child: Text(
        //                     //           //                           "₹ ${subPlan?.price}",
        //                     //           //                           style: interRegular.copyWith(
        //                     //           //                             fontSize: Dimensions.fontSizeLarge,
        //                     //           //                             fontWeight: FontWeight.w600,
        //                     //           //                             color: isSelected ? Colors.white : AppColors.black,
        //                     //           //                             decoration: TextDecoration.lineThrough,
        //                     //           //                           ),
        //                     //           //                         ),
        //                     //           //                       ),
        //                     //           //                       const SizedBox(
        //                     //           //                         width: Dimensions.PADDING_SIZE_EXTRA_SMALL,
        //                     //           //                       ),
        //                     //           //                       Padding(
        //                     //           //                         padding: const EdgeInsets.only(top: Dimensions.PADDING_SIZE_SMALL),
        //                     //           //                         child: Text(
        //                     //           //                           "₹ ${subPlan?.offer == null ? subPlan?.price : offerPrice.toStringAsFixed(0)}",
        //                     //           //                           style: interRegular.copyWith(
        //                     //           //                             fontSize: Dimensions.fontSizeExtraLarge,
        //                     //           //                             fontWeight: FontWeight.w500,
        //                     //           //                             color: isSelected ? Colors.white : AppColors.black,
        //                     //           //                             overflow: TextOverflow.ellipsis,
        //                     //           //                           ),
        //                     //           //                         ),
        //                     //           //                       ),
        //                     //           //                       Text(
        //                     //           //                         formatTime(int.parse(subPlan?.day??"")),
        //                     //           //                         // "${subPlan?.day} days",
        //                     //           //                         style: interRegular.copyWith(
        //                     //           //                             fontSize: Dimensions.fontSizeSmall,
        //                     //           //                             fontWeight: FontWeight.w400,
        //                     //           //                             color: isSelected
        //                     //           //                                 ? Colors.white
        //                     //           //                                 : Theme.of(context).hintColor),
        //                     //           //                       ),
        //                     //           //                     ],
        //                     //           //                   ),
        //                     //           //                 ],
        //                     //           //               );
        //                     //           //             },
        //                     //           //           ),
        //                     //           //         ),
        //                     //           //         const SizedBox(height: 4),
        //                     //           //         TextButton.icon(
        //                     //           //           style: TextButton.styleFrom(
        //                     //           //             backgroundColor: AppColors.borderBlue,
        //                     //           //             side: const BorderSide(color: AppColors.borderBlue),
        //                     //           //             shape: RoundedRectangleBorder(
        //                     //           //               borderRadius: BorderRadius.circular(Dimensions.RADIUS_DEFAULT),
        //                     //           //             ),
        //                     //           //           ),
        //                     //           //           onPressed: () {
        //                     //           //             Navigator.of(context)
        //                     //           //                 .pushNamed(Routes.subscriptionDetailPlan,
        //                     //           //                 arguments: {
        //                     //           //                   "subscription": store.subscription[index],
        //                     //           //                   "store": store
        //                     //           //                 });
        //                     //           //           },
        //                     //           //           label: const Icon(
        //                     //           //               Icons.arrow_forward_outlined,
        //                     //           //               color: AppColors.black),
        //                     //           //           icon: Text('Subscribe now',
        //                     //           //               style: interRegular.copyWith(
        //                     //           //                 fontSize: Dimensions.fontSizeSmall,
        //                     //           //                 color: AppColors.black,
        //                     //           //                 fontWeight: FontWeight.w500,
        //                     //           //               )),
        //                     //           //         ),
        //                     //           //       ],
        //                     //           //     ),
        //                     //           //   ),
        //                     //           // ),
        //                     //         ],
        //                     //       ),
        //                     //     ),
        //                     //   ),
        //                     // );
        //                     return Padding(
        //                       padding: const EdgeInsets.only(
        //                           bottom: Dimensions.PADDING_SIZE_EXTRA_LARGE*1.5),
        //                       child: Stack(
        //                         clipBehavior: Clip.none,
        //                         children: [
        //                           ExpansionTile(
        //                             onExpansionChanged: (value) {
        //                               setState(() {
        //                                 if (isExpandedList.length <= index) {
        //                                   isExpandedList.length = index + 1;
        //                                 }
        //                                 isExpandedList[index] = value;
        //                               });
        //                             },
        //                             initiallyExpanded: false,
        //                             tilePadding: EdgeInsets.only(left: Dimensions.PADDING_SIZE_SMALL*2.2,
        //                                 right: Dimensions.PADDING_SIZE_EXTRA_LARGE*1.1,
        //                                 top: Dimensions.PADDING_SIZE_SMALL,
        //                                 bottom: Dimensions.PADDING_SIZE_SMALL),
        //                             title: Row(
        //                               children: [
        //                                 SvgPicture.asset("assets/image/subscription_logo.svg"),
        //                                 SizedBox(width: Dimensions.PADDING_SIZE_DEFAULT,),
        //                                 SizedBox(
        //                                   width: MediaQuery.of(context).size.width*0.4,
        //                                   child: Text(
        //                                     subscriptionList[index]?.plan_name ??"",
        //                                     style: interRegular.copyWith(
        //                                       fontSize: Dimensions.fontSizeLarge,
        //                                       fontWeight: FontWeight.w500,
        //                                       color:Colors.black,
        //                                     ),
        //                                   ),
        //                                 ),
        //                               ],
        //                             ),
        //                             collapsedBackgroundColor: AppColors.mockContainer,
        //                             backgroundColor: AppColors.mockContainer,
        //                             shape: RoundedRectangleBorder(
        //                                 borderRadius: BorderRadius.circular(10),
        //                                 side: BorderSide(
        //                                     color: AppColors.mockBorderContainer
        //                                 )
        //                             ),
        //                             collapsedShape: RoundedRectangleBorder(
        //                                 borderRadius: BorderRadius.circular(10),
        //                                 side: BorderSide(
        //                                     color: AppColors.mockBorderContainer
        //                                 )
        //                             ),
        //                             children: [
        //
        //                               ListView.builder(
        //                                 itemCount: subscriptionList[index]?.benifit?.length,
        //                                 padding: EdgeInsets.zero,
        //                                 shrinkWrap: true,
        //                                 physics: NeverScrollableScrollPhysics(),
        //                                 itemBuilder: (BuildContext context, int bindex) {
        //                                   String? benefits = subscriptionList[index]?.benifit![bindex];
        //                                   return Padding(
        //                                     padding: const EdgeInsets.only(
        //                                         left: Dimensions.PADDING_SIZE_LARGE,
        //                                         top: Dimensions.PADDING_SIZE_EXTRA_SMALL),
        //                                     child: Text(
        //                                       '\u2022 $benefits',
        //                                       style: interRegular.copyWith(
        //                                           fontSize: Dimensions.fontSizeSmall,
        //                                           fontWeight: FontWeight.w400,
        //                                           color:Colors.black),
        //                                     ),
        //                                   );
        //                                 },
        //                               ),
        //                               SizedBox(height: Dimensions.PADDING_SIZE_EXTRA_LARGE,),
        //                               loginStore.settingsData.value?.showActiveUser==true?
        //                               Align(
        //                                 alignment: Alignment.center,
        //                                 child: Text(
        //                                   "${subscriptionList[index]?.active_user.toString()} Active Students",
        //                                   style: interRegular.copyWith(
        //                                     fontSize: Dimensions.fontSizeSmall,
        //                                     fontWeight: FontWeight.w600,
        //                                     color:Colors.black ,
        //                                   ),
        //                                 ),
        //                               ) :const SizedBox(),
        //                               SizedBox(height: Dimensions.PADDING_SIZE_EXTRA_LARGE*2,),
        //                             ],
        //                           ),
        //                           if (index < isExpandedList.length &&
        //                               isExpandedList[index] != null &&
        //                               isExpandedList[index]!)  Positioned(
        //                             bottom: -20,
        //                             left: MediaQuery.of(context).size.width*0.12,
        //                             child: InkWell(
        //                               onTap: (){
        //                                 // if(Platform.isIOS){
        //                                 //   loggedIn==true?
        //                                 //   openUrlWithToken():
        //                                 //   // Navigator.of(context).pushNamed(Routes.loginWithPass);
        //                                 //   Navigator.of(context).pushNamed(Routes.login);
        //                                 // }else if(Platform.isAndroid){
        //                                 //   Navigator.of(context)
        //                                 //       .pushNamed(Routes.subscriptionDetailPlan,
        //                                 //       arguments: {
        //                                 //         "subscription": store.subscription[index],
        //                                 //         "store": store
        //                                 //       });
        //                                 // }
        //                                 Navigator.of(context)
        //                                     .pushNamed(Routes.subscriptionDetailPlan,
        //                                     arguments: {
        //                                       "subscription": store.subscription[index],
        //                                       "store": store
        //                                     });
        //                                 isExpandedList = [];
        //                               },
        //                               child: Container(
        //                                 width: MediaQuery.of(context).size.width*0.62,
        //                                 height: MediaQuery.of(context).size.height*0.06,
        //                                 alignment: Alignment.center,
        //                                 decoration: BoxDecoration(
        //                                     color: AppColors.primaryColor,
        //                                     borderRadius: BorderRadius.circular(25)
        //                                 ),
        //                                 child: Text('Subscribe now',
        //                                     style: interRegular.copyWith(
        //                                       fontSize: Dimensions.fontSizeSmall,
        //                                       color: AppColors.white,
        //                                       fontWeight: FontWeight.w500,
        //                                     )),
        //                               ),
        //                             ),
        //                           ),
        //                         ],
        //                       ),
        //                     );
        //                     // return Container(
        //                     //   margin: const EdgeInsets.only(bottom: Dimensions.PADDING_SIZE_DEFAULT),
        //                     //   padding: const EdgeInsets.only(
        //                     //     left: Dimensions.PADDING_SIZE_LARGE*1.1,
        //                     //     right: Dimensions.PADDING_SIZE_LARGE*1.1,
        //                     //     top: Dimensions.PADDING_SIZE_LARGE*1.1,
        //                     //     bottom: Dimensions.PADDING_SIZE_SMALL*1.7,
        //                     //   ),
        //                     //   decoration: BoxDecoration(
        //                     //     borderRadius: BorderRadius.circular(13.78),
        //                     //     border: Border.all(color: AppColors.white.withOpacity(0.3))
        //                     //   ),
        //                     //   child: Column(
        //                     //     crossAxisAlignment: CrossAxisAlignment.start,
        //                     //     children: [
        //                     //       Text(
        //                     //       subscriptionList[index]?.plan_name??"",
        //                     //       style: interRegular.copyWith(
        //                     //         fontSize: 22,
        //                     //         fontWeight: FontWeight.w700,
        //                     //         color: AppColors.subPlanText,
        //                     //       ),
        //                     //     ),
        //                     //       const SizedBox(height: Dimensions.PADDING_SIZE_LARGE*1.1,),
        //                     //       Text(
        //                     //         subscriptionList[index]?.??"",
        //                     //         style: interRegular.copyWith(
        //                     //           fontSize: 27,
        //                     //           fontWeight: FontWeight.w600,
        //                     //           color: AppColors.white,
        //                     //         ),
        //                     //       ),
        //                     //     ],
        //                     //   ),
        //                     // );
        //                   },
        //                 ): const NoInternetScreen();
        //               },
        //             ),
        //           ),
        //           const SizedBox(height: Dimensions.PADDING_SIZE_EXTRA_LARGE*3,)
        //         ],
        //       ),
        //     ),
        //   ),
        // ),
        body: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                  gradient: RadialGradient(radius: 0.8, colors: [
                AppTokens.brand.withOpacity(0.55),
                AppTokens.brand2.withOpacity(0),
              ])),
            ),
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(
                    left: Dimensions.PADDING_SIZE_LARGE * 1.2,
                    right: Dimensions.PADDING_SIZE_LARGE * 1.2,
                    bottom: Dimensions.PADDING_SIZE_SMALL * 1.4,
                  ),
                  child: TabBar(
                      dividerColor: Colors.transparent,
                      controller: _controller,
                      labelPadding: EdgeInsets.zero,
                      indicator: const BoxDecoration(
                          borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(7),
                        topRight: Radius.circular(7),
                      )),
                      labelColor: AppColors.black,
                      tabs: [
                        Container(
                          height: 35,
                          width: double.infinity,
                          alignment: Alignment.center,
                          margin: const EdgeInsets.only(right: 4),
                          decoration: BoxDecoration(
                              borderRadius:
                                  (Platform.isMacOS || Platform.isWindows)
                                      ? BorderRadius.circular(7)
                                      : const BorderRadius.only(
                                          topLeft: Radius.circular(7),
                                          topRight: Radius.circular(7),
                                        ),
                              border: tabIndex == 0
                                  ? const Border.fromBorderSide(BorderSide.none)
                                  : Border.all(
                                      color: AppColors.backContainer
                                          .withOpacity(0.5)),
                              color: tabIndex == 0
                                  ? AppColors.white
                                  : Colors.transparent),
                          child: Text("Neet SS",
                              style: tabIndex == 0
                                  ? interRegular.copyWith(
                                      fontSize: Dimensions.fontSizeDefault,
                                      color: AppColors.black,
                                      fontWeight: FontWeight.w600,
                                    )
                                  : interRegular.copyWith(
                                      fontSize: Dimensions.fontSizeSmallLarge,
                                      color: AppColors.backContainer
                                          .withOpacity(0.5),
                                      fontWeight: FontWeight.w400,
                                    )),
                        ),
                        Container(
                          height: 35,
                          width: double.infinity,
                          alignment: Alignment.center,
                          margin: const EdgeInsets.only(left: 4),
                          decoration: BoxDecoration(
                              borderRadius:
                                  (Platform.isMacOS || Platform.isWindows)
                                      ? BorderRadius.circular(7)
                                      : const BorderRadius.only(
                                          topLeft: Radius.circular(7),
                                          topRight: Radius.circular(7),
                                        ),
                              border: tabIndex == 1
                                  ? const Border.fromBorderSide(BorderSide.none)
                                  : Border.all(
                                      color: AppColors.backContainer
                                          .withOpacity(0.5)),
                              color: tabIndex == 1
                                  ? AppColors.white
                                  : Colors.transparent),
                          child: Text("INISS-ET",
                              style: tabIndex == 1
                                  ? interRegular.copyWith(
                                      fontSize: Dimensions.fontSizeDefault,
                                      color: AppColors.black,
                                      fontWeight: FontWeight.w600,
                                    )
                                  : interRegular.copyWith(
                                      fontSize: Dimensions.fontSizeSmallLarge,
                                      color: AppColors.backContainer
                                          .withOpacity(0.5),
                                      fontWeight: FontWeight.w400,
                                    )),
                        ),
                      ]),
                ),
                Expanded(
                  child: TabBarView(controller: _controller, children: const [
                    NeetGroupSubscriptionList(),
                    IniGroupSubscriptionList(),
                  ]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String formatTime(int numberOfDays) {
    if (numberOfDays >= 365) {
      int years = numberOfDays ~/ 365;
      return years == 1 ? '1 Year' : '$years years';
    } else if (numberOfDays >= 30) {
      int months = numberOfDays ~/ 30;
      return months == 1 ? '1 month' : '$months months';
    } else {
      return '$numberOfDays days';
    }
  }

  void openUrlWithToken() async {
    // Disable external subscription URL for iOS/macOS to comply with App Store guidelines
    if (Platform.isIOS || Platform.isMacOS) {
      // Show message that subscription is only available through in-app purchase on iOS/macOS
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Subscription is available through in-app purchase. Please use the subscription options within the app.'),
          duration: Duration(seconds: 4),
        ),
      );
      return;
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");

    final url = 'https://app.sushrutalgs.in/subscription?token=$token';

    // ignore: deprecated_member_use
    if (await canLaunch(url)) {
      // ignore: deprecated_member_use
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }
}

class CustomBottomSheet extends StatefulWidget {
  final double heightSize;
  final String selectedVal;
  final List<String> checkboxItems;

  const CustomBottomSheet({
    super.key,
    required this.heightSize,
    required this.selectedVal,
    required this.checkboxItems,
  });

  @override
  _CustomBottomSheetState createState() => _CustomBottomSheetState();
}

class _CustomBottomSheetState extends State<CustomBottomSheet> {
  final List<String> _selectedValues = [];
  List<String> checkItems = [
    'Live Classes',
    'Mock Exams',
    "Only MCQ's",
    'Only Videos',
    'Only Notes'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.selectedVal != '') {
      _selectedValues.addAll(widget.selectedVal.split(','));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.heightSize,
      padding: const EdgeInsets.all(Dimensions.PADDING_SIZE_DEFAULT),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Filter',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: Dimensions.PADDING_SIZE_DEFAULT),
          Expanded(
            child: ListView.builder(
              itemCount: widget.checkboxItems.length,
              itemBuilder: (context, index) {
                final item = widget.checkboxItems[index];
                return CheckboxListTile(
                  title: Text(checkItems[index]),
                  value: _selectedValues.contains(item),
                  onChanged: (bool? value) {
                    setState(() {
                      if (value != null && value) {
                        _selectedValues.add(item);
                      } else {
                        _selectedValues.remove(item);
                      }
                    });
                  },
                );
              },
            ),
          ),
          const SizedBox(height: Dimensions.PADDING_SIZE_DEFAULT),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton(
                onPressed: () {
                  if (_selectedValues.isNotEmpty) {
                    Navigator.pop(context, _selectedValues.join(','));
                  } else {
                    Navigator.pop(
                        context, ''); // or any other appropriate value
                  }
                },
                child: const Text('Apply'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
