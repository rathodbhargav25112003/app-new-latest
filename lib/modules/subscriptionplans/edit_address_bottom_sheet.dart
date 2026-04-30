// ignore_for_file: deprecated_member_use, unused_import, unnecessary_import, library_private_types_in_public_api, use_build_context_synchronously, unused_field

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:shusruta_lms/helpers/dimensions.dart';
import 'package:shusruta_lms/modules/subscriptionplans/store/subscription_store.dart';

import '../../app/routes.dart';
import '../../helpers/app_tokens.dart';
import '../../helpers/colors.dart';
import '../../helpers/styles.dart';
import '../widgets/bottom_toast.dart';
import 'model/get_address_model.dart';

/// UpdateAddressBottomSheet — bottom sheet used from the address list to
/// edit an existing shipping address. Pre-fills controllers from
/// [widget.address] and calls [SubscriptionStore.onUpdateAddress] on save.
///
/// Public surface preserved exactly:
///   • class [UpdateAddressBottomSheet] + const constructor
///     `{super.key, required address}`
///   • private [updateAddressData] signature (addressId, buildingNumber,
///     landMark, pinCode, city, state, phone, name, email)
///   • All 8 `GlobalKey<FormFieldState<String>>` validators and their
///     companion `_isXXXValid` booleans
///   • [_emailRegex] pattern
///   • All hint labels / CTA copy ("Edit Address")
class UpdateAddressBottomSheet extends StatefulWidget {
  final GetAddressModel? address;
  const UpdateAddressBottomSheet({super.key, required this.address});

  @override
  State<UpdateAddressBottomSheet> createState() =>
      _UpdateAddressBottomSheetState();
}

class _UpdateAddressBottomSheetState extends State<UpdateAddressBottomSheet> {
  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController buildingController = TextEditingController();
  TextEditingController landMarkController = TextEditingController();
  TextEditingController pinCodeController = TextEditingController();
  TextEditingController cityController = TextEditingController();
  TextEditingController stateController = TextEditingController();
  final _nameKey = GlobalKey<FormFieldState<String>>();
  bool _isNameValid = false;
  final _phoneKey = GlobalKey<FormFieldState<String>>();
  bool _isphoneValid = false;
  final _buildingKey = GlobalKey<FormFieldState<String>>();
  bool _isbuildingValid = false;
  final _landMarkKey = GlobalKey<FormFieldState<String>>();
  bool _islandMarkValid = false;
  final _pinCodeKey = GlobalKey<FormFieldState<String>>();
  bool _ispinCodeValid = false;
  final _cityKey = GlobalKey<FormFieldState<String>>();
  bool _iscityValid = false;
  final _stateKey = GlobalKey<FormFieldState<String>>();
  bool _isstateValid = false;
  final _emailKey = GlobalKey<FormFieldState<String>>();
  bool _isEmailValid = false;
  final _emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

  @override
  void initState() {
    super.initState();
    setState(() {
      nameController.text = widget.address?.name ?? '';
      emailController.text = widget.address?.email ?? '';
      phoneController.text = widget.address?.phone.toString() ?? '';
      buildingController.text = widget.address?.buildingNumber ?? '';
      landMarkController.text = widget.address?.landMark ?? '';
      pinCodeController.text = widget.address?.pincode.toString() ?? '';
      cityController.text = widget.address?.city ?? '';
      stateController.text = widget.address?.state ?? '';
    });
  }

  Future<void> updateAddressData(
      String addressId,
      String buildingNumber,
      String landMark,
      int pinCode,
      String city,
      String state,
      int phone,
      String name,
      String email) async {
    final store = Provider.of<SubscriptionStore>(context, listen: false);
    await store.onUpdateAddress(context, addressId, buildingNumber, landMark,
        pinCode, city, state, phone, name, email);
    Navigator.pop(context);
  }

  Widget _field({
    required GlobalKey<FormFieldState<String>> fieldKey,
    required TextEditingController controller,
    required String hint,
    required String? Function(String?) validator,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    void Function(String)? onChanged,
  }) {
    return SizedBox(
      height: Dimensions.PADDING_SIZE_EXTRA_LARGE * 3,
      child: TextFormField(
        key: fieldKey,
        cursorColor: AppTokens.ink(context),
        controller: controller,
        validator: validator,
        onChanged: onChanged,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        style: AppTokens.body(context).copyWith(
          color: AppTokens.ink(context),
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          filled: true,
          fillColor: AppTokens.surface2(context),
          hintStyle: AppTokens.body(context).copyWith(
            color: AppTokens.muted(context),
            fontWeight: FontWeight.w400,
          ),
          hintText: hint,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: Dimensions.PADDING_SIZE_DEFAULT, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTokens.r12),
            borderSide: BorderSide(color: AppTokens.border(context), width: 1),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTokens.r12),
            borderSide: BorderSide(color: AppTokens.border(context), width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTokens.r12),
            borderSide: BorderSide(color: AppTokens.border(context), width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTokens.r12),
            borderSide: const BorderSide(color: AppTokens.brand, width: 1.4),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTokens.r12),
            borderSide: BorderSide(color: AppTokens.danger(context), width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTokens.r12),
            borderSide:
                BorderSide(color: AppTokens.danger(context), width: 1.4),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 600),
      width: MediaQuery.of(context).size.width,
      decoration: BoxDecoration(
        color: AppTokens.surface(context),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppTokens.r28),
        ),
      ),
      padding: const EdgeInsets.symmetric(
          horizontal: Dimensions.PADDING_SIZE_DEFAULT),
      child: SingleChildScrollView(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const SizedBox(height: Dimensions.PADDING_SIZE_SMALL),
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTokens.border(context),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: Dimensions.PADDING_SIZE_LARGE),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Fill the details",
                  style: AppTokens.titleMd(context).copyWith(
                    color: AppTokens.ink(context),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTokens.surface2(context),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTokens.border(context)),
                    ),
                    child: Icon(
                      Icons.close,
                      color: AppTokens.ink(context),
                      size: 18,
                    ),
                  ),
                )
              ],
            ),
            const SizedBox(height: Dimensions.PADDING_SIZE_DEFAULT),
            _field(
              fieldKey: _nameKey,
              controller: nameController,
              hint: 'Enter your name',
              validator: (value) {
                if (value == null || value.isEmpty) {
                  setState(() {
                    _isNameValid = false;
                  });
                  return 'Please enter name';
                }
                setState(() {
                  _isNameValid = true;
                });
                return null;
              },
            ),
            const SizedBox(height: Dimensions.PADDING_SIZE_SMALL),
            _field(
              fieldKey: _emailKey,
              controller: emailController,
              hint: 'Enter your email',
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
            ),
            const SizedBox(height: Dimensions.PADDING_SIZE_SMALL),
            Row(
              children: [
                Expanded(
                  flex: 5,
                  child: _field(
                    fieldKey: _phoneKey,
                    controller: phoneController,
                    hint: 'Enter mobile number',
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp('[0-9]')),
                      LengthLimitingTextInputFormatter(10),
                    ],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        setState(() {
                          _isphoneValid = false;
                        });
                        return 'Please enter mobile number';
                      }
                      if (value.length < 10 || value.isEmpty) {
                        setState(() {
                          _isphoneValid = false;
                        });
                        return 'Please enter valid mobile number';
                      }
                      setState(() {
                        _isphoneValid = true;
                      });
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: Dimensions.PADDING_SIZE_SMALL),
            _field(
              fieldKey: _buildingKey,
              controller: buildingController,
              hint: 'Enter D.no, Building, street, Area',
              validator: (value) {
                if (value == null || value.isEmpty) {
                  setState(() {
                    _isbuildingValid = false;
                  });
                  return 'Please enter d.no, building, street, area';
                }
                setState(() {
                  _isbuildingValid = true;
                });
                return null;
              },
            ),
            const SizedBox(height: Dimensions.PADDING_SIZE_SMALL),
            _field(
              fieldKey: _landMarkKey,
              controller: landMarkController,
              hint: 'Enter Landmark',
              validator: (value) {
                if (value == null || value.isEmpty) {
                  setState(() {
                    _islandMarkValid = false;
                  });
                  return 'Please enter landmark';
                }
                setState(() {
                  _islandMarkValid = true;
                });
                return null;
              },
            ),
            const SizedBox(height: Dimensions.PADDING_SIZE_SMALL),
            Row(
              children: [
                Expanded(
                  child: _field(
                    fieldKey: _pinCodeKey,
                    controller: pinCodeController,
                    hint: 'Enter pin code',
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp('[0-9]')),
                      LengthLimitingTextInputFormatter(6),
                    ],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        setState(() {
                          _ispinCodeValid = false;
                        });
                        return 'Please enter pin code';
                      }
                      if (value.length < 6 || value.isEmpty) {
                        setState(() {
                          _ispinCodeValid = false;
                        });
                        return 'Please enter valid pin code';
                      }
                      setState(() {
                        _ispinCodeValid = true;
                      });
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: Dimensions.PADDING_SIZE_SMALL),
                Expanded(
                  child: _field(
                    fieldKey: _cityKey,
                    controller: cityController,
                    hint: 'Enter Town/City',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        setState(() {
                          _iscityValid = false;
                        });
                        return 'Please enter city';
                      }
                      setState(() {
                        _iscityValid = true;
                      });
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: Dimensions.PADDING_SIZE_SMALL),
            _field(
              fieldKey: _stateKey,
              controller: stateController,
              hint: 'Enter State',
              validator: (value) {
                if (value == null || value.isEmpty) {
                  setState(() {
                    _isstateValid = false;
                  });
                  return 'Please enter state';
                }
                setState(() {
                  _isstateValid = true;
                });
                return null;
              },
            ),
            const SizedBox(height: Dimensions.PADDING_SIZE_DEFAULT),
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: Dimensions.PADDING_SIZE_SMALL),
              child: _SaveCta(
                label: "Edit Address",
                onTap: () {
                  bool? nameValidate = _nameKey.currentState?.validate();
                  bool? emailValidate = _emailKey.currentState?.validate();
                  bool? phoneValidate = _nameKey.currentState?.validate();
                  bool? buildingValidate = _nameKey.currentState?.validate();
                  bool? landMarkValidate = _nameKey.currentState?.validate();
                  bool? pinCodeValidate = _nameKey.currentState?.validate();
                  bool? cityValidate = _nameKey.currentState?.validate();
                  bool? stateValidate = _nameKey.currentState?.validate();
                  if (nameValidate! &&
                      emailValidate! &&
                      phoneValidate! &&
                      buildingValidate! &&
                      landMarkValidate! &&
                      pinCodeValidate! &&
                      cityValidate! &&
                      stateValidate!) {
                    updateAddressData(
                        widget.address?.sId ?? '',
                        buildingController.text,
                        landMarkController.text,
                        int.parse(pinCodeController.text),
                        cityController.text,
                        stateController.text,
                        int.parse(phoneController.text),
                        nameController.text,
                        emailController.text);
                  }
                },
              ),
            ),
            const SizedBox(height: Dimensions.PADDING_SIZE_DEFAULT),
          ],
        ),
      ),
    );
  }
}

/// Gradient CTA matching the design system's primary action style.
class _SaveCta extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _SaveCta({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTokens.r12),
        onTap: onTap,
        child: Ink(
          height: Dimensions.PADDING_SIZE_LARGE * 2.4,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTokens.brand, AppTokens.brand2],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppTokens.r12),
            boxShadow: [
              BoxShadow(
                color: AppTokens.brand.withOpacity(0.25),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: Text(
              label,
              style: AppTokens.titleSm(context).copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
