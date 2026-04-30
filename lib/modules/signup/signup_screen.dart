import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shusruta_lms/modules/signup/store/signup_store.dart';
import 'package:shusruta_lms/helpers/app_tokens.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import '../../app/routes.dart';
import '../../helpers/colors.dart';
import '../../helpers/dimensions.dart';
import '../../helpers/styles.dart';
import '../../models/registerationData.dart';
import '../login/store/login_store.dart';
import '../widgets/custom_button.dart';
// Custom keyboard import - commented out as we're using system default keyboard
// Uncomment this if you want to re-enable the custom keyboard
// import '../login/keyboard.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
  static Route<dynamic> route(RouteSettings routeSettings) {
    return CupertinoPageRoute(
      builder: (_) => const SignUpScreen(),
    );
  }
}

class _SignUpScreenState extends State<SignUpScreen>
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
  List<String> selectedCheckboxValues = [];
  List<String> availableCheckboxes = [];
  String? currentStatus;
  bool isChecked = false;
  final _emailKey = GlobalKey<FormFieldState<String>>();
  final _nameKey = GlobalKey<FormFieldState<String>>();
  final _prepParingKey = GlobalKey<FormFieldState<String>>();
  final _passKey = GlobalKey<FormFieldState<String>>();
  final _repassKey = GlobalKey<FormFieldState<String>>();
  final _mobileKey = GlobalKey<FormFieldState<String>>();
  final _dobKey = GlobalKey<FormFieldState<String>>();
  final _emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
  bool _isEmailValid = false;
  bool _isPasswordValid = false;
  bool _isMobileValid = false;
  bool _isNameValid = false;
  bool _isDateValid = false;
  bool _isPreparingValid = false;
  bool isSubmitted = false;
  List<String> preparingForList = [];

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

    return Scaffold(
      backgroundColor: ThemeManager.white,
      body: SingleChildScrollView(
        child: SizedBox(
          // height: MediaQuery.of(context).size.height,
          child: Padding(
            padding: EdgeInsets.only(
              left: Dimensions.PADDING_SIZE_LARGE,
              top: Dimensions.PADDING_SIZE_EXTRA_LARGE * 4,
              right: Dimensions.PADDING_SIZE_LARGE,
              bottom: isKeyboardOpen
                  ? MediaQuery.of(context).viewInsets.bottom
                  : Dimensions.PADDING_SIZE_LARGE * 2,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image.asset("assets/image/hand_alert.png"),
                    // const SizedBox(
                    //   width: Dimensions.PADDING_SIZE_LARGE,
                    // ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Create your account",
                          style: AppTokens.displayMd(context),
                        ),
                        const SizedBox(height: AppTokens.s8),
                        Text(
                          "Welcome to Sushruta LGS — let's set up your prep.",
                          style: AppTokens.bodyLg(context).copyWith(
                            color: AppTokens.muted(context),
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(
                  height: Dimensions.PADDING_SIZE_LARGE * 2,
                ),
                Container(
                  constraints: const BoxConstraints(
                    minHeight: Dimensions.PADDING_SIZE_EXTRA_LARGE * 2,
                  ),
                  child: TextFormField(
                    key: _nameKey,
                    cursorColor: Theme.of(context).disabledColor,
                    style: interRegular.copyWith(
                      fontSize: Dimensions.fontSizeDefault,
                    ),
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
                      fillColor: Theme.of(context).disabledColor,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          12,
                        ),
                        borderSide: BorderSide(
                          color: Theme.of(context).disabledColor,
                        ),
                      ),
                      labelText: 'Full name',
                      hintText: 'Full name',
                      hintStyle: interRegular.copyWith(
                        fontSize: Dimensions.fontSizeSmall,
                        color: ThemeManager.black,
                      ),
                      labelStyle: interRegular.copyWith(
                        fontSize: Dimensions.fontSizeSmall,
                        color: ThemeManager.black,
                      ),
                      counterText: '',
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          12,
                        ),
                        borderSide: BorderSide(
                          color: Theme.of(context).disabledColor,
                        ),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          12,
                        ),
                        borderSide: BorderSide(
                          color: Theme.of(context).disabledColor,
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
                    cursorColor: Theme.of(context).disabledColor,
                    style: interRegular.copyWith(
                      fontSize: Dimensions.fontSizeDefault,
                    ),
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
                      suffixIcon: Icon(
                        Icons.date_range_outlined,
                        color: Theme.of(context).disabledColor,
                      ),
                      fillColor: Theme.of(context).disabledColor,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          12,
                        ),
                        borderSide: BorderSide(
                          color: Theme.of(context).disabledColor,
                        ),
                      ),
                      labelText: 'Date of birth',
                      hintText: 'Date of birth',
                      hintStyle: interRegular.copyWith(
                        fontSize: Dimensions.fontSizeSmall,
                        color: ThemeManager.black,
                      ),
                      labelStyle: interRegular.copyWith(
                        fontSize: Dimensions.fontSizeSmall,
                        color: ThemeManager.black,
                      ),
                      counterText: '',
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          12,
                        ),
                        borderSide: BorderSide(
                          color: Theme.of(context).disabledColor,
                        ),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          12,
                        ),
                        borderSide: BorderSide(
                          color: Theme.of(context).disabledColor,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  height: Dimensions.PADDING_SIZE_DEFAULT,
                ),
                DropdownButtonFormField<String>(
                  key: _prepParingKey,
                  dropdownColor: ThemeManager.white,
                  value: selectedValue.isNotEmpty ? selectedValue : null,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      setState(() {
                        _isPreparingValid = false;
                      });
                      return 'Please choose one.';
                    }
                    setState(() {
                      _isPreparingValid = true;
                    });
                    return null;
                  },
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.transparent,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.red),
                    ),
                    labelText: 'Preparing for',
                    labelStyle: interRegular.copyWith(
                      fontSize: Dimensions.fontSizeSmall,
                      color: ThemeManager.black,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                  ),
                  items: dropdownItems,
                  onChanged: (value) {
                    setState(() {
                      selectedCheckboxValues = [];
                      selectedValue = value!;
                      _isPreparingValid = true;

                      final selectedItem = store.preparingexams.firstWhere(
                        (item) => item?.preparingFor == selectedValue,
                        orElse: () => null,
                      );
                      availableCheckboxes = selectedItem != null
                          ? List<String>.from(
                              selectedItem.checkbox as List<dynamic>)
                          : [];
                    });
                  },
                  isExpanded: true,
                  icon: Icon(
                    Icons.keyboard_arrow_down,
                    color: Theme.of(context).disabledColor,
                  ),
                  iconSize: 24,
                  elevation: 16,
                  style: interRegular.copyWith(
                    fontSize: Dimensions.fontSizeSmall,
                    color: ThemeManager.black,
                  ),
                ),
                const SizedBox(width: Dimensions.PADDING_SIZE_LARGE),
                if (availableCheckboxes.isNotEmpty)
                  ListView.builder(
                    padding: const EdgeInsets.only(top: 0),
                    shrinkWrap: true,
                    itemCount: availableCheckboxes.length,
                    itemBuilder: (context, index) {
                      final checkboxValue = availableCheckboxes[index];
                      final isChecked =
                          selectedCheckboxValues.contains(checkboxValue);
                      return Row(
                        children: [
                          Checkbox(
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                            value: isChecked,
                            onChanged: (value) {
                              setState(() {
                                if (value!) {
                                  selectedCheckboxValues.add(checkboxValue);
                                } else {
                                  selectedCheckboxValues.remove(checkboxValue);
                                }
                              });
                            },
                            activeColor: Theme.of(context).primaryColor,
                            side: BorderSide(
                              color: Theme.of(context).disabledColor,
                            ),
                          ),
                          Text(
                            checkboxValue,
                            style: interRegular.copyWith(
                                fontSize: Dimensions.fontSizeSmall,
                                color: ThemeManager.black,
                                fontWeight: FontWeight.w400),
                          ),
                        ],
                      );
                    },
                  ),
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
                  height: Dimensions.PADDING_SIZE_DEFAULT,
                ),
                Text(
                  "What Are You Currently Doing",
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
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
                        activeColor: ThemeManager.currentTheme == AppTheme.Dark
                            ? ThemeManager.white
                            : Theme.of(context).primaryColor,
                        side: BorderSide(
                          color: ThemeManager.currentTheme == AppTheme.Dark
                              ? ThemeManager.black
                              : Theme.of(context).disabledColor,
                        ),
                      ),
                      Text(
                        'PG Resident',
                        style: interRegular.copyWith(
                            fontSize: Dimensions.fontSizeSmall,
                            color: ThemeManager.black,
                            fontWeight: FontWeight.w400),
                      ),
                    ]),
                    const SizedBox(width: Dimensions.PADDING_SIZE_EXTRA_LARGE),
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      Checkbox(
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
                        activeColor: ThemeManager.currentTheme == AppTheme.Dark
                            ? ThemeManager.white
                            : Theme.of(context).primaryColor,
                        side: BorderSide(
                          color: ThemeManager.currentTheme == AppTheme.Dark
                              ? ThemeManager.black
                              : Theme.of(context).disabledColor,
                        ),
                      ),
                      Text(
                        'Post-Graduate',
                        style: interRegular.copyWith(
                            fontSize: Dimensions.fontSizeSmall,
                            color: ThemeManager.black,
                            fontWeight: FontWeight.w400),
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
                    cursorColor: Theme.of(context).disabledColor,
                    style: interRegular.copyWith(
                      fontSize: Dimensions.fontSizeDefault,
                    ),
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
                      fillColor: Theme.of(context).disabledColor,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          12,
                        ),
                        borderSide: BorderSide(
                          color: Theme.of(context).disabledColor,
                        ),
                      ),
                      labelText: 'Mobile number',
                      hintText: 'Mobile number',
                      hintStyle: interRegular.copyWith(
                        fontSize: Dimensions.fontSizeSmall,
                        color: ThemeManager.black,
                      ),
                      labelStyle: interRegular.copyWith(
                        fontSize: Dimensions.fontSizeSmall,
                        color: ThemeManager.black,
                      ),
                      counterText: '',
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          12,
                        ),
                        borderSide: BorderSide(
                          color: Theme.of(context).disabledColor,
                        ),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          12,
                        ),
                        borderSide: BorderSide(
                          color: Theme.of(context).disabledColor,
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
                    cursorColor: Theme.of(context).disabledColor,
                    style: interRegular.copyWith(
                      fontSize: Dimensions.fontSizeDefault,
                    ),
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
                      fillColor: Theme.of(context).disabledColor,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          12,
                        ),
                        borderSide: BorderSide(
                          color: Theme.of(context).disabledColor,
                        ),
                      ),
                      labelText: 'Enter email',
                      hintText: 'Enter email',
                      hintStyle: interRegular.copyWith(
                        fontSize: Dimensions.fontSizeSmall,
                        color: ThemeManager.black,
                      ),
                      labelStyle: interRegular.copyWith(
                        fontSize: Dimensions.fontSizeSmall,
                        color: ThemeManager.black,
                      ),
                      counterText: '',
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          12,
                        ),
                        borderSide: BorderSide(
                          color: Theme.of(context).disabledColor,
                        ),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          12,
                        ),
                        borderSide: BorderSide(
                          color: Theme.of(context).disabledColor,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  height: Dimensions.PADDING_SIZE_DEFAULT,
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
                Column(
                  children: [
                    Observer(builder: (_) {
                      return CustomButton(
                        onPressed: () {
                          FocusScope.of(context).unfocus();
                          isSubmitted = true;
                          bool? nameValidate =
                              _nameKey.currentState?.validate();
                          bool? dateValidate = _dobKey.currentState?.validate();
                          bool? preParingValidate =
                              _prepParingKey.currentState?.validate();
                          bool? emailValidate =
                              _emailKey.currentState?.validate();
                          bool? mobileValidate =
                              _mobileKey.currentState?.validate();
                          // bool? passwordValidate = _passKey.currentState?.validate();
                          // bool? rePasswordValidate = _repassKey.currentState?.validate();
                          if (nameValidate! &&
                              dateValidate! &&
                              preParingValidate! &&
                              emailValidate! &&
                              mobileValidate!) {
                            _register(
                                store,
                                loginStore,
                                nameController.text,
                                dateController.text,
                                selectedValue,
                                selectedCheckboxValues,
                                currentStatus ?? "",
                                phoneController.text,
                                emailController.text);
                          }
                        },
                        buttonText: "Next",
                        height: 54,
                        bgColor: Theme.of(context).primaryColor,
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
                      height: Dimensions.PADDING_SIZE_LARGE,
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
                              fontSize: Dimensions.fontSizeSmall,
                              color: Theme.of(context).hintColor),
                        ),
                        InkWell(
                          onTap: () {
                            Navigator.of(context)
                                .pushNamed(Routes.loginWithPass);
                          },
                          child: Text(
                            "Login",
                            style: interRegular.copyWith(
                              fontSize: Dimensions.fontSizeSmall,
                              color: Theme.of(context).primaryColor,
                              decoration: TextDecoration.underline,
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
    );
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

  Future<void> _register(
      SignupStore store,
      LoginStore loginStore,
      String fullName,
      String dateOfBirth,
      String preparingValue,
      List<String> preparingFor,
      String currentStatus,
      String phoneNumber,
      String email) async {
    RegistrationData registrationData = RegistrationData(
      fullName: fullName,
      dateOfBirth: dateOfBirth,
      preparingValue: preparingValue,
      stateValue: '',
      preparingFor: preparingFor,
      currentStatus: currentStatus,
      phoneNumber: phoneNumber,
      email: email,
    );

    await store.onSendOtpToMail(email, fullName).then((value) {
      Navigator.of(context).pushNamed(Routes.verifyOtp, arguments: {
        'email': email,
        'registrationObj': registrationData,
        'trial': true,
        'email2': email
      });
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
        final formattedDate = DateFormat('dd - MMMM - yyyy').format(picked);
        dateController.text = formattedDate;
      });
    }
  }
}
