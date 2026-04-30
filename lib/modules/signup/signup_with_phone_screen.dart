// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_svg/svg.dart';
// import 'package:google_sign_in/google_sign_in.dart';
// import 'package:intl/intl.dart';
// import 'package:mobx/mobx.dart';
// import 'package:otpless_flutter/otpless_flutter.dart';
// import 'package:provider/provider.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:shusruta_lms/modules/signup/store/signup_store.dart';
// import 'package:flutter_mobx/flutter_mobx.dart';
// import 'package:shusruta_lms/modules/widgets/bottom_toast.dart';
// import '../../app/routes.dart';
// import '../../helpers/colors.dart';
// import '../../helpers/dimensions.dart';
// import '../../helpers/styles.dart';
// import '../login/store/login_store.dart';
// import '../widgets/custom_button.dart';
//
// class SignUpWithPhoneScreen extends StatefulWidget {
//   const SignUpWithPhoneScreen({Key? key}) : super(key: key);
//
//   @override
//   State<SignUpWithPhoneScreen> createState() => _SignUpWithPhoneScreenState();
//   static Route<dynamic> route(RouteSettings routeSettings) {
//     return CupertinoPageRoute(
//       builder: (_) => const SignUpWithPhoneScreen(),
//     );
//   }
// }
//
// class _SignUpWithPhoneScreenState extends State<SignUpWithPhoneScreen> with WidgetsBindingObserver {
//   final FirebaseAuth auth = FirebaseAuth.instance;
//   bool isSignIn =false;
//   bool google =false;
//   String? _fcmToken;
//   final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
//   bool isKeyboardOpen = false;
//   final TextEditingController nameController = TextEditingController();
//   final TextEditingController dateController = TextEditingController();
//   final TextEditingController phoneController = TextEditingController();
//   final TextEditingController emailController = TextEditingController();
//   final TextEditingController passwordController = TextEditingController();
//   final TextEditingController confirmPassController = TextEditingController();
//   DateTime? selectedDate;
//   String selectedValue='';
//   List<String> selectedCheckboxValues = [];
//   String? currentStatus;
//   bool isChecked=false;
//   final _emailKey = GlobalKey<FormFieldState<String>>();
//   final _nameKey = GlobalKey<FormFieldState<String>>();
//   final _prepParingKey = GlobalKey<FormFieldState<String>>();
//   final _passKey = GlobalKey<FormFieldState<String>>();
//   final _repassKey = GlobalKey<FormFieldState<String>>();
//   final _mobileKey = GlobalKey<FormFieldState<String>>();
//   final _dobKey = GlobalKey<FormFieldState<String>>();
//   final _emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
//   bool _isEmailValid = false;
//   bool _isPasswordValid = false;
//   bool _isMobileValid = false;
//   bool _isNameValid = false;
//   bool _isDateValid = false;
//   bool _isPreparingValid = false;
//   bool isSubmitted = false;
//
//   bool isCheckboxChecked() {
//     return currentStatus == "PG Resident" || currentStatus == "Post-Graduate";
//   }
//
//   String? validateCheckbox() {
//     if (!isCheckboxChecked()) {
//       return 'Please select at least one option.';
//     }
//     return null;
//   }
//
//   @override
//   void initState() {
//     super.initState();
//     // _otplessFlutterPlugin.hideFabButton();
//     WidgetsBinding.instance?.addObserver(this);
//   }
//
//   @override
//   void dispose() {
//     WidgetsBinding.instance?.removeObserver(this);
//     super.dispose();
//   }
//
//   @override
//   void didChangeMetrics() {
//     final bottomInset = WidgetsBinding.instance?.window.viewInsets.bottom ?? 0;
//     setState(() {
//       isKeyboardOpen = bottomInset > 0;
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final store = Provider.of<SignupStore>(context, listen: false);
//     final loginStore = Provider.of<LoginStore>(context, listen: false);
//     return Scaffold(
//       backgroundColor: ThemeManager.white,
//       body: SingleChildScrollView(
//         child: SizedBox(
//           // height: MediaQuery.of(context).size.height,
//           child: Padding(
//             padding: EdgeInsets.only(
//               left: Dimensions.PADDING_SIZE_LARGE,
//               top: Dimensions.PADDING_SIZE_EXTRA_LARGE * 4,
//               right: Dimensions.PADDING_SIZE_LARGE,
//               bottom: isKeyboardOpen
//                   ? MediaQuery.of(context).viewInsets.bottom
//                   : Dimensions.PADDING_SIZE_LARGE * 2,
//             ),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.start,
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     // Image.asset("assets/image/hand_alert.png"),
//                     // const SizedBox(
//                     //   width: Dimensions.PADDING_SIZE_LARGE,
//                     // ),
//                     Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           "Hello!!",
//                           style: interSemiBold.copyWith(
//                             fontSize: Dimensions.fontSizeExtraLarge,
//                           ),
//                         ),
//                         Text(
//                           "Welcome to Sushruta LGS!",
//                           style: interSemiBold.copyWith(
//                             fontSize: Dimensions.fontSizeExtraLarge,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//                 const SizedBox(
//                   height: Dimensions.PADDING_SIZE_LARGE * 2,
//                 ),
//                 Container(
//                   constraints: const BoxConstraints(
//                     minHeight: Dimensions.PADDING_SIZE_EXTRA_LARGE * 2,
//                   ),
//                   child: TextFormField(
//                     key: _nameKey,
//                     cursorColor: Theme.of(context).disabledColor,
//                     style: interRegular.copyWith(
//                       fontSize: Dimensions.fontSizeDefault,
//                     ),
//                     controller: nameController,
//                     validator: (value) {
//                       if (value == null || value.isEmpty) {
//                         setState(() {
//                           _isNameValid = false;
//                         });
//                         return 'Please enter full name.';
//                       }
//                       setState(() {
//                         _isNameValid = true;
//                       });
//                       return null;
//                     },
//                     keyboardType: TextInputType.name,
//                     decoration: InputDecoration(
//                       fillColor: Theme.of(context).disabledColor,
//                       enabledBorder: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(
//                           Dimensions.RADIUS_SMALL,
//                         ),
//                         borderSide: BorderSide(
//                           color: Theme.of(context).disabledColor,
//                         ),
//                       ),
//                       labelText: 'Full name',
//                       hintText: 'Full name',
//                       hintStyle: interRegular.copyWith(
//                         fontSize: Dimensions.fontSizeSmall,
//                         color: ThemeManager.black,
//                       ),
//                       labelStyle: interRegular.copyWith(
//                         fontSize: Dimensions.fontSizeSmall,
//                         color: ThemeManager.black,
//                       ),
//                       counterText: '',
//                       focusedBorder: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(
//                           Dimensions.RADIUS_SMALL,
//                         ),
//                         borderSide: BorderSide(
//                           color: Theme.of(context).disabledColor,
//                         ),
//                       ),
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(
//                           Dimensions.RADIUS_SMALL,
//                         ),
//                         borderSide: BorderSide(
//                           color: Theme.of(context).disabledColor,
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(
//                   height: Dimensions.PADDING_SIZE_DEFAULT,
//                 ),
//                 Container(
//                   constraints: const BoxConstraints(
//                     minHeight: Dimensions.PADDING_SIZE_EXTRA_LARGE * 2,
//                   ),
//                   child: TextFormField(
//                     key: _dobKey,
//                     onTap: () {
//                       _selectDate(context);
//                     },
//                     cursorColor: Theme.of(context).disabledColor,
//                     style: interRegular.copyWith(
//                       fontSize: Dimensions.fontSizeDefault,
//                     ),
//                     controller: dateController,
//                     validator: (value) {
//                       if (value == null || value.isEmpty) {
//                         setState(() {
//                           _isDateValid = false;
//                         });
//                         return 'Please select date of birth.';
//                       }
//                       setState(() {
//                         _isDateValid = true;
//                       });
//                       return null;
//                     },
//                     readOnly: true,
//                     keyboardType: TextInputType.datetime,
//                     decoration: InputDecoration(
//                       suffixIcon: Icon(Icons.date_range_outlined,color: Theme.of(context).disabledColor,),
//                       fillColor: Theme.of(context).disabledColor,
//                       enabledBorder: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(
//                           Dimensions.RADIUS_SMALL,
//                         ),
//                         borderSide: BorderSide(
//                           color: Theme.of(context).disabledColor,
//                         ),
//                       ),
//                       labelText: 'Date of birth',
//                       hintText: 'Date of birth',
//                       hintStyle: interRegular.copyWith(
//                         fontSize: Dimensions.fontSizeSmall,
//                         color: ThemeManager.black,
//                       ),
//                       labelStyle: interRegular.copyWith(
//                         fontSize: Dimensions.fontSizeSmall,
//                         color: ThemeManager.black,
//                       ),
//                       counterText: '',
//                       focusedBorder: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(
//                           Dimensions.RADIUS_SMALL,
//                         ),
//                         borderSide: BorderSide(
//                           color: Theme.of(context).disabledColor,
//                         ),
//                       ),
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(
//                           Dimensions.RADIUS_SMALL,
//                         ),
//                         borderSide: BorderSide(
//                           color: Theme.of(context).disabledColor,
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(
//                   height: Dimensions.PADDING_SIZE_DEFAULT,
//                 ),
//                 DropdownButtonFormField<String>(
//                   key: _prepParingKey,
//                   dropdownColor:ThemeManager.white,
//                   value: selectedValue.isNotEmpty ? selectedValue : null,
//                   validator: (value) {
//                     if (value == null || value.isEmpty) {
//                       setState(() {
//                         _isPreparingValid = false;
//                       });
//                       return 'Please choose one.';
//                     }
//                     setState(() {
//                       _isPreparingValid = true;
//                     });
//                     return null;
//                   },
//                   decoration: InputDecoration(
//                     filled: true,
//                     fillColor: Colors.transparent,
//                     enabledBorder: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(8),
//                       borderSide: const BorderSide(color: Colors.grey),
//                     ),
//                     focusedBorder: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(8),
//                       borderSide: const BorderSide(color: Colors.grey),
//                     ),
//                     errorBorder: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(8),
//                       borderSide: const BorderSide(color: Colors.red),
//                     ),
//                     labelText: 'Preparing for',
//                     labelStyle: interRegular.copyWith(
//                       fontSize: Dimensions.fontSizeSmall,
//                       color: ThemeManager.black,
//                     ),
//                     contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
//                   ),
//                   items: const [
//                     DropdownMenuItem(
//                       value: 'Surgical',
//                       child: Text('Surgical'),
//                     ),
//                     DropdownMenuItem(
//                       value: 'Medical',
//                       child: Text('Medical'),
//                     ),
//                   ],
//                   onChanged: (value) {
//                     setState(() {
//                       selectedCheckboxValues=[];
//                       selectedValue = value!;
//                       _isPreparingValid = true;
//                     });
//                   },
//                   isExpanded: true,
//                   icon: Icon(Icons.keyboard_arrow_down,
//                     color: Theme.of(context).disabledColor,),
//                   iconSize: 24,
//                   elevation: 16,
//                   style: interRegular.copyWith(
//                     fontSize: Dimensions.fontSizeSmall,
//                     color: ThemeManager.black,
//                   ),
//                 ),
//                 const SizedBox(width: Dimensions.PADDING_SIZE_EXTRA_LARGE),
//                 selectedValue=="Surgical"?
//                 Row(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       Checkbox(
//                         materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
//                         visualDensity: VisualDensity.compact,
//                         value: selectedCheckboxValues.contains('NEET SS'),
//                         onChanged: (value){
//                           setState(() {
//                             isChecked = value!;
//                             if (isChecked) {
//                               selectedCheckboxValues.add('NEET SS');
//                             } else {
//                               selectedCheckboxValues.remove('NEET SS');
//                             }
//                           });
//                         },
//                         activeColor: Theme.of(context).primaryColor,
//                         side: BorderSide(
//                           color: Theme.of(context).disabledColor,
//                         ),
//                       ),
//                       Text('NEET SS',
//                         style: interRegular.copyWith(
//                             fontSize: Dimensions.fontSizeSmall,
//                             color: ThemeManager.black,
//                             fontWeight: FontWeight.w400
//                         ),),
//
//                       Checkbox(
//                         materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
//                         visualDensity: VisualDensity.compact,
//                         value: selectedCheckboxValues.contains('INI SS'),
//                         onChanged: (value){
//                           setState(() {
//                             isChecked = value!;
//                             if (isChecked) {
//                               selectedCheckboxValues.add('INI SS');
//                             } else {
//                               selectedCheckboxValues.remove('INI SS');
//                             }
//                           });
//                         },
//                         activeColor: Theme.of(context).primaryColor,
//                         side: BorderSide(
//                           color: Theme.of(context).disabledColor,
//                         ),
//                       ),
//                       Text('INI SS',
//                         style: interRegular.copyWith(
//                             fontSize: Dimensions.fontSizeSmall,
//                             color: ThemeManager.black,
//                             fontWeight: FontWeight.w400
//                         ),),
//
//                       Checkbox(
//                         materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
//                         visualDensity: VisualDensity.compact,
//                         value: selectedCheckboxValues.contains('MR CS'),
//                         onChanged: (value){
//                           setState(() {
//                             isChecked = value!;
//                             if (isChecked) {
//                               selectedCheckboxValues.add('MR CS');
//                             } else {
//                               selectedCheckboxValues.remove('MR CS');
//                             }
//                           });
//                         },
//                         activeColor: Theme.of(context).primaryColor,
//                         side: BorderSide(
//                           color: Theme.of(context).disabledColor,
//                         ),
//                       ),
//                       Text('MR CS',
//                         style: interRegular.copyWith(
//                             fontSize: Dimensions.fontSizeSmall,
//                             color: ThemeManager.black,
//                             fontWeight: FontWeight.w400
//                         ),),
//                     ]
//                 ):
//                 selectedValue == "Medical"
//                     ? Row(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Checkbox(
//                       materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
//                       visualDensity: VisualDensity.compact,
//                       value: selectedCheckboxValues.contains('NEET SS'),
//                       onChanged: (value) {
//                         setState(() {
//                           isChecked = value!;
//                           if (isChecked) {
//                             selectedCheckboxValues.add('NEET SS');
//                           } else {
//                             selectedCheckboxValues.remove('NEET SS');
//                           }
//                         });
//                       },
//                       activeColor: Theme.of(context).primaryColor,
//                       side: BorderSide(
//                         color: Theme.of(context).disabledColor,
//                       ),
//                     ),
//                     Text(
//                       'NEET SS',
//                       style: interRegular.copyWith(
//                         fontSize: Dimensions.fontSizeSmall,
//                         color: ThemeManager.black,
//                         fontWeight: FontWeight.w400,
//                       ),
//                     ),
//
//                     Checkbox(
//                       materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
//                       visualDensity: VisualDensity.compact,
//                       value: selectedCheckboxValues.contains('INI SS'),
//                       onChanged: (value) {
//                         setState(() {
//                           isChecked = value!;
//                           if (isChecked) {
//                             selectedCheckboxValues.add('INI SS');
//                           } else {
//                             selectedCheckboxValues.remove('INI SS');
//                           }
//                         });
//                       },
//                       activeColor: Theme.of(context).primaryColor,
//                       side: BorderSide(
//                         color: Theme.of(context).disabledColor,
//                       ),
//                     ),
//                     Text(
//                       'INI SS',
//                       style: interRegular.copyWith(
//                         fontSize: Dimensions.fontSizeSmall,
//                         color: ThemeManager.black,
//                         fontWeight: FontWeight.w400,
//                       ),
//                     ),
//                   ],
//                 ) : const SizedBox(),
//                 const SizedBox(
//                   height: Dimensions.PADDING_SIZE_DEFAULT,
//                 ),
//                 Text("What Are You Currently Doing",
//                   style: interRegular.copyWith(
//                       fontSize: Dimensions.fontSizeSmall,
//                       color: ThemeManager.black,
//                       fontWeight: FontWeight.w500
//                   ),
//                 ),
//                 const SizedBox(
//                   height: Dimensions.PADDING_SIZE_DEFAULT,
//                 ),
//                 Row(
//                   children: [
//                     Row(
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           Checkbox(
//                             materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
//                             visualDensity: VisualDensity.compact,
//                             value: currentStatus=="PG Resident",
//                             onChanged: (value){
//                               setState(() {
//                                 isChecked = value!;
//                                 if (isChecked) {
//                                   currentStatus = "PG Resident";
//                                 } else {
//                                   currentStatus = null;
//                                 }
//                               });
//                             },
//                             activeColor:ThemeManager.currentTheme == AppTheme.Dark ? ThemeManager.white :  Theme.of(context).primaryColor,
//                             side: BorderSide(
//                               color: ThemeManager.currentTheme == AppTheme.Dark ? ThemeManager.black : Theme.of(context).disabledColor,
//                             ),
//                           ),
//                           Text('PG Resident',
//                             style: interRegular.copyWith(
//                                 fontSize: Dimensions.fontSizeSmall,
//                                 color: ThemeManager.black,
//                                 fontWeight: FontWeight.w400
//                             ),),
//                         ]
//                     ),
//                     const SizedBox(width: Dimensions.PADDING_SIZE_EXTRA_LARGE),
//                     Row(
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           Checkbox(
//                             materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
//                             visualDensity: VisualDensity.compact,
//                             value: currentStatus=="Post-Graduate",
//                             onChanged: (value){
//                               setState(() {
//                                 isChecked = value!;
//                                 if (isChecked) {
//                                   currentStatus = "Post-Graduate";
//                                 } else {
//                                   currentStatus = null;
//                                 }
//                               });
//                             },
//                             activeColor:ThemeManager.currentTheme == AppTheme.Dark ? ThemeManager.white :  Theme.of(context).primaryColor,
//                             side: BorderSide(
//                               color: ThemeManager.currentTheme == AppTheme.Dark ? ThemeManager.black : Theme.of(context).disabledColor,
//                             ),
//                           ),
//                           Text('Post-Graduate',
//                             style: interRegular.copyWith(
//                                 fontSize: Dimensions.fontSizeSmall,
//                                 color: ThemeManager.black,
//                                 fontWeight: FontWeight.w400
//                             ),),
//                         ]
//                     ),
//                   ],
//                 ),
//                 if (isSubmitted && !isCheckboxChecked())
//                   Text(
//                     'Please select at least one option.',
//                     style: interRegular.copyWith(
//                         fontSize: Dimensions.fontSizeSmall,
//                         color: Theme.of(context).colorScheme.error),
//                   ),
//                 const SizedBox(
//                   height: Dimensions.PADDING_SIZE_DEFAULT,
//                 ),
//                 Container(
//                   constraints: const BoxConstraints(
//                     minHeight: Dimensions.PADDING_SIZE_EXTRA_LARGE * 2,
//                   ),
//                   child: TextFormField(
//                     key: _mobileKey,
//                     cursorColor: Theme.of(context).disabledColor,
//                     style: interRegular.copyWith(
//                       fontSize: Dimensions.fontSizeDefault,
//                     ),
//                     controller: phoneController,
//                     maxLength: 10,
//                     validator: (value) {
//                       if (value == null || value.isEmpty) {
//                         setState(() {
//                           _isMobileValid = false;
//                         });
//                         return 'Please enter mobile number.';
//                       }
//                       setState(() {
//                         _isMobileValid = true;
//                       });
//                       return null;
//                     },
//                     keyboardType: TextInputType.phone,
//                     decoration: InputDecoration(
//                       fillColor: Theme.of(context).disabledColor,
//                       enabledBorder: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(
//                           Dimensions.RADIUS_SMALL,
//                         ),
//                         borderSide: BorderSide(
//                           color: Theme.of(context).disabledColor,
//                         ),
//                       ),
//                       labelText: 'Mobile number',
//                       hintText: 'Mobile number',
//                       hintStyle: interRegular.copyWith(
//                         fontSize: Dimensions.fontSizeSmall,
//                         color: ThemeManager.black,
//                       ),
//                       labelStyle: interRegular.copyWith(
//                         fontSize: Dimensions.fontSizeSmall,
//                         color: ThemeManager.black,
//                       ),
//                       counterText: '',
//                       focusedBorder: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(
//                           Dimensions.RADIUS_SMALL,
//                         ),
//                         borderSide: BorderSide(
//                           color: Theme.of(context).disabledColor,
//                         ),
//                       ),
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(
//                           Dimensions.RADIUS_SMALL,
//                         ),
//                         borderSide: BorderSide(
//                           color: Theme.of(context).disabledColor,
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(
//                   height: Dimensions.PADDING_SIZE_DEFAULT,
//                 ),
//                 Container(
//                   constraints: const BoxConstraints(
//                     minHeight: Dimensions.PADDING_SIZE_EXTRA_LARGE * 2,
//                   ),
//                   child: TextFormField(
//                     key: _emailKey,
//                     onChanged: (value) {
//                       setState(() {
//                         _isEmailValid = _emailRegex.hasMatch(value);
//                       });
//                     },
//                     validator: (value) {
//                       if (value == null || value.isEmpty) {
//                         setState(() {
//                           _isEmailValid = false;
//                         });
//                         return 'Please enter an email address.';
//                       } else if (!_emailRegex.hasMatch(value)) {
//                         setState(() {
//                           _isEmailValid = false;
//                         });
//                         return 'Please enter a valid email address.';
//                       }
//                       setState(() {
//                         _isEmailValid = true;
//                       });
//                       return null;
//                     },
//                     cursorColor: Theme.of(context).disabledColor,
//                     style: interRegular.copyWith(
//                       fontSize: Dimensions.fontSizeDefault,
//                     ),
//                     controller: emailController,
//                     keyboardType: TextInputType.emailAddress,
//                     decoration: InputDecoration(
//                       fillColor: Theme.of(context).disabledColor,
//                       enabledBorder: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(
//                           Dimensions.RADIUS_SMALL,
//                         ),
//                         borderSide: BorderSide(
//                           color: Theme.of(context).disabledColor,
//                         ),
//                       ),
//                       labelText: 'Enter email',
//                       hintText: 'Enter email',
//                       hintStyle: interRegular.copyWith(
//                         fontSize: Dimensions.fontSizeSmall,
//                         color: ThemeManager.black,
//                       ),
//                       labelStyle: interRegular.copyWith(
//                         fontSize: Dimensions.fontSizeSmall,
//                         color: ThemeManager.black,
//                       ),
//                       counterText: '',
//                       focusedBorder: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(
//                           Dimensions.RADIUS_SMALL,
//                         ),
//                         borderSide: BorderSide(
//                           color: Theme.of(context).disabledColor,
//                         ),
//                       ),
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(
//                           Dimensions.RADIUS_SMALL,
//                         ),
//                         borderSide: BorderSide(
//                           color: Theme.of(context).disabledColor,
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(
//                   height: Dimensions.PADDING_SIZE_DEFAULT,
//                 ),
//                 // Container(
//                 //   constraints: const BoxConstraints(
//                 //     minHeight: Dimensions.PADDING_SIZE_EXTRA_LARGE * 2,
//                 //   ),
//                 //   child: TextFormField(
//                 //     key: _passKey,
//                 //     obscureText: true,
//                 //     cursorColor: Theme.of(context).disabledColor,
//                 //     style: interRegular.copyWith(
//                 //       fontSize: Dimensions.fontSizeDefault,
//                 //     ),
//                 //     controller: passwordController,
//                 //     validator: (value) {
//                 //       if (value == null || value.isEmpty) {
//                 //         setState(() {
//                 //           _isPasswordValid = false;
//                 //         });
//                 //         return 'Please enter an password.';
//                 //       }
//                 //       setState(() {
//                 //         _isPasswordValid = true;
//                 //       });
//                 //       return null;
//                 //     },
//                 //     keyboardType: TextInputType.visiblePassword,
//                 //     decoration: InputDecoration(
//                 //       fillColor: Theme.of(context).disabledColor,
//                 //       enabledBorder: OutlineInputBorder(
//                 //         borderRadius: BorderRadius.circular(
//                 //           Dimensions.RADIUS_SMALL,
//                 //         ),
//                 //         borderSide: BorderSide(
//                 //           color: Theme.of(context).disabledColor,
//                 //         ),
//                 //       ),
//                 //       labelText: 'Create Password',
//                 //       hintText: 'Create Password',
//                 //       hintStyle: interRegular.copyWith(
//                 //         fontSize: Dimensions.fontSizeSmall,
//                 //         color: ThemeManager.black,
//                 //       ),
//                 //       labelStyle: interRegular.copyWith(
//                 //         fontSize: Dimensions.fontSizeSmall,
//                 //         color: ThemeManager.black,
//                 //       ),
//                 //       counterText: '',
//                 //       focusedBorder: OutlineInputBorder(
//                 //         borderRadius: BorderRadius.circular(
//                 //           Dimensions.RADIUS_SMALL,
//                 //         ),
//                 //         borderSide: BorderSide(
//                 //           color: Theme.of(context).disabledColor,
//                 //         ),
//                 //       ),
//                 //       border: OutlineInputBorder(
//                 //         borderRadius: BorderRadius.circular(
//                 //           Dimensions.RADIUS_SMALL,
//                 //         ),
//                 //         borderSide: BorderSide(
//                 //           color: Theme.of(context).disabledColor,
//                 //         ),
//                 //       ),
//                 //     ),
//                 //   ),
//                 // ),
//                 // const SizedBox(
//                 //   height: Dimensions.PADDING_SIZE_DEFAULT,
//                 // ),
//                 // Container(
//                 //   constraints: const BoxConstraints(
//                 //     minHeight: Dimensions.PADDING_SIZE_EXTRA_LARGE * 2,
//                 //   ),
//                 //   child: TextFormField(
//                 //     key: _repassKey,
//                 //     obscureText: true,
//                 //     cursorColor: Theme.of(context).disabledColor,
//                 //     style: interRegular.copyWith(
//                 //       fontSize: Dimensions.fontSizeDefault,
//                 //     ),
//                 //     controller: confirmPassController,
//                 //     validator: (value) {
//                 //       if (value == null || value.isEmpty) {
//                 //         setState(() {
//                 //           _isPasswordValid = false;
//                 //         });
//                 //         return 'Please enter an confirm password.';
//                 //       }
//                 //       setState(() {
//                 //         _isPasswordValid = true;
//                 //       });
//                 //       return null;
//                 //     },
//                 //     keyboardType: TextInputType.visiblePassword,
//                 //     decoration: InputDecoration(
//                 //       fillColor: Theme.of(context).disabledColor,
//                 //       enabledBorder: OutlineInputBorder(
//                 //         borderRadius: BorderRadius.circular(
//                 //           Dimensions.RADIUS_SMALL,
//                 //         ),
//                 //         borderSide: BorderSide(
//                 //           color: Theme.of(context).disabledColor,
//                 //         ),
//                 //       ),
//                 //       labelText: 'Re-enter Password',
//                 //       hintText: 'Re-enter Password',
//                 //       hintStyle: interRegular.copyWith(
//                 //         fontSize: Dimensions.fontSizeSmall,
//                 //         color: ThemeManager.black,
//                 //       ),
//                 //       labelStyle: interRegular.copyWith(
//                 //         fontSize: Dimensions.fontSizeSmall,
//                 //         color: ThemeManager.black,
//                 //       ),
//                 //       counterText: '',
//                 //       focusedBorder: OutlineInputBorder(
//                 //         borderRadius: BorderRadius.circular(
//                 //           Dimensions.RADIUS_SMALL,
//                 //         ),
//                 //         borderSide: BorderSide(
//                 //           color: Theme.of(context).disabledColor,
//                 //         ),
//                 //       ),
//                 //       border: OutlineInputBorder(
//                 //         borderRadius: BorderRadius.circular(
//                 //           Dimensions.RADIUS_SMALL,
//                 //         ),
//                 //         borderSide: BorderSide(
//                 //           color: Theme.of(context).disabledColor,
//                 //         ),
//                 //       ),
//                 //     ),
//                 //   ),
//                 // ),
//                 // const SizedBox(
//                 //   height: Dimensions.PADDING_SIZE_DEFAULT,
//                 // ),
//                 Column(
//                   children: [
//                     // const Spacer(),
//                     Observer(
//                         builder: (_){
//                           return  CustomButton(
//                             onPressed: () {
//                               FocusScope.of(context).unfocus();
//                               isSubmitted = true;
//                               bool? nameValidate = _nameKey.currentState?.validate();
//                               bool? dateValidate = _dobKey.currentState?.validate();
//                               bool? preParingValidate = _prepParingKey.currentState?.validate();
//                               bool? emailValidate = _emailKey.currentState?.validate();
//                               bool? mobileValidate = _mobileKey.currentState?.validate();
//                               if(nameValidate! && dateValidate! && preParingValidate! && emailValidate! && mobileValidate!){
//                                 _registerWithPhone(store,loginStore,nameController.text,
//                                     dateController.text,selectedValue,selectedCheckboxValues,
//                                     currentStatus??"",phoneController.text, emailController.text);
//                               }
//                             },
//                             buttonText: "Next",
//                             height: Dimensions.PADDING_SIZE_EXTRA_LARGE * 2,
//                             bgColor: Theme.of(context).primaryColor,
//                             radius: Dimensions.RADIUS_SMALL,
//                             transparent: true,
//                             fontSize: Dimensions.fontSizeDefault,
//                             child: store.isLoading ? CircularProgressIndicator(
//                               color: Colors.white,) : null,
//                           );
//                         }
//                     ),
//                     // const SizedBox(
//                     //   height: Dimensions.PADDING_SIZE_LARGE,
//                     // ),
//                     // // Divider
//                     // Row(
//                     //   children: <Widget>[
//                     //     Expanded(
//                     //       child: Container(
//                     //         margin: const EdgeInsets.only(right: 20.0),
//                     //         child: Divider(
//                     //           color: Theme.of(context).disabledColor,
//                     //           height: 25,
//                     //           thickness: 1,
//                     //         ),
//                     //       ),
//                     //     ),
//                     //     const Text("OR"),
//                     //     Expanded(
//                     //       child: Container(
//                     //         margin: const EdgeInsets.only(left: 20.0),
//                     //         child: Divider(
//                     //           color: Theme.of(context).disabledColor,
//                     //           height: 25,
//                     //           thickness: 1,
//                     //         ),
//                     //       ),
//                     //     ),
//                     //   ],
//                     // ),
//                     // const SizedBox(
//                     //   height: Dimensions.PADDING_SIZE_LARGE,
//                     // ),
//                     // SizedBox(
//                     //   width: MediaQuery.of(context).size.height,
//                     //   height: Dimensions.PADDING_SIZE_EXTRA_LARGE * 2,
//                     //   child: ElevatedButton(
//                     //     onPressed: () {
//                     //       FocusScope.of(context).unfocus();
//                     //       Navigator.of(context).pushNamed(Routes.registerWithPass);
//                     //       // signupWithGoogle(context);
//                     //     },
//                     //     style: ElevatedButton.styleFrom(
//                     //       backgroundColor: ThemeManager.white,
//                     //       elevation: 0,
//                     //       side: BorderSide(
//                     //         color: Theme.of(context).disabledColor,
//                     //       ),
//                     //     ),
//                     //     child: Row(
//                     //       mainAxisAlignment: MainAxisAlignment.center,
//                     //       children: [
//                     //         Icon(Icons.password,color: Theme.of(context).primaryColor),
//                     //         const SizedBox(width: Dimensions.PADDING_SIZE_DEFAULT),
//                     //         Text(
//                     //           "Sign up with Password",
//                     //           style: interBold.copyWith(
//                     //             color: ThemeManager.black,
//                     //           ),
//                     //         ),
//                     //       ],
//                     //     ),
//                     //   ),
//                     // ),
//                     const SizedBox(
//                       height: Dimensions.PADDING_SIZE_EXTRA_LARGE,
//                     ),
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Text(
//                           "Don't have an account? ",
//                           style: interRegular.copyWith(
//                               fontSize: Dimensions.fontSizeSmall,
//                               color: Theme.of(context).hintColor
//                           ),
//                         ),
//                         InkWell(
//                           onTap: () {
//                             Navigator.of(context).pushNamed(Routes.login);
//                           },
//                           child: Text(
//                             "Login",
//                             style: interRegular.copyWith(
//                               fontSize: Dimensions.fontSizeSmall,
//                               color: Theme.of(context).primaryColor,
//                               decoration: TextDecoration.underline,
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   // Future<void> signupWithGoogle(BuildContext context) async {
//   //   final GoogleSignIn googleSignIn = GoogleSignIn();
//   //   final GoogleSignInAccount? googleSignInAccount = await googleSignIn.signIn();
//   //   if (googleSignInAccount != null) {
//   //     final GoogleSignInAuthentication googleSignInAuthentication =
//   //     await googleSignInAccount.authentication;
//   //     final AuthCredential authCredential = GoogleAuthProvider.credential(
//   //         idToken: googleSignInAuthentication.idToken,
//   //         accessToken: googleSignInAuthentication.accessToken);
//   //
//   //     UserCredential result = await auth.signInWithCredential(authCredential);
//   //     User? user = result.user;
//   //
//   //     if (result != null) {
//   //       Navigator.of(context).pushNamed(Routes.googleSignUpForm,
//   //           arguments: {"username":user?.displayName,"email":user?.email},);
//   //     }
//   //   }
//   // }
//
//   // String _dataResponse = 'Unknown';
//   // final _otplessFlutterPlugin = Otpless();
//
//   Future<void> _registerWithPhone(SignupStore store, LoginStore loginStore, String fullName, String dateOfBirth, String preparingValue ,List<String> preparingFor,
//       String currentStatus, String phoneNumber, String email)async {
//
//     await store.onRegisterWithPhoneApiCall(fullName, dateOfBirth, preparingValue ,preparingFor,
//         currentStatus, phoneNumber, email);
//
//     String errorMessage = store.errorMessage;
//     // await  _otplessFlutterPlugin.start((result) async {
//     //   var message = "";
//     //   if (result['data'] != null) {
//     //     final token = result['data']['token'];
//     //     message = "token: $token";
//     //   }
//     //   setState(() {
//     //     _dataResponse = message ?? "Unknown";
//     //   });
//     //   await store.onRegisterWithPhoneApiCall(fullName, dateOfBirth, preparingValue ,preparingFor,
//     //       currentStatus, phoneNumber, email);
//     //
//     //   String errorMessage = store.errorMessage;
//     //
//     //   if (store.signupWithPhone.value?.created==null) {
//     //     BottomToast.showBottomToastOverlay(
//     //       context: context,
//     //       errorMessage: errorMessage,
//     //       backgroundColor: Theme.of(context).colorScheme.error,
//     //     );
//     //   }else if(store.signupWithPhone.value?.created==false){
//     //     if(store.signupWithPhone.value?.data?.token!=null){
//     //       SharedPreferences prefs = await SharedPreferences.getInstance();
//     //       prefs.setString('token', store.signupWithPhone.value?.data?.token??"");
//     //       prefs.setBool('isloggedInEmail', true);
//     //       BottomToast.showBottomToastOverlay(
//     //         context: context,
//     //         errorMessage: "User Registered Successfully",
//     //         backgroundColor: Theme.of(context).primaryColor,
//     //       );
//     //       Navigator.of(context).pushNamed(Routes.home);
//     //     }else{
//     //       BottomToast.showBottomToastOverlay(
//     //         context: context,
//     //         errorMessage: errorMessage,
//     //         backgroundColor: Theme.of(context).colorScheme.error,
//     //       );
//     //     }
//     //   }
//     // });
//
//     if (store.signupWithPhone.value?.created==null) {
//       BottomToast.showBottomToastOverlay(
//         context: context,
//         errorMessage: errorMessage,
//         backgroundColor: Theme.of(context).colorScheme.error,
//       );
//     }else if(store.signupWithPhone.value?.created==true){
//       BottomToast.showBottomToastOverlay(
//         context: context,
//         errorMessage: "OTP Sent Successfully!",
//         backgroundColor: Theme.of(context).primaryColor,
//       );
//       Navigator.of(context).pushNamed(Routes.verifyOtp,
//       arguments: {'phone': phoneNumber});
//     }
//   }
//
//   Future<void> _selectDate(BuildContext context) async {
//     final DateTime? picked = await showDatePicker(
//       context: context,
//       initialDate: DateTime.now(),
//       firstDate: DateTime(1900),
//       lastDate: DateTime.now(),
//       builder: (context, child) {
//         return Theme(
//           data: Theme.of(context).copyWith(
//             colorScheme: ColorScheme.light(
//               primary: Theme.of(context).primaryColor,
//               onPrimary: Colors.white,
//               onSurface: Colors.blue,
//             ),
//             textButtonTheme: TextButtonThemeData(
//               style: TextButton.styleFrom(
//                 primary:ThemeManager.currentTheme == AppTheme.Dark ? ThemeManager.white : Theme.of(context).primaryColor,
//               ),
//             ),
//           ),
//           child: child!,
//         );
//       },
//     );
//
//     if (picked != null && picked != selectedDate) {
//       setState(() {
//         selectedDate = picked;
//         final formattedDate = DateFormat('dd - MMMM - yyyy').format(picked);
//         dateController.text = formattedDate;
//       });
//     }
//   }
// }
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shusruta_lms/modules/signup/store/signup_store.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../app/routes.dart';
import '../../helpers/colors.dart';
import '../../helpers/dimensions.dart';
import '../../helpers/styles.dart';
import '../../helpers/app_tokens.dart';
import '../../models/registerationData.dart';
import '../login/store/login_store.dart';
import '../widgets/bottom_toast.dart';
import '../widgets/custom_button.dart';
// Custom keyboard import - commented out as we're using system default keyboard
// Uncomment this if you want to re-enable the custom keyboard
// import '../login/keyboard.dart';

class SignUpWithPhoneScreen extends StatefulWidget {
  const SignUpWithPhoneScreen({super.key});

  @override
  State<SignUpWithPhoneScreen> createState() => _SignUpWithPhoneScreenState();
  static Route<dynamic> route(RouteSettings routeSettings) {
    return CupertinoPageRoute(
      builder: (_) => const SignUpWithPhoneScreen(),
    );
  }
}

class _SignUpWithPhoneScreenState extends State<SignUpWithPhoneScreen>
    with WidgetsBindingObserver {
  bool isSignIn = false;
  bool google = false;
  String? _fcmToken;
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  bool isKeyboardOpen = false;
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
  bool _isPreparingValid = false;
  bool _isStateValid = false;
  bool isSubmitted = false;
  bool isUserCheck = false;
  List<String> preparingForList = [];
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

  bool isCheckboxCheckedUserAgreement() {
    return isUserCheck;
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
    WidgetsBinding.instance.addObserver(this);

    _getPreparingExamsData();
  }

  Future<void> _getPreparingExamsData() async {
    final store = Provider.of<SignupStore>(context, listen: false);
    await store.onGetPreparingExams();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    final bottomInset = WidgetsBinding.instance.window.viewInsets.bottom ?? 0;
    setState(() {
      isKeyboardOpen = bottomInset > 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = Provider.of<SignupStore>(context, listen: false);
    final loginStore = Provider.of<LoginStore>(context, listen: false);

    List<DropdownMenuItem<String>> dropdownItems =
        store.preparingexams.map((item) {
      final preparingFor = item?.preparingFor;
      return DropdownMenuItem<String>(
        value: preparingFor,
        child: Text(preparingFor!),
      );
    }).toList();

    List<DropdownMenuItem<String>> stateDropdownItems =
        indianStates.map((item) {
      final state = item;
      return DropdownMenuItem<String>(
        value: state,
        child: Text(state),
      );
    }).toList();

    return Scaffold(
      backgroundColor: ThemeManager.white,
      body: Center(
        child: Container(
          constraints: BoxConstraints(
              maxWidth: 600, maxHeight: MediaQuery.of(context).size.height * 1),
          child: SingleChildScrollView(
            child: SizedBox(
              // height: MediaQuery.of(context).size.height,
              child: Padding(
                padding: EdgeInsets.only(
                  left: Dimensions.PADDING_SIZE_LARGE * 1.15,
                  top: Dimensions.PADDING_SIZE_EXTRA_LARGE * 2.5,
                  right: Dimensions.PADDING_SIZE_LARGE * 1.1,
                  bottom: isKeyboardOpen
                      ? MediaQuery.of(context).viewInsets.bottom
                      : Dimensions.PADDING_SIZE_LARGE * 2,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Create your account",
                          style: AppTokens.displayMd(context),
                        ),
                        const SizedBox(height: AppTokens.s8),
                        RichText(
                          text: TextSpan(
                            style: AppTokens.bodyLg(context).copyWith(
                              color: AppTokens.muted(context),
                              height: 1.45,
                            ),
                            children: [
                              const TextSpan(text: "Welcome to "),
                              TextSpan(
                                text: "Sushruta LGS",
                                style: TextStyle(
                                  color: AppTokens.accent(context),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const TextSpan(text: ' — let\'s set up your prep.'),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: Dimensions.PADDING_SIZE_LARGE,
                    ),
                    Container(
                      constraints: const BoxConstraints(
                        minHeight: Dimensions.PADDING_SIZE_EXTRA_LARGE * 2,
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
                        // Custom keyboard code - commented out to use system default keyboard
                        // To re-enable custom keyboard, also uncomment the import '../login/keyboard.dart' above
                        // readOnly: true,
                        // enableInteractiveSelection: false,
                        // onTap: () {
                        //   FocusScope.of(context).unfocus();
                        //   showCustomKeyboardSheet(context, KeyboardType.email, nameController);
                        // },
                        keyboardType: TextInputType.name,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.only(
                              left: Dimensions.PADDING_SIZE_SMALL * 1.2),
                          fillColor: Theme.of(context).disabledColor,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              3.4,
                            ),
                            borderSide: BorderSide(
                              color: ThemeManager.grey1,
                            ),
                          ),
                          hintText: 'Full Name',
                          hintStyle: interRegular.copyWith(
                            fontSize: Dimensions.fontSizeSmall,
                            color: ThemeManager.textColor4.withOpacity(0.5),
                          ),
                          counterText: '',
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              3.4,
                            ),
                            borderSide: BorderSide(
                              color: ThemeManager.grey1,
                            ),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              3.4,
                            ),
                            borderSide: BorderSide(
                              color: ThemeManager.grey1,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: Dimensions.PADDING_SIZE_DEFAULT,
                    ),
                    Container(
                      constraints: const BoxConstraints(
                        minHeight: Dimensions.PADDING_SIZE_EXTRA_LARGE * 2,
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
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.only(
                              left: Dimensions.PADDING_SIZE_SMALL * 1.2),
                          suffixIcon: Padding(
                            padding: const EdgeInsets.only(
                                right: Dimensions.PADDING_SIZE_DEFAULT),
                            child:
                                SvgPicture.asset("assets/image/date_Icon.svg"),
                          ),
                          suffixIconConstraints: const BoxConstraints(
                              minHeight: Dimensions.PADDING_SIZE_DEFAULT * 1.1,
                              minWidth: Dimensions.PADDING_SIZE_DEFAULT),
                          fillColor: Theme.of(context).disabledColor,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              3.4,
                            ),
                            borderSide: BorderSide(
                              color: ThemeManager.grey1,
                            ),
                          ),
                          hintText: 'Date of birth',
                          hintStyle: interRegular.copyWith(
                            fontSize: Dimensions.fontSizeSmall,
                            color: ThemeManager.textColor4.withOpacity(0.5),
                          ),
                          counterText: '',
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              3.4,
                            ),
                            borderSide: BorderSide(
                              color: ThemeManager.grey1,
                            ),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              3.4,
                            ),
                            borderSide: BorderSide(
                              color: ThemeManager.grey1,
                            ),
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
                      value: stateValue.isNotEmpty ? stateValue : null,
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
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.transparent,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            3.4,
                          ),
                          borderSide: BorderSide(
                            color: ThemeManager.grey1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            3.4,
                          ),
                          borderSide: BorderSide(
                            color: ThemeManager.grey1,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.red),
                        ),
                        hintText: "Select State",
                        hintStyle: interRegular.copyWith(
                          fontSize: Dimensions.fontSizeSmall,
                          color: ThemeManager.textColor4,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
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
                    // Preparing for dropdown and checkboxes removed - moved to new screen
                    // selectedValue=="Surgical"?
                    // Row(
                    //     mainAxisSize: MainAxisSize.min,
                    //     children: [
                    //       Checkbox(
                    //         materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    //         visualDensity: VisualDensity.compact,
                    //         value: selectedCheckboxValues.contains('NEET SS'),
                    //         onChanged: (value){
                    //           setState(() {
                    //             isChecked = value!;
                    //             if (isChecked) {
                    //               selectedCheckboxValues.add('NEET SS');
                    //             } else {
                    //               selectedCheckboxValues.remove('NEET SS');
                    //             }
                    //           });
                    //         },
                    //         activeColor: Theme.of(context).primaryColor,
                    //         side: BorderSide(
                    //           color: Theme.of(context).disabledColor,
                    //         ),
                    //       ),
                    //       Text('NEET SS',
                    //         style: interRegular.copyWith(
                    //             fontSize: Dimensions.fontSizeSmall,
                    //             color: ThemeManager.black,
                    //             fontWeight: FontWeight.w400
                    //         ),),
                    //
                    //       Checkbox(
                    //         materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    //         visualDensity: VisualDensity.compact,
                    //         value: selectedCheckboxValues.contains('INI SS'),
                    //         onChanged: (value){
                    //           setState(() {
                    //             isChecked = value!;
                    //             if (isChecked) {
                    //               selectedCheckboxValues.add('INI SS');
                    //             } else {
                    //               selectedCheckboxValues.remove('INI SS');
                    //             }
                    //           });
                    //         },
                    //         activeColor: Theme.of(context).primaryColor,
                    //         side: BorderSide(
                    //           color: Theme.of(context).disabledColor,
                    //         ),
                    //       ),
                    //       Text('INI SS',
                    //         style: interRegular.copyWith(
                    //             fontSize: Dimensions.fontSizeSmall,
                    //             color: ThemeManager.black,
                    //             fontWeight: FontWeight.w400
                    //         ),),
                    //
                    //       Checkbox(
                    //         materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    //         visualDensity: VisualDensity.compact,
                    //         value: selectedCheckboxValues.contains('MR CS'),
                    //         onChanged: (value){
                    //           setState(() {
                    //             isChecked = value!;
                    //             if (isChecked) {
                    //               selectedCheckboxValues.add('MR CS');
                    //             } else {
                    //               selectedCheckboxValues.remove('MR CS');
                    //             }
                    //           });
                    //         },
                    //         activeColor: Theme.of(context).primaryColor,
                    //         side: BorderSide(
                    //           color: Theme.of(context).disabledColor,
                    //         ),
                    //       ),
                    //       Text('MR CS',
                    //         style: interRegular.copyWith(
                    //             fontSize: Dimensions.fontSizeSmall,
                    //             color: ThemeManager.black,
                    //             fontWeight: FontWeight.w400
                    //         ),),
                    //     ]
                    // ):
                    // selectedValue == "Medical"
                    //     ? Row(
                    //   mainAxisSize: MainAxisSize.min,
                    //   children: [
                    //     Checkbox(
                    //       materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    //       visualDensity: VisualDensity.compact,
                    //       value: selectedCheckboxValues.contains('NEET SS'),
                    //       onChanged: (value) {
                    //         setState(() {
                    //           isChecked = value!;
                    //           if (isChecked) {
                    //             selectedCheckboxValues.add('NEET SS');
                    //           } else {
                    //             selectedCheckboxValues.remove('NEET SS');
                    //           }
                    //         });
                    //       },
                    //       activeColor: Theme.of(context).primaryColor,
                    //       side: BorderSide(
                    //         color: Theme.of(context).disabledColor,
                    //       ),
                    //     ),
                    //     Text(
                    //       'NEET SS',
                    //       style: interRegular.copyWith(
                    //         fontSize: Dimensions.fontSizeSmall,
                    //         color: ThemeManager.black,
                    //         fontWeight: FontWeight.w400,
                    //       ),
                    //     ),
                    //
                    //     Checkbox(
                    //       materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    //       visualDensity: VisualDensity.compact,
                    //       value: selectedCheckboxValues.contains('INI SS'),
                    //       onChanged: (value) {
                    //         setState(() {
                    //           isChecked = value!;
                    //           if (isChecked) {
                    //             selectedCheckboxValues.add('INI SS');
                    //           } else {
                    //             selectedCheckboxValues.remove('INI SS');
                    //           }
                    //         });
                    //       },
                    //       activeColor: Theme.of(context).primaryColor,
                    //       side: BorderSide(
                    //         color: Theme.of(context).disabledColor,
                    //       ),
                    //     ),
                    //     Text(
                    //       'INI SS',
                    //       style: interRegular.copyWith(
                    //         fontSize: Dimensions.fontSizeSmall,
                    //         color: ThemeManager.black,
                    //         fontWeight: FontWeight.w400,
                    //       ),
                    //     ),
                    //   ],
                    // ) : const SizedBox(),

                    const SizedBox(
                      height: Dimensions.PADDING_SIZE_DEFAULT * 1.1,
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
                        Row(mainAxisSize: MainAxisSize.min, children: [
                          Checkbox(
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                            value: currentStatus == "PG Resident",
                            onChanged: (value) {
                              setState(() {
                                isChecked = value!;
                                if (isChecked) {
                                  currentStatus = "PG Resident";
                                } else {
                                  currentStatus = null;
                                }
                              });
                            },
                            activeColor: ThemeManager.primaryColor,
                            side: BorderSide(
                              color: ThemeManager.grey1,
                            ),
                          ),
                          Text(
                            'PG Resident',
                            style: interRegular.copyWith(
                                fontSize: Dimensions.fontSizeSmall,
                                color: ThemeManager.black,
                                fontWeight: FontWeight.w500),
                          ),
                        ]),
                        const SizedBox(
                            width: Dimensions.PADDING_SIZE_LARGE * 1.7),
                        Row(mainAxisSize: MainAxisSize.min, children: [
                          Checkbox(
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                            value: currentStatus == "Post-Graduate",
                            onChanged: (value) {
                              setState(() {
                                isChecked = value!;
                                if (isChecked) {
                                  currentStatus = "Post-Graduate";
                                } else {
                                  currentStatus = null;
                                }
                              });
                            },
                            activeColor: ThemeManager.primaryColor,
                            side: BorderSide(
                              color: ThemeManager.grey1,
                            ),
                          ),
                          Text(
                            'Post-Graduate',
                            style: interRegular.copyWith(
                                fontSize: Dimensions.fontSizeSmall,
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
                            color: Theme.of(context).colorScheme.error),
                      ),
                    const SizedBox(
                      height: Dimensions.PADDING_SIZE_DEFAULT,
                    ),
                    Container(
                      constraints: const BoxConstraints(
                        minHeight: Dimensions.PADDING_SIZE_EXTRA_LARGE * 2,
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
                        // Custom keyboard code - commented out to use system default keyboard
                        // To re-enable custom keyboard, also uncomment the import '../login/keyboard.dart' above
                        // readOnly: true,
                        // enableInteractiveSelection: false,
                        // onTap: () {
                        //   FocusScope.of(context).unfocus();
                        //   showCustomKeyboardSheet(context, KeyboardType.number, phoneController);
                        // },
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          contentPadding: EdgeInsets.zero,
                          prefixIcon: IntrinsicHeight(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(
                                      left: Dimensions.PADDING_SIZE_SMALL * 1.2,
                                      right: Dimensions.PADDING_SIZE_SMALL),
                                  child: Text(
                                    "+91",
                                    style: interMedium.copyWith(
                                        fontSize: Dimensions.fontSizeSmall,
                                        color: ThemeManager.black),
                                  ),
                                ),
                                VerticalDivider(color: ThemeManager.grey1)
                              ],
                            ),
                          ),
                          fillColor: Theme.of(context).disabledColor,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              3.4,
                            ),
                            borderSide: BorderSide(
                              color: ThemeManager.grey1,
                            ),
                          ),
                          hintText: 'Mobile Number',
                          hintStyle: interRegular.copyWith(
                            fontSize: Dimensions.fontSizeSmall,
                            color: ThemeManager.textColor4.withOpacity(0.5),
                          ),
                          counterText: '',
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              3.4,
                            ),
                            borderSide: BorderSide(
                              color: ThemeManager.grey1,
                            ),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              3.4,
                            ),
                            borderSide: BorderSide(
                              color: ThemeManager.grey1,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: Dimensions.PADDING_SIZE_DEFAULT,
                    ),
                    Container(
                      constraints: const BoxConstraints(
                        minHeight: Dimensions.PADDING_SIZE_EXTRA_LARGE * 2,
                      ),
                      child: TextFormField(
                        key: _emailKey,
                        onChanged: (value) {
                          setState(() {
                            _isEmailValid = _emailRegex.hasMatch(value);
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            setState(() {
                              _isEmailValid = false;
                            });
                            return 'Please enter an email address.';
                          } else if (!_emailRegex.hasMatch(value)) {
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
                        // Custom keyboard code - commented out to use system default keyboard
                        // To re-enable custom keyboard, also uncomment the import '../login/keyboard.dart' above
                        // readOnly: true,
                        // enableInteractiveSelection: false,
                        // onTap: () {
                        //   FocusScope.of(context).unfocus();
                        //   showCustomKeyboardSheet(context, KeyboardType.email, emailController);
                        // },
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.only(
                              left: Dimensions.PADDING_SIZE_SMALL * 1.2),
                          fillColor: Theme.of(context).disabledColor,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              3.4,
                            ),
                            borderSide: BorderSide(
                              color: ThemeManager.grey1,
                            ),
                          ),
                          hintText: 'Enter Email',
                          hintStyle: interRegular.copyWith(
                            fontSize: Dimensions.fontSizeSmall,
                            color: ThemeManager.textColor4.withOpacity(0.5),
                          ),
                          counterText: '',
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              3.4,
                            ),
                            borderSide: BorderSide(
                              color: ThemeManager.grey1,
                            ),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              3.4,
                            ),
                            borderSide: BorderSide(
                              color: ThemeManager.grey1,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: Dimensions.PADDING_SIZE_DEFAULT * 1.2,
                    ),
                    // Container(
                    //   constraints: const BoxConstraints(
                    //     minHeight: Dimensions.PADDING_SIZE_EXTRA_LARGE * 2,
                    //   ),
                    //   child: TextFormField(
                    //     key: _passKey,
                    //     obscureText: true,
                    //     cursorColor: Theme.of(context).disabledColor,
                    //     style: interRegular.copyWith(
                    //       fontSize: Dimensions.fontSizeDefault,
                    //     ),
                    //     controller: passwordController,
                    //     validator: (value) {
                    //       if (value == null || value.isEmpty) {
                    //         setState(() {
                    //           _isPasswordValid = false;
                    //         });
                    //         return 'Please enter an password.';
                    //       }else if (value.length < 6) {
                    //         return 'Password must be at least 6 characters long';
                    //       }
                    //       setState(() {
                    //         _isPasswordValid = true;
                    //       });
                    //       return null;
                    //     },
                    //     keyboardType: TextInputType.visiblePassword,
                    //     decoration: InputDecoration(
                    //       fillColor: Theme.of(context).disabledColor,
                    //       enabledBorder: OutlineInputBorder(
                    //         borderRadius: BorderRadius.circular(
                    //           Dimensions.RADIUS_SMALL,
                    //         ),
                    //         borderSide: BorderSide(
                    //           color: Theme.of(context).disabledColor,
                    //         ),
                    //       ),
                    //       labelText: 'Create Password',
                    //       hintText: 'Create Password',
                    //       hintStyle: interRegular.copyWith(
                    //         fontSize: Dimensions.fontSizeSmall,
                    //         color: ThemeManager.black,
                    //       ),
                    //       labelStyle: interRegular.copyWith(
                    //         fontSize: Dimensions.fontSizeSmall,
                    //         color: ThemeManager.black,
                    //       ),
                    //       counterText: '',
                    //       focusedBorder: OutlineInputBorder(
                    //         borderRadius: BorderRadius.circular(
                    //           Dimensions.RADIUS_SMALL,
                    //         ),
                    //         borderSide: BorderSide(
                    //           color: Theme.of(context).disabledColor,
                    //         ),
                    //       ),
                    //       border: OutlineInputBorder(
                    //         borderRadius: BorderRadius.circular(
                    //           Dimensions.RADIUS_SMALL,
                    //         ),
                    //         borderSide: BorderSide(
                    //           color: Theme.of(context).disabledColor,
                    //         ),
                    //       ),
                    //     ),
                    //   ),
                    // ),
                    // const SizedBox(
                    //   height: Dimensions.PADDING_SIZE_DEFAULT,
                    // ),
                    // Container(
                    //   constraints: const BoxConstraints(
                    //     minHeight: Dimensions.PADDING_SIZE_EXTRA_LARGE * 2,
                    //   ),
                    //   child: TextFormField(
                    //     key: _repassKey,
                    //     obscureText: true,
                    //     cursorColor: Theme.of(context).disabledColor,
                    //     style: interRegular.copyWith(
                    //       fontSize: Dimensions.fontSizeDefault,
                    //     ),
                    //     controller: confirmPassController,
                    //     validator: (value) {
                    //       if (value == null || value.isEmpty) {
                    //         setState(() {
                    //           _isPasswordValid = false;
                    //         });
                    //         return 'Please enter an confirm password.';
                    //       }else if (value.length < 6) {
                    //         return 'Password must be at least 6 characters long';
                    //       }
                    //       setState(() {
                    //         _isPasswordValid = true;
                    //       });
                    //       return null;
                    //     },
                    //     keyboardType: TextInputType.visiblePassword,
                    //     decoration: InputDecoration(
                    //       fillColor: Theme.of(context).disabledColor,
                    //       enabledBorder: OutlineInputBorder(
                    //         borderRadius: BorderRadius.circular(
                    //           Dimensions.RADIUS_SMALL,
                    //         ),
                    //         borderSide: BorderSide(
                    //           color: Theme.of(context).disabledColor,
                    //         ),
                    //       ),
                    //       labelText: 'Re-enter Password',
                    //       hintText: 'Re-enter Password',
                    //       hintStyle: interRegular.copyWith(
                    //         fontSize: Dimensions.fontSizeSmall,
                    //         color: ThemeManager.black,
                    //       ),
                    //       labelStyle: interRegular.copyWith(
                    //         fontSize: Dimensions.fontSizeSmall,
                    //         color: ThemeManager.black,
                    //       ),
                    //       counterText: '',
                    //       focusedBorder: OutlineInputBorder(
                    //         borderRadius: BorderRadius.circular(
                    //           Dimensions.RADIUS_SMALL,
                    //         ),
                    //         borderSide: BorderSide(
                    //           color: Theme.of(context).disabledColor,
                    //         ),
                    //       ),
                    //       border: OutlineInputBorder(
                    //         borderRadius: BorderRadius.circular(
                    //           Dimensions.RADIUS_SMALL,
                    //         ),
                    //         borderSide: BorderSide(
                    //           color: Theme.of(context).disabledColor,
                    //         ),
                    //       ),
                    //     ),
                    //   ),
                    // ),
                    // const SizedBox(
                    //   height: Dimensions.PADDING_SIZE_DEFAULT,
                    // ),
                    Row(
                      children: [
                        Checkbox(
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                          value: isUserCheck,
                          onChanged: (value) {
                            setState(() {
                              isUserCheck = value!;
                            });
                          },
                          activeColor: ThemeManager.primaryColor,
                          side: BorderSide(
                            color: ThemeManager.grey1,
                          ),
                        ),
                        // RichText(
                        //   textAlign: TextAlign.center,
                        //   text: TextSpan(
                        //     style: TextStyle(fontSize: 16.0, color: Colors.black),
                        //     children: [
                        //       TextSpan(
                        //         text: 'By clicking "I agree", you certify that you are 18 years of age or older and agree to the ',
                        //       ),
                        //       TextSpan(
                        //         text: 'User Agreement',
                        //         style: TextStyle(
                        //           decoration: TextDecoration.underline,
                        //           color: Colors.blue,
                        //         ),
                        //         recognizer: TapGestureRecognizer()
                        //           ..onTap = () {
                        //             // Handle tap on User Agreement
                        //             print('User Agreement tapped');
                        //           },
                        //       ),
                        //       TextSpan(
                        //         text: ' and ',
                        //       ),
                        //       TextSpan(
                        //         text: 'Privacy Policy',
                        //         style: TextStyle(
                        //           decoration: TextDecoration.underline,
                        //           color: Colors.blue,
                        //         ),
                        //         recognizer: TapGestureRecognizer()
                        //           ..onTap = () {
                        //             // Handle tap on Privacy Policy
                        //             print('Privacy Policy tapped');
                        //           },
                        //       ),
                        //     ],
                        //   ),
                        // ),
                        Expanded(
                          child: Text.rich(
                            TextSpan(
                              text:
                                  'I certify that I am 18 years of age or older, and I agree to the ',
                              children: [
                                TextSpan(
                                  text: 'User Agreement',
                                  style: interRegular.copyWith(
                                      // fontSize: Dimensions.fontSizeSmall,
                                      color: ThemeManager.primaryColor),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () {
                                      _launchURL(
                                          "https://sushrutalgs.in/terms-%26-conditions");
                                    },
                                ),
                                const TextSpan(text: ' and '),
                                TextSpan(
                                  text: 'Privacy Policy',
                                  style: interRegular.copyWith(
                                      color: ThemeManager.primaryColor),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () {
                                      _launchURL(
                                          "https://sushrutalgs.in/privacy-policy");
                                    },
                                ),
                              ],
                              style: interRegular.copyWith(
                                  fontSize: Dimensions.fontSizeDefault,
                                  color: ThemeManager.black),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (isSubmitted && !isCheckboxCheckedUserAgreement())
                      Text(
                        'Please select user agreement.',
                        style: interRegular.copyWith(
                            fontSize: Dimensions.fontSizeSmall,
                            color: Theme.of(context).colorScheme.error),
                      ),
                    const SizedBox(
                      height: Dimensions.PADDING_SIZE_DEFAULT * 1.2,
                    ),
                    Column(
                      children: [
                        Observer(builder: (_) {
                          return CustomButton(
                            onPressed: () {
                              FocusScope.of(context).unfocus();
                              isSubmitted = true;
                              bool? nameValidate =
                                  _nameKey.currentState?.validate();
                              bool? dateValidate =
                                  _dobKey.currentState?.validate();
                              // bool? preParingValidate =
                              //     _prepParingKey.currentState?.validate();
                              bool? stateValidate =
                                  _stateKey.currentState?.validate();
                              bool? emailValidate =
                                  _emailKey.currentState?.validate();
                              bool? mobileValidate =
                                  _mobileKey.currentState?.validate();
                              // bool? passwordValidate = _passKey.currentState?.validate();
                              // bool? rePasswordValidate = _repassKey.currentState?.validate();
                              debugPrint("isCheck:$isUserCheck");
                              if (nameValidate! &&
                                  dateValidate! &&
                                  stateValidate! &&
                                  emailValidate! &&
                                  mobileValidate! &&
                                  isUserCheck) {
                                // Create registration data
                                RegistrationData registrationData = RegistrationData(
                                  fullName: nameController.text,
                                  dateOfBirth: dateController.text,
                                  preparingValue: '', // Will be set in the new screen
                                  stateValue: stateValue,
                                  preparingFor: [], // Will be set in the new screen
                                  currentStatus: currentStatus ?? "",
                                  phoneNumber: phoneController.text,
                                  email: emailController.text,
                                );
                                
                                // Navigate to the new preparing for screen
                                Navigator.of(context).pushNamed(
                                  Routes.preparingForScreen,
                                  arguments: {'registrationData': registrationData},
                                );
                              }
                            },
                            buttonText: "Continue",
                            height: 54,
                            bgColor: isUserCheck
                                ? AppTokens.accent(context)
                                : AppTokens.accent(context).withOpacity(0.4),
                            radius: 16,
                            transparent: true,
                            fontSize: 16,
                            child: store.isLoading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white,
                                    ),
                                  )
                                : null,
                          );
                        }),
                        const SizedBox(
                          height: Dimensions.PADDING_SIZE_DEFAULT * 1.2,
                        ),
                        // Divider
                        // Row(
                        //   children: <Widget>[
                        //     Expanded(
                        //       child: Container(
                        //         margin: const EdgeInsets.only(right: 20.0),
                        //         child: Divider(
                        //           color: Theme.of(context).disabledColor,
                        //           height: 25,
                        //           thickness: 1,
                        //         ),
                        //       ),
                        //     ),
                        //     const Text("OR"),
                        //     Expanded(
                        //       child: Container(
                        //         margin: const EdgeInsets.only(left: 20.0),
                        //         child: Divider(
                        //           color: Theme.of(context).disabledColor,
                        //           height: 25,
                        //           thickness: 1,
                        //         ),
                        //       ),
                        //     ),
                        //   ],
                        // ),
                        // const SizedBox(
                        //   height: Dimensions.PADDING_SIZE_LARGE,
                        // ),
                        // SizedBox(
                        //   width: MediaQuery.of(context).size.height,
                        //   height: Dimensions.PADDING_SIZE_EXTRA_LARGE * 2,
                        //   child: ElevatedButton(
                        //     onPressed: () {
                        //       FocusScope.of(context).unfocus();
                        //       Navigator.of(context).pushNamed(Routes.register);
                        //       // signupWithGoogle(context);
                        //     },
                        //     style: ElevatedButton.styleFrom(
                        //       backgroundColor: ThemeManager.white,
                        //       elevation: 0,
                        //       side: BorderSide(
                        //         color: Theme.of(context).disabledColor,
                        //       ),
                        //     ),
                        //     child: Row(
                        //       mainAxisAlignment: MainAxisAlignment.center,
                        //       children: [
                        //         Icon(Icons.password,color: Theme.of(context).primaryColor),
                        //         const SizedBox(width: Dimensions.PADDING_SIZE_DEFAULT),
                        //         Text(
                        //           "Sign up with OTP",
                        //           style: interBold.copyWith(
                        //             color: ThemeManager.black,
                        //           ),
                        //         ),
                        //       ],
                        //     ),
                        //   ),
                        // ),
                        // const SizedBox(
                        //   height: Dimensions.PADDING_SIZE_EXTRA_LARGE,
                        // ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Already have An Account? ",
                              style: interRegular.copyWith(
                                  fontSize: Dimensions.fontSizeDefault,
                                  color: ThemeManager.black),
                            ),
                            InkWell(
                              onTap: () {
                                Navigator.of(context).pushNamed(Routes.login);
                              },
                              child: Text(
                                "Login",
                                style: interBold.copyWith(
                                  fontSize: Dimensions.fontSizeDefault,
                                  color: ThemeManager.textColor2,
                                  decoration: TextDecoration.underline,
                                  decorationColor: ThemeManager.textColor2,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  // Future<void> signupWithGoogle(BuildContext context) async {
  //   final GoogleSignIn googleSignIn = GoogleSignIn();
  //   final GoogleSignInAccount? googleSignInAccount = await googleSignIn.signIn();
  //   if (googleSignInAccount != null) {
  //     final GoogleSignInAuthentication googleSignInAuthentication =
  //     await googleSignInAccount.authentication;
  //     final AuthCredential authCredential = GoogleAuthProvider.credential(
  //         idToken: googleSignInAuthentication.idToken,
  //         accessToken: googleSignInAuthentication.accessToken);
  //
  //     UserCredential result = await auth.signInWithCredential(authCredential);
  //     User? user = result.user;
  //
  //     if (result != null) {
  //       Navigator.of(context).pushNamed(Routes.googleSignUpForm,
  //           arguments: {"username":user?.displayName,"email":user?.email},);
  //     }
  //   }
  // }

  Future<Map<String, String>> getDeviceInfo() async {
    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    String deviceId = '';
    String deviceName = '';
    String platform = '';

    if (Platform.isAndroid) {
      // Android specific device information
      final androidInfo = await deviceInfo.androidInfo;
      deviceId = androidInfo.id;
      deviceName = androidInfo.model ?? 'Unknown';
      platform = 'Android';
    } else if (Platform.isIOS) {
      // iOS specific device information
      final iosInfo = await deviceInfo.iosInfo;
      deviceId = iosInfo.identifierForVendor ?? 'Unknown';
      deviceName = iosInfo.name ?? 'Unknown';
      platform = 'iOS';
    } else if (Platform.isMacOS) {
      // macOS specific device information
      final macInfo = await deviceInfo.macOsInfo;
      deviceId = macInfo.systemGUID ?? 'Unknown';
      deviceName = macInfo.model ?? 'Unknown';
      platform = 'macOS';
    } else if (Platform.isWindows) {
      // Windows specific device information
      final windowsInfo = await deviceInfo.windowsInfo;
      deviceId = windowsInfo.deviceId ?? 'Unknown';
      deviceName = windowsInfo.computerName ?? 'Unknown';
      platform = 'Windows';
    }
    return {
      'device_id': deviceId,
      'device_name': deviceName,
      'platform': platform,
    };
  }

  Future<void> _register(
      SignupStore store,
      LoginStore loginStore,
      String fullName,
      String dateOfBirth,
      String preparingValue,
      String state,
      List<String> preparingFor,
      String currentStatus,
      String phoneNumber,
      String email) async {
    
    // Check device registration first
    try {
      Map<String, String> deviceInfo = await getDeviceInfo();
      String deviceUniqueId = deviceInfo['device_id'] ?? '';
      
      if (deviceUniqueId.isNotEmpty) {
        Map<String, dynamic>? deviceCheckResult = await store.onCheckDeviceRegistration(deviceUniqueId);
        
        if (deviceCheckResult != null) {
          bool exists = deviceCheckResult['exists'] ?? false;
          bool success = deviceCheckResult['success'] ?? false;
          
          if (success && exists) {
            // Device is already registered, show error
            BottomToast.showBottomToastOverlay(
              context: context,
              errorMessage: "You cannot register from the same device multiple times",
              backgroundColor: Theme.of(context).colorScheme.error,
            );
            return;
          }
        }
      }
    } catch (e) {
      // If device check fails, show error and return
      BottomToast.showBottomToastOverlay(
        context: context,
        errorMessage: "Failed to verify device. Please try again.",
        backgroundColor: Theme.of(context).colorScheme.error,
      );
      return;
    }

    RegistrationData registrationData = RegistrationData(
      fullName: fullName,
      dateOfBirth: dateOfBirth,
      preparingValue: preparingValue,
      stateValue: state,
      preparingFor: preparingFor,
      currentStatus: currentStatus,
      phoneNumber: phoneNumber,
      email: email,
    );

    await store.onSendOtpToPhone(phoneNumber, email).then((value) {
      // Check if there's a restore user error
      if (store.errorMessageOtp2.value?.error == 'ERROR_REGISTER_User') {
        // Show dialog for previously deleted user
        _showRestoreUserDialog(store, registrationData, phoneNumber, email);
      } else if (store.errorMessageOtp2.value?.message != null) {
        // Success case - OTP sent
        BottomToast.showBottomToastOverlay(
          context: context,
          errorMessage: "OTP Sent Successfully! both Email and SMS",
          backgroundColor: Theme.of(context).primaryColor,
        );
        Navigator.of(context).pushNamed(Routes.verifyOtp, arguments: {
          'email': phoneNumber,
          'registrationObj': registrationData,
          'trial': true,
          'email2': email
        });
      } else if (store.errorMessageOtp2.value?.error != null) {
        // Show other errors
        BottomToast.showBottomToastOverlay(
          context: context,
          errorMessage: store.errorMessageOtp2.value?.error ?? 'An error occurred',
          backgroundColor: Theme.of(context).colorScheme.error,
        );
      }
    });

    // await store.onRegisterWithPhoneApiCall(fullName, dateOfBirth, preparingValue ,preparingFor,
    //     currentStatus, phoneNumber, email, password, confirmPass);
    //
    // String errorMessage = store.errorMessage;
    // debugPrint('created${store.signupWithPhone.value?.created}');
    // if (store.signupWithPhone.value?.created==null) {
    //   BottomToast.showBottomToastOverlay(
    //     context: context,
    //     errorMessage: errorMessage,
    //     backgroundColor: Theme.of(context).colorScheme.error,
    //   );
    // }
    // else if(store.signupWithPhone.value?.created==false){
    //   debugPrint('created${store.signupWithPhone.value?.data?.token}');
    //   if(store.signupWithPhone.value?.data?.token!=null){
    //     SharedPreferences prefs = await SharedPreferences.getInstance();
    //     prefs.setString('token', store.signupWithPhone.value?.data?.token??"");
    //     prefs.setBool('isloggedInEmail', true);
    //     String? fcmtoken = await _firebaseMessaging.getToken();
    //     setState(() {
    //       _fcmToken = fcmtoken;
    //     });
    //     prefs.setString('fcmtoken',_fcmToken??"");
    //     debugPrint('fcm $_fcmToken');
    //     await loginStore.onCreateNotificationToken(_fcmToken??"");
    //     BottomToast.showBottomToastOverlay(
    //       context: context,
    //       errorMessage: "User Registered Successfully",
    //       backgroundColor: Theme.of(context).primaryColor,
    //     );
    //     Navigator.of(context).pushNamed(Routes.home);
    //   }
    // }
  }

  void _showRestoreUserDialog(SignupStore store, RegistrationData registrationData, String phoneNumber, String email) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            "Account Previously Deleted",
            style: interBold.copyWith(
              fontSize: Dimensions.fontSizeDefaultLarge,
              color: ThemeManager.black,
            ),
          ),
          content: Text(
            "This account was previously deleted. You can restore it to continue.",
            style: interRegular.copyWith(
              fontSize: Dimensions.fontSizeDefault,
              color: ThemeManager.grey4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                "Cancel",
                style: interRegular.copyWith(
                  fontSize: Dimensions.fontSizeDefault,
                  color: ThemeManager.grey4,
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                // Call restore user API
                await _handleRestoreUser(store, email, phoneNumber);
              },
              child: Text(
                "Restore Account",
                style: interBold.copyWith(
                  fontSize: Dimensions.fontSizeDefault,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleRestoreUser(SignupStore store, String email, String phoneNumber) async {
    try {
      final result = await store.onRestoreUser(email, phoneNumber);
      
      if (result != null && result['success'] == true && result['message'] != null) {
        // Show success message
        BottomToast.showBottomToastOverlay(
          context: context,
          errorMessage: result['message'] ?? "User restored successfully",
          backgroundColor: Theme.of(context).primaryColor,
        );
        
        // Navigate to login screen after a short delay
        Future.delayed(const Duration(seconds: 2), () {
          Navigator.of(context).pushNamed(Routes.login);
        });
      } else {
        // Show error message
        BottomToast.showBottomToastOverlay(
          context: context,
          errorMessage: store.errorMessage.isNotEmpty ? store.errorMessage : "Failed to restore user account",
          backgroundColor: Theme.of(context).colorScheme.error,
        );
      }
    } catch (e) {
      // Show error message for any exception
      BottomToast.showBottomToastOverlay(
        context: context,
        errorMessage: "An error occurred while restoring your account",
        backgroundColor: Theme.of(context).colorScheme.error,
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
