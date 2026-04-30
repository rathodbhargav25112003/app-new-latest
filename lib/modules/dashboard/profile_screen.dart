import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shusruta_lms/modules/signup/store/signup_store.dart';
import 'package:shusruta_lms/modules/widgets/no_internet_connection.dart';
import '../../app/routes.dart';
import '../../helpers/app_tokens.dart';
import '../../helpers/colors.dart';
import '../../helpers/dimensions.dart';
import '../../helpers/styles.dart';
import '../../models/get_user_details_model.dart';
import '../dashboard/store/home_store.dart';
import '../login/verify_otp_mail.dart';
import '../widgets/bottom_toast.dart';
import '../widgets/custom_button.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
  static Route<dynamic> route(RouteSettings routeSettings) {
    // final arguments = routeSettings.arguments as Map<String, dynamic>;
    return CupertinoPageRoute(
      builder: (_) => const ProfileScreen(),
    );
  }
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController dateController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPassController = TextEditingController();
  DateTime? selectedDate;
  String selectedValue = '';
  String stateValue = '';
  List<String> selectedCheckboxValues = [];
  List<String> availableCheckboxes = [];
  String? currentStatus;
  bool isChecked = false;
  final _emailKey = GlobalKey<FormFieldState<String>>();
  final _nameKey = GlobalKey<FormFieldState<String>>();
  final _prepParingKey = GlobalKey<FormFieldState<String>>();
  final _stateKey = GlobalKey<FormFieldState<String>>();
  final _passKey = GlobalKey<FormFieldState<String>>();
  final _repassKey = GlobalKey<FormFieldState<String>>();
  final _mobileKey = GlobalKey<FormFieldState<String>>();
  final _dobKey = GlobalKey<FormFieldState<String>>();
  final _emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
  bool _isEmailValid = false;
  final bool _isPasswordValid = false;
  bool _isMobileValid = false;
  bool _isNameValid = false;
  bool _isDateValid = false;
  final bool _isPreparingValid = false;
  bool _isStateValid = false;
  bool isSubmitted = false;
  String loggedInPlatform = '';
  final List<String> indianStates = [
    'Andhra Pradesh',
    'Arunachal Pradesh',
    'Assam',
    'Bihar',
    'Chhattisgarh',
    'Goa',
    'Gujarat',
    'Haryana',
    'Himachal Pradesh',
    'Jharkhand',
    'Karnataka',
    'Kerala',
    'Madhya Pradesh',
    'Maharashtra',
    'Manipur',
    'Meghalaya',
    'Mizoram',
    'Nagaland',
    'Odisha',
    'Punjab',
    'Rajasthan',
    'Sikkim',
    'Tamil Nadu',
    'Telangana',
    'Tripura',
    'Uttar Pradesh',
    'Uttarakhand',
    'West Bengal',
    'Andaman and Nicobar Islands',
    'Chandigarh',
    'Dadra and Nagar Haveli and Daman and Diu',
    'Delhi',
    'Lakshadweep',
    'Puducherry'
  ];
  bool isCheckboxChecked() {
    return currentStatus == "PG Resident" || currentStatus == "Post-Graduate";
  }

  String? validateCheckbox() {
    if (!isCheckboxChecked()) {
      return 'Please select at least one option.';
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    final store = Provider.of<HomeStore>(context, listen: false);
    store.onGetUserDetailsCall(context);
    nameController.text = store.userDetails.value?.fullname ?? "";
    dateController.text = store.userDetails.value?.dateOfBirth ?? "";
    phoneController.text = store.userDetails.value?.phone ?? "";
    emailController.text = store.userDetails.value?.email ?? "";
    currentStatus = store.userDetails.value?.currentData ?? "";
    // _getPreparingExamsData();
  }

  void signOut(HomeStore store, String loggedInPlatform) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool? loggedInEmail = prefs.getBool('isloggedInEmail');
    bool? loggedInWt = prefs.getBool('isLoggedInWt');
    // bool? signInGoogle = prefs.getBool('isSignInGoogle');
    String? fcmToken = prefs.getString('fcmtoken');
    
    // Try to call the API logout, but don't block local logout if it fails
    try {
      await store.onSignoutUser(loggedInPlatform);
    } catch (e) {
      print("API logout failed, proceeding with local logout: $e");
    }

    // Perform local logout operations regardless of API call success
    // If user reached this screen, they must be logged in, so always allow logout
    String? token = prefs.getString('token');
    bool shouldLogout = true; // Always allow logout if user clicked logout button
    
    print("Logout Debug - loggedInEmail: $loggedInEmail, loggedInWt: $loggedInWt, token: ${token?.substring(0, token != null && token.length > 10 ? 10 : token?.length ?? 0)}..., shouldLogout: $shouldLogout, platform: ${Platform.operatingSystem}");
    
    if (shouldLogout) {
      prefs.setString('token', '');
      prefs.setString('fcmtoken', '');
      prefs.setBool('isLoggedInWt', false);
      prefs.setBool('isloggedInEmail', false);
      prefs.setBool('isSignInGoogle', false);
      prefs.clear();
      ThemeManager.currentTheme == AppTheme.Dark
          ? Provider.of<ThemeNotifier>(context, listen: false).toggleTheme()
          : null;
      // Navigator.of(context).pushNamed(Routes.loginWithPass);
      Navigator.of(context).pushNamed(Routes.login);
      print("User Logged Out - Navigation to login screen executed");
    } else {
      print("Logout failed - shouldLogout condition not met");
    }
    // else if(signInGoogle==true){
    //   await _googleSignIn.signOut();
    //   prefs.setString('fcmtoken','');
    //   prefs.setString('token','');
    //   prefs.setBool('isSignInGoogle',false);
    //   prefs.clear();
    //   Navigator.of(context).pushNamed(Routes.splash);
    //   print("User Sign Out");
    // }

    // Only delete FCM token on mobile platforms where FCM is available
    if (fcmToken != null && !Platform.isWindows && !Platform.isMacOS) {
      try {
        await store.onDeleteNotificationToken(fcmToken);
      } catch (e) {
        print("FCM token deletion failed: $e");
      }
    }
  }

  Future<void> _deleteAccountUser() async {
    final store = Provider.of<HomeStore>(context, listen: false);
    await store.onDeleteUserAccountCall(store.userDetails.value?.id ?? '');
  }

  @override
  Widget build(BuildContext context) {
    // final store = Provider.of<SignupStore>(context, listen: false);
    final store = Provider.of<HomeStore>(context, listen: false);
    // List<DropdownMenuItem<String>> dropdownItems = store.preparingexams.map((item) {
    //   final preparingFor = item?.preparingFor;
    //   return DropdownMenuItem<String>(
    //     value: preparingFor,
    //     child: Text(preparingFor!),
    //   );
    // }).toList();

    selectedValue = store.userDetails.value?.preparingFor ?? "";
    stateValue = store.userDetails.value?.state ?? "";

    List<DropdownMenuItem<String>> stateDropdownItems =
        indianStates.map((item) {
      final state = item;
      return DropdownMenuItem<String>(
        value: state,
        child: Text(state),
      );
    }).toList();
    // selectedValue = (dropdownItems.contains(widget.userprofile.preparingFor)
    //     ? widget.userprofile.preparingFor : "")!;

    selectedCheckboxValues =
        List<String>.from((store.userDetails.value?.exams ?? []) as Iterable);
    // isChecked = selectedCheckboxValues.isNotEmpty;
    final deviceType = getDeviceType(context);
    String type = deviceType == DeviceType.Tablet ? 'Tablet' : 'Mobile';
    
    // Enhanced platform detection for desktop platforms
    if (Platform.isIOS) {
      loggedInPlatform = "ios$type";
    } else if (Platform.isAndroid) {
      loggedInPlatform = "android$type";
    } else if (Platform.isMacOS) {
      loggedInPlatform = "macOSDesktop";
    } else if (Platform.isWindows) {
      loggedInPlatform = "windowsDesktop";
    } else {
      loggedInPlatform = "unknownDesktop";
    }
    return Scaffold(
      backgroundColor: AppTokens.scaffold(context),
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: AppTokens.scaffold(context),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: AppTokens.ink(context), size: 18),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text("Edit profile", style: AppTokens.titleLg(context)),
        centerTitle: false,
      ),
      // appBar: PreferredSize(
      //   preferredSize: const Size.fromHeight(Dimensions.PADDING_SIZE_EXTRA_LARGE * 7),
      //   child: Stack(
      //     children: <Widget>[
      //       Container(     // Background
      //         color:Theme.of(context).primaryColor,
      //         height: Dimensions.PADDING_SIZE_EXTRA_LARGE * 6,
      //         width: MediaQuery.of(context).size.width,     // Background
      //         child: AppBar(
      //               elevation: 0,
      //               automaticallyImplyLeading: false,
      //               backgroundColor:ThemeManager.currentTheme == AppTheme.Dark ? ThemeManager.white :Theme.of(context).primaryColor,
      //               leading: Padding(
      //                 padding: const EdgeInsets.only(left: Dimensions.PADDING_SIZE_SMALL),
      //                 child:       IconButton(       highlightColor: Colors.transparent,     hoverColor: Colors.transparent,
      //                   icon:  Icon(Icons.arrow_back_ios, color: Colors.white,),
      //                   onPressed: () {
      //                     Navigator.pop(context);
      //                   },
      //                 ),
      //               ),
      //               centerTitle: false,
      //               title: Text(
      //                 "Edit profile",
      //                 style: interRegular.copyWith(
      //                   fontSize: Dimensions.fontSizeExtraLarge,
      //                   fontWeight: FontWeight.w600,
      //                   color: Colors.white,
      //                 ),
      //               ),
      //             ),
      //       ),
      //       // Container(),
      //       // Positioned(
      //       //     top: Dimensions.PADDING_SIZE_EXTRA_LARGE * 5,
      //       //     left: Dimensions.PADDING_SIZE_LARGE * 7.2,
      //       //     right: Dimensions.PADDING_SIZE_LARGE * 7.2,
      //       //     bottom: Dimensions.PADDING_SIZE_EXTRA_SMALL * 0.1,
      //       //   child: Stack(
      //       //     children: [
      //       //       Container(
      //       //         height: Dimensions.PADDING_SIZE_DEFAULT * 6.3,
      //       //         width: Dimensions.PADDING_SIZE_DEFAULT * 6.5,
      //       //         decoration: const BoxDecoration(
      //       //             borderRadius: BorderRadius.all(Radius.circular(12))
      //       //         ),
      //       //         child: Image.asset("assets/image/profile_img.png",fit: BoxFit.fill,),
      //       //       ),
      //       //     ],
      //       //   ),
      //       // ),
      //     ],
      //   ),
      // ),
      body: store.isConnected
          ? SafeArea(
              child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                          AppTokens.s24, AppTokens.s8, AppTokens.s24, 0),
                      child: Stack(
                        // mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Center(
                            child: Container(
                              constraints: const BoxConstraints(maxWidth: 600),
                              child: SingleChildScrollView(
                                physics: const BouncingScrollPhysics(),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Center(
                                    //   child: Text(widget.userprofile.username??"",
                                    //     style: interSemiBold.copyWith(
                                    //       fontSize: Dimensions.fontSizeExtraLarge,
                                    //       fontWeight: FontWeight.w600,
                                    //       color: ThemeManager.black,
                                    //     ),),
                                    // ),
                                    // const SizedBox(height: Dimensions.PADDING_SIZE_DEFAULT,),
                                    Container(
                                      constraints: const BoxConstraints(
                                        minHeight:
                                            Dimensions.PADDING_SIZE_EXTRA_LARGE *
                                                2,
                                      ),
                                      child: TextFormField(
                                        key: _nameKey,
                                        cursorColor: ThemeManager.textColor4,
                                        style: interRegular.copyWith(
                                            fontSize: Dimensions.fontSizeDefault,
                                            color: ThemeManager.textColor4),
                                        controller: nameController,
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            setState(() {
                                              _isNameValid = false;
                                            });
                                            return 'Please enter full name.';
                                          }
                                          setState(() {
                                            _isNameValid = true;
                                          });
                                          return null;
                                        },
                                        keyboardType: TextInputType.name,
                                        decoration: AppTokens.inputDecoration(
                                          context,
                                          hint: 'Full name',
                                        ),
                                      ),
                                    ),
                                    const SizedBox(
                                      height: Dimensions.PADDING_SIZE_DEFAULT,
                                    ),
                                    Container(
                                      constraints: const BoxConstraints(
                                        minHeight:
                                            Dimensions.PADDING_SIZE_EXTRA_LARGE *
                                                2,
                                      ),
                                      child: TextFormField(
                                        key: _dobKey,
                                        onTap: () {
                                          _selectDate(context);
                                        },
                                        cursorColor: ThemeManager.textColor4,
                                        style: interRegular.copyWith(
                                            fontSize: Dimensions.fontSizeDefault,
                                            color: ThemeManager.textColor4),
                                        controller: dateController,
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            setState(() {
                                              _isDateValid = false;
                                            });
                                            return 'Please select date of birth.';
                                          }
                                          setState(() {
                                            _isDateValid = true;
                                          });
                                          return null;
                                        },
                                        readOnly: true,
                                        keyboardType: TextInputType.datetime,
                                        decoration: AppTokens.inputDecoration(
                                          context,
                                          hint: 'Date of birth',
                                          suffix: Padding(
                                            padding: const EdgeInsets.only(
                                                right: AppTokens.s12),
                                            child: SvgPicture.asset(
                                                "assets/image/date_Icon.svg"),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(
                                      height: Dimensions.PADDING_SIZE_DEFAULT,
                                    ),
                                    DropdownButtonFormField<String>(
                                      key: _stateKey,
                                      dropdownColor: ThemeManager.white,
                                      value: stateValue.isNotEmpty
                                          ? stateValue
                                          : null,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          setState(() {
                                            _isStateValid = false;
                                          });
                                          return 'Please choose one.';
                                        }
                                        setState(() {
                                          _isStateValid = true;
                                        });
                                        return null;
                                      },
                                      decoration: AppTokens.inputDecoration(
                                        context,
                                        hint: "Select state",
                                      ),
                                      items: stateDropdownItems,
                                      onChanged: (value) {
                                        setState(() {
                                          stateValue = value ?? '';
                                          _isStateValid = true;
                                        });
                                      },
                                      isExpanded: true,
                                      icon: RotationTransition(
                                        turns: const AlwaysStoppedAnimation(
                                            0.25), // 90 degrees in radians
                                        child: Icon(
                                          Icons.arrow_forward_ios_sharp,
                                          color: ThemeManager.black,
                                        ),
                                      ),
                                      iconSize: 20,
                                      elevation: 16,
                                      style: interRegular.copyWith(
                                        fontSize: Dimensions.fontSizeSmall,
                                        color: ThemeManager.black,
                                      ),
                                    ),
                                    const SizedBox(
                                      height: Dimensions.PADDING_SIZE_DEFAULT,
                                    ),
                                    // DropdownButtonFormField<String>(
                                    //   key: _prepParingKey,
                                    // dropdownColor:ThemeManager.white,
                                    //   value: selectedValue.isNotEmpty ? selectedValue : null,
                                    //   validator: (value) {
                                    //     if (value == null || value.isEmpty) {
                                    //       setState(() {
                                    //         _isPreparingValid = false;
                                    //       });
                                    //       return 'Please choose one.';
                                    //     }
                                    //     setState(() {
                                    //       _isPreparingValid = true;
                                    //     });
                                    //     return null;
                                    //   },
                                    //   decoration: InputDecoration(
                                    //     filled: true,
                                    //     fillColor: Colors.transparent,
                                    //     enabledBorder: OutlineInputBorder(
                                    //       borderRadius: BorderRadius.circular(8),
                                    //       borderSide: const BorderSide(color: Colors.grey),
                                    //     ),
                                    //     focusedBorder: OutlineInputBorder(
                                    //       borderRadius: BorderRadius.circular(8),
                                    //       borderSide: const BorderSide(color: Colors.grey),
                                    //     ),
                                    //     errorBorder: OutlineInputBorder(
                                    //       borderRadius: BorderRadius.circular(8),
                                    //       borderSide: const BorderSide(color: Colors.red),
                                    //     ),
                                    //     labelText: 'Preparing for',
                                    //     labelStyle: interRegular.copyWith(
                                    //       fontSize: Dimensions.fontSizeSmall,
                                    //       color: ThemeManager.black,
                                    //     ),
                                    //     contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                    //   ),
                                    //   // items: const [
                                    //   //   DropdownMenuItem(
                                    //   //     value: 'Surgical',
                                    //   //     child: Text('Surgical'),
                                    //   //   ),
                                    //   //   DropdownMenuItem(
                                    //   //     value: 'Medical',
                                    //   //     child: Text('Medical'),
                                    //   //   ),
                                    //   // ],
                                    //   items: dropdownItems,
                                    //   onChanged: (value) {
                                    //     setState(() {
                                    //       selectedCheckboxValues=[];
                                    //       selectedValue = value!;
                                    //       _isPreparingValid = true;
                                    //
                                    //       final selectedItem = store.preparingexams.firstWhere(
                                    //             (item) => item?.preparingFor == selectedValue,
                                    //         orElse: () => null,
                                    //       );
                                    //       availableCheckboxes = selectedItem != null ? List<String>.from(selectedItem.checkbox as List<dynamic>) : [];
                                    //     });
                                    //   },
                                    //   isExpanded: true,
                                    //   icon: Icon(Icons.keyboard_arrow_down,
                                    //     color: Theme.of(context).disabledColor,),
                                    //   iconSize: 24,
                                    //   elevation: 16,
                                    //   style: interRegular.copyWith(
                                    //     fontSize: Dimensions.fontSizeSmall,
                                    //     color: ThemeManager.black,
                                    //   ),
                                    // ),
                                    // const SizedBox(width: Dimensions.PADDING_SIZE_EXTRA_LARGE),
                                    // if (availableCheckboxes.isNotEmpty)
                                    //   ListView.builder(
                                    //     padding: const EdgeInsets.only(top: 0),
                                    //     shrinkWrap: true,
                                    //     itemCount: availableCheckboxes.length,
                                    //     itemBuilder: (context, index) {
                                    //       final checkboxValue = availableCheckboxes[index];
                                    //       final isChecked = selectedCheckboxValues.contains(checkboxValue);
                                    //       return Row(
                                    //         children: [
                                    //           Checkbox(
                                    //             materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    //             visualDensity: VisualDensity.compact,
                                    //             value: isChecked,
                                    //             onChanged: (value) {
                                    //               setState(() {
                                    //                 if (value!) {
                                    //                   selectedCheckboxValues.add(checkboxValue);
                                    //                 } else {
                                    //                   selectedCheckboxValues.remove(checkboxValue);
                                    //                 }
                                    //               });
                                    //             },
                                    //             activeColor: Theme.of(context).primaryColor,
                                    //             side: BorderSide(
                                    //               color: Theme.of(context).disabledColor,
                                    //             ),
                                    //           ),
                                    //           Text(
                                    //             checkboxValue,
                                    //             style: interRegular.copyWith(
                                    //                 fontSize: Dimensions.fontSizeSmall,
                                    //                 color: ThemeManager.black,
                                    //                 fontWeight: FontWeight.w400
                                    //             ),
                                    //           ),
                                    //         ],
                                    //       );
                                    //     },
                                    //   ),
                                    Row(
                                      children: [
                                        Text(
                                          "Preparing for: ",
                                          style: interMedium.copyWith(
                                              fontSize: Dimensions.fontSizeSmall,
                                              color: ThemeManager.black),
                                        ),
                                        Text(
                                          "${selectedValue.isNotEmpty ? selectedValue : null}",
                                          style: interBold.copyWith(
                                              fontSize:
                                                  Dimensions.fontSizeDefault,
                                              color: ThemeManager.primaryColor),
                                        ),
                                      ],
                                    ),
                                    // Text("Preparing for: $selectedValue",
                                    //   style: interRegular.copyWith(
                                    //       fontSize: Dimensions.fontSizeDefault,
                                    //       color: ThemeManager.black,
                                    //       fontWeight: FontWeight.w500
                                    //   ),),
                                    const SizedBox(
                                      height: Dimensions.PADDING_SIZE_SMALL,
                                    ),
                                    Wrap(
                                        spacing: Dimensions.PADDING_SIZE_SMALL,
                                        runSpacing:
                                            Dimensions.PADDING_SIZE_SMALL * 1.1,
                                        children: List.generate(
                                            store.userDetails.value?.exams
                                                    ?.length ??
                                                0,
                                            (index) => Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: Dimensions
                                                          .PADDING_SIZE_DEFAULT,
                                                      vertical: Dimensions
                                                              .PADDING_SIZE_EXTRA_SMALL *
                                                          1.6),
                                                  // alignment: Alignment.center,
                                                  decoration: BoxDecoration(
                                                      color: ThemeManager.white,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              50),
                                                      border: Border.all(
                                                        color: ThemeManager
                                                            .primaryColor,
                                                      )),
                                                  child: Text(
                                                    store.userDetails.value
                                                            ?.exams?[index] ??
                                                        '',
                                                    style: interRegular.copyWith(
                                                        fontSize: Dimensions
                                                            .fontSizeExtraSmall,
                                                        color:
                                                            ThemeManager.black),
                                                  ),
                                                ))),
                                    // ListView.builder(
                                    //   itemCount: widget.userprofile.exams?.length,
                                    //   shrinkWrap: true,
                                    //   itemBuilder: (context, index) {
                                    //     return Column(
                                    //       children: [
                                    //         Row(
                                    //           children: [
                                    //             Text('\u2022 ',
                                    //               style: interRegular.copyWith(
                                    //                   fontSize: Dimensions.fontSizeSmall,
                                    //                   color: ThemeManager.black,
                                    //                   fontWeight: FontWeight.w500
                                    //               ),
                                    //             ),
                                    //             Text(widget.userprofile.exams?[index]??"",
                                    //               style: interRegular.copyWith(
                                    //                   fontSize: Dimensions.fontSizeSmall,
                                    //                   color: ThemeManager.black,
                                    //                   fontWeight: FontWeight.w500
                                    //               ),
                                    //             ),
                                    //           ],
                                    //         ),
                                    //         const SizedBox(
                                    //           height: Dimensions.PADDING_SIZE_SMALL,
                                    //         ),
                                    //       ],
                                    //     );
                                    //   },
                                    // ),
                                    const SizedBox(
                                      height:
                                          Dimensions.PADDING_SIZE_DEFAULT * 1.1,
                                    ),
                                    Text(
                                      "What are you currently doing?",
                                      style: interRegular.copyWith(
                                          fontSize: Dimensions.fontSizeSmall,
                                          color: ThemeManager.black,
                                          fontWeight: FontWeight.w500),
                                    ),
                                    const SizedBox(
                                      height: Dimensions.PADDING_SIZE_DEFAULT,
                                    ),
                            
                                    Row(
                                      children: [
                                        Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Checkbox(
                                                materialTapTargetSize:
                                                    MaterialTapTargetSize
                                                        .shrinkWrap,
                                                visualDensity:
                                                    VisualDensity.compact,
                                                value: currentStatus ==
                                                    "PG Resident",
                                                onChanged: (value) {
                                                  setState(() {
                                                    isChecked = value!;
                                                    if (isChecked) {
                                                      currentStatus =
                                                          "PG Resident";
                                                    } else {
                                                      currentStatus = null;
                                                    }
                                                  });
                                                },
                                                activeColor:
                                                    ThemeManager.primaryColor,
                                                side: BorderSide(
                                                  color: ThemeManager.grey1,
                                                ),
                                              ),
                                              Text(
                                                'PG Resident',
                                                style: interRegular.copyWith(
                                                    fontSize:
                                                        Dimensions.fontSizeSmall,
                                                    color: ThemeManager.black,
                                                    fontWeight: FontWeight.w500),
                                              ),
                                            ]),
                                        const SizedBox(
                                            width: Dimensions.PADDING_SIZE_LARGE *
                                                1.7),
                                        Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Checkbox(
                                                materialTapTargetSize:
                                                    MaterialTapTargetSize
                                                        .shrinkWrap,
                                                visualDensity:
                                                    VisualDensity.compact,
                                                value: currentStatus ==
                                                    "Post-Graduate",
                                                onChanged: (value) {
                                                  setState(() {
                                                    isChecked = value!;
                                                    if (isChecked) {
                                                      currentStatus =
                                                          "Post-Graduate";
                                                    } else {
                                                      currentStatus = null;
                                                    }
                                                  });
                                                },
                                                activeColor:
                                                    ThemeManager.primaryColor,
                                                side: BorderSide(
                                                  color: ThemeManager.grey1,
                                                ),
                                              ),
                                              Text(
                                                'Post-Graduate',
                                                style: interRegular.copyWith(
                                                    fontSize:
                                                        Dimensions.fontSizeSmall,
                                                    color: ThemeManager.black,
                                                    fontWeight: FontWeight.w500),
                                              ),
                                            ]),
                                      ],
                                    ),
                                    if (isSubmitted && !isCheckboxChecked())
                                      Text(
                                        'Please select at least one option.',
                                        style: interRegular.copyWith(
                                            fontSize: Dimensions.fontSizeSmall,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .error),
                                      ),
                                    const SizedBox(
                                      height: Dimensions.PADDING_SIZE_DEFAULT,
                                    ),
                                    Container(
                                      constraints: const BoxConstraints(
                                        minHeight:
                                            Dimensions.PADDING_SIZE_EXTRA_LARGE *
                                                2,
                                      ),
                                      child: TextFormField(
                                        key: _mobileKey,
                                        cursorColor: ThemeManager.textColor4,
                                        style: interRegular.copyWith(
                                            fontSize: Dimensions.fontSizeDefault,
                                            color: ThemeManager.textColor4),
                                        controller: phoneController,
                                        maxLength: 10,
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            setState(() {
                                              _isMobileValid = false;
                                            });
                                            return 'Please enter mobile number.';
                                          }
                                          setState(() {
                                            _isMobileValid = true;
                                          });
                                          return null;
                                        },
                                        keyboardType: TextInputType.phone,
                                        decoration: AppTokens.inputDecoration(
                                          context,
                                          hint: 'Mobile number',
                                          prefix: IntrinsicHeight(
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          left: AppTokens.s12,
                                                          right: AppTokens.s8),
                                                  child: Text(
                                                    "+91",
                                                    style: AppTokens
                                                            .titleSm(context)
                                                        .copyWith(
                                                      color: AppTokens.ink(
                                                          context),
                                                    ),
                                                  ),
                                                ),
                                                VerticalDivider(
                                                  color: AppTokens.border(
                                                      context),
                                                )
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    // const SizedBox(
                                    //   height: Dimensions.PADDING_SIZE_EXTRA_SMALL,
                                    // ),
                                    // Align(
                                    //   alignment: Alignment.centerRight,
                                    //   child: InkWell(
                                    //     onTap: (){
                                    //       // showModalBottomSheet<void>(
                                    //       //   shape: const RoundedRectangleBorder(
                                    //       //     borderRadius: BorderRadius.vertical(
                                    //       //       top: Radius.circular(25),
                                    //       //     ),
                                    //       //   ),
                                    //       //   clipBehavior: Clip.antiAliasWithSaveLayer,
                                    //       //   context: context,
                                    //       //   builder: (BuildContext context) {
                                    //       //     return CustomChangeMobileBottomSheet(context, true);
                                    //       //   },
                                    //       // );
                                    //     },
                                    //     child: Text("Change number",
                                    //       style: interRegular.copyWith(
                                    //         decoration: (TextDecoration.underline),
                                    //           fontSize: Dimensions.fontSizeExtraSmall,
                                    //           color: ThemeManager.primaryColor,
                                    //           fontWeight: FontWeight.w500
                                    //       ),
                                    //     ),
                                    //   ),
                                    // ),
                                    const SizedBox(
                                      height: Dimensions.PADDING_SIZE_DEFAULT,
                                    ),
                                    Container(
                                      constraints: const BoxConstraints(
                                        minHeight:
                                            Dimensions.PADDING_SIZE_EXTRA_LARGE *
                                                2,
                                      ),
                                      child: TextFormField(
                                        key: _emailKey,
                                        onChanged: (value) {
                                          setState(() {
                                            _isEmailValid =
                                                _emailRegex.hasMatch(value);
                                          });
                                        },
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            setState(() {
                                              _isEmailValid = false;
                                            });
                                            return 'Please enter an email address.';
                                          } else if (!_emailRegex
                                              .hasMatch(value)) {
                                            setState(() {
                                              _isEmailValid = false;
                                            });
                                            return 'Please enter a valid email address.';
                                          }
                                          setState(() {
                                            _isEmailValid = true;
                                          });
                                          return null;
                                        },
                                        cursorColor: ThemeManager.textColor4,
                                        style: interRegular.copyWith(
                                            fontSize: Dimensions.fontSizeDefault,
                                            color: ThemeManager.textColor4),
                                        controller: emailController,
                                        keyboardType:
                                            TextInputType.emailAddress,
                                        decoration: AppTokens.inputDecoration(
                                          context,
                                          hint: 'Email address',
                                        ),
                                      ),
                                    ),
                                    // const SizedBox(
                                    //   height: Dimensions.PADDING_SIZE_EXTRA_SMALL,
                                    // ),
                                    // Align(
                                    //   alignment: Alignment.centerRight,
                                    //   child: InkWell(
                                    //     onTap: (){
                                    //       // showModalBottomSheet<void>(
                                    //       //   shape: const RoundedRectangleBorder(
                                    //       //     borderRadius: BorderRadius.vertical(
                                    //       //       top: Radius.circular(25),
                                    //       //     ),
                                    //       //   ),
                                    //       //   clipBehavior: Clip.antiAliasWithSaveLayer,
                                    //       //   context: context,
                                    //       //   builder: (BuildContext context) {
                                    //       //     return CustomChangeMobileBottomSheet(context, false);
                                    //       //   },
                                    //       // );
                                    //     },
                                    //     child: Text("Change Email ID",
                                    //       style: interRegular.copyWith(
                                    //           decoration: (TextDecoration.underline),
                                    //           fontSize: Dimensions.fontSizeExtraSmall,
                                    //           color: ThemeManager.primaryColor,
                                    //           fontWeight: FontWeight.w500
                                    //       ),
                                    //     ),
                                    //   ),
                                    // ),
                                    const SizedBox(
                                      height:
                                          Dimensions.PADDING_SIZE_EXTRA_LARGE * 3,
                                    ),
                                    SizedBox(
                                      width: double.infinity,
                                      height: 52,
                                      child: ElevatedButton(
                                        onPressed: () {
                                          FocusScope.of(context).unfocus();
                                          _updateProfile(
                                              store.userDetails.value?.id ?? "",
                                              nameController.text,
                                              dateController.text,
                                              selectedValue,
                                              stateValue,
                                              selectedCheckboxValues,
                                              currentStatus ?? "",
                                              phoneController.text,
                                              emailController.text);
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              AppTokens.accent(context),
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          shadowColor: Colors.transparent,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                AppTokens.radius16,
                                          ),
                                        ),
                                        child: Text(
                                          "Save profile",
                                          style: AppTokens.titleSm(context)
                                              .copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                    // const SizedBox(
                                    //   height: Dimensions.PADDING_SIZE_DEFAULT,
                                    // ),
                                    // Row(
                                    //   children: [
                                    //     Expanded(
                                    //       child: CustomButton(onPressed: (){
                                    //         showDialog(
                                    //           context: context,
                                    //           builder: (context) => AlertDialog(
                                    //             content: Text('Do you want to Delete this Account? ',
                                    //               style: interRegular.copyWith(
                                    //                 fontSize: Dimensions.fontSizeLarge,
                                    //                 fontWeight: FontWeight.w500,
                                    //                 color: ThemeManager.white,),
                                    //             ),
                                    //             actions: [
                                    //               TextButton(
                                    //                 style: TextButton.styleFrom(
                                    //                     foregroundColor: Colors.white,
                                    //                     elevation: 2,
                                    //                     backgroundColor: Theme.of(context).hintColor),
                                    //                 onPressed: () => Navigator.pop(context, false),
                                    //                 child: Text('No',
                                    //                     style: interRegular.copyWith(
                                    //                       fontSize: Dimensions.fontSizeDefault,
                                    //                       fontWeight: FontWeight.w500,
                                    //                       color: ThemeManager.white,)),
                                    //               ),
                                    //               TextButton(
                                    //                 style: TextButton.styleFrom(
                                    //                     foregroundColor: Colors.white,
                                    //                     elevation: 2,
                                    //                     backgroundColor: Theme.of(context).primaryColor),
                                    //                 onPressed: () {
                                    //                   _deleteAccountUser();
                                    //                   Navigator.of(context).pushNamed(Routes.loginWithPass);
                                    //                 },
                                    //                 child: Text('Yes',
                                    //                     style: interRegular.copyWith(
                                    //                       fontSize: Dimensions.fontSizeDefault,
                                    //                       fontWeight: FontWeight.w500,
                                    //                       color: ThemeManager.white,)),
                                    //               ),
                                    //             ],
                                    //           )
                                    //         );
                                    //       },
                                    //         buttonText: "Delete Account",
                                    //         height: Dimensions.PADDING_SIZE_EXTRA_LARGE*2,
                                    //         textAlign: TextAlign.center,
                                    //         radius: Dimensions.RADIUS_DEFAULT,
                                    //         transparent: true,
                                    //         bgColor: Theme.of(context).primaryColor,
                                    //         fontSize: Dimensions.fontSizeDefault,
                                    //       ),
                                    //     ),
                                    //     const SizedBox(
                                    //       width: Dimensions.PADDING_SIZE_DEFAULT,
                                    //     ),
                                    //     Expanded(
                                    //       child: CustomButton(onPressed: (){
                                    //         showDialog(
                                    //             context: context,
                                    //             builder: (context) => AlertDialog(
                                    //               backgroundColor: ThemeManager.white,
                                    //               content: Text('Do you want to logout this Account? ',
                                    //                 style: interRegular.copyWith(
                                    //                   fontSize: Dimensions.fontSizeLarge,
                                    //                   fontWeight: FontWeight.w500,
                                    //                   color: ThemeManager.black,),
                                    //               ),
                                    //               actions: [
                                    //                 TextButton(
                                    //                   style: TextButton.styleFrom(
                                    //                       foregroundColor: Colors.white,
                                    //                       elevation: 2,
                                    //                       backgroundColor: Theme.of(context).hintColor),
                                    //                   onPressed: () => Navigator.pop(context, false),
                                    //                   child: Text('No',
                                    //                       style: interRegular.copyWith(
                                    //                         fontSize: Dimensions.fontSizeDefault,
                                    //                         fontWeight: FontWeight.w500,
                                    //                         color: ThemeManager.white,)),
                                    //                 ),
                                    //                 TextButton(
                                    //                   style: TextButton.styleFrom(
                                    //                       foregroundColor: Colors.white,
                                    //                       elevation: 2,
                                    //                       backgroundColor: Theme.of(context).primaryColor),
                                    //                   onPressed: () {
                                    //                     signOut(store,loggedInPlatform);
                                    //                   },
                                    //                   child: Text('Yes',
                                    //                       style: interRegular.copyWith(
                                    //                         fontSize: Dimensions.fontSizeDefault,
                                    //                         fontWeight: FontWeight.w500,
                                    //                         color: ThemeManager.white,)),
                                    //                 ),
                                    //               ],
                                    //             )
                                    //         );
                                    //       },
                                    //         buttonText: "Logout",
                                    //         height: Dimensions.PADDING_SIZE_EXTRA_LARGE*2,
                                    //         textAlign: TextAlign.center,
                                    //         radius: Dimensions.RADIUS_DEFAULT,
                                    //         transparent: true,
                                    //         bgColor: Theme.of(context).primaryColor,
                                    //         fontSize: Dimensions.fontSizeDefault,
                                    //       ),
                                    //     ),
                                    //   ],
                                    // ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  : const NoInternetWidget(),
    );
  }

  Future<void> _updateProfile(
      String userId,
      String fullname,
      String dob,
      String preparingFor,
      String stateVal,
      List<String> preparingExams,
      String currentData,
      String phone,
      String email) async {
    final store = Provider.of<HomeStore>(context, listen: false);
    await store.onUpdateUserDetailsCall(userId, fullname, dob, preparingFor,
        stateVal, preparingExams, currentData, phone, email, context);

    if (store.updateUserDetails.value?.msg == "Successfully update user...") {
      BottomToast.showBottomToastOverlay(
        context: context,
        errorMessage: "Profile Updated Successfully.",
        backgroundColor: Theme.of(context).primaryColor,
      );
      Navigator.of(context).pushNamed(Routes.dashboard);
    } else {
      BottomToast.showBottomToastOverlay(
        context: context,
        errorMessage: "Profile Not Updated Successfully.",
        backgroundColor: Theme.of(context).primaryColor,
      );
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
              onPrimary: Colors.white,
              onSurface: Colors.blue,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: ThemeManager.currentTheme == AppTheme.Dark
                    ? ThemeManager.white
                    : Theme.of(context).primaryColor,
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        final formattedDate = DateFormat('dd/MM/yyyy').format(picked);
        dateController.text = formattedDate;
      });
    }
  }
}
