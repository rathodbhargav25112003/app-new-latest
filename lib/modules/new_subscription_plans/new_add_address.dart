// ignore_for_file: deprecated_member_use, unused_import, unnecessary_import, library_private_types_in_public_api, use_build_context_synchronously, use_super_parameters

import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:provider/provider.dart';
import 'package:shusruta_lms/modules/new_subscription_plans/widget/custom_info_card.dart';
import 'package:shusruta_lms/modules/new_subscription_plans/widget/exam_goal_dialog.dart';

import '../../app/routes.dart';
import '../../helpers/app_tokens.dart';
import '../../helpers/colors.dart';
import '../../helpers/dimensions.dart';
import '../../helpers/styles.dart';
import '../notes/sharedhelper.dart';
import 'model/delivery_service_model.dart';
import 'store/new_subscription_store.dart';

/// NewAddAddress — form for capturing a new shipping address during the
/// hardcopy-notes purchase flow. Pre-fills the 6-digit pincode either from
/// [widget.pincode] or [NewSubscriptionStore.pincode] and falls back to
/// "382350"; the pincode field stays read-only.
///
/// Public surface preserved exactly:
///   • class [NewAddAddress] + const constructor `{Key? key, pincode}`
///   • static [route] factory that reads `arguments['pincode']` and wraps
///     the page in a [MultiProvider] providing [NewSubscriptionStore]
///   • MobX: `_store.setPincode`, `_store.pincode`,
///     `_store.isAddressLoading`, `_store.createAddress(addressData)`
///   • `_saveAddress` builds the address map with keys
///     `name / phone / email / address / buildingNumber / City / State /
///     Pincode`, then on success pops twice back to NewCheckoutPlan
class NewAddAddress extends StatefulWidget {
  final String? pincode;

  const NewAddAddress({Key? key, this.pincode}) : super(key: key);

  @override
  State<NewAddAddress> createState() => _NewAddAddressState();

  static Route<dynamic> route(RouteSettings routeSettings) {
    final args = routeSettings.arguments as Map<String, dynamic>?;
    return CupertinoPageRoute(
      builder: (_) => MultiProvider(
        providers: [
          Provider<NewSubscriptionStore>(
            create: (_) => NewSubscriptionStore(),
          ),
        ],
        child: NewAddAddress(pincode: args?['pincode']),
      ),
    );
  }
}

class _NewAddAddressState extends State<NewAddAddress> {
  late NewSubscriptionStore _store;

  // Form controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _addressLine1Controller =
      TextEditingController();
  final TextEditingController _addressLine2Controller =
      TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();

    // Initialize pincode from widget parameter first if provided
    if (widget.pincode != null && widget.pincode!.isNotEmpty) {
      _pincodeController.text = widget.pincode!;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _store = Provider.of<NewSubscriptionStore>(context);

    // Pre-fill pincode from widget parameter first, then from the store (if still empty)
    if (_pincodeController.text.isEmpty) {
      if (_store.pincode.isNotEmpty) {
        _pincodeController.text = _store.pincode;
      } else {
        // Default fallback value if no pincode available
        _pincodeController.text = "382350";
      }
    }

    // Make sure the store has the pincode value (for serviceability check later)
    if (widget.pincode != null &&
        widget.pincode!.isNotEmpty &&
        _store.pincode.isEmpty) {
      _store.setPincode(widget.pincode!);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTokens.scaffold(context),
      body: Column(
        children: [
          // Brand gradient hero header
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTokens.brand, AppTokens.brand2],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 16,
              bottom: 24,
              left: 16,
              right: 16,
            ),
            child: Row(
              children: [
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(22),
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Colors.white.withOpacity(0.18)),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  "Add address",
                  style: AppTokens.titleMd(context).copyWith(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          // Main content
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppTokens.scaffold(context),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppTokens.r28),
                  topRight: Radius.circular(AppTokens.r28),
                ),
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Enter your shipping details\nfor delivery",
                          style: AppTokens.titleLg(context).copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppTokens.ink(context),
                          ),
                        ),
                        const SizedBox(height: AppTokens.s8),
                        Text(
                          "We'll ship your hardcopy notes here.",
                          style: AppTokens.body(context).copyWith(
                            color: AppTokens.muted(context),
                          ),
                        ),
                        const SizedBox(height: AppTokens.s24),

                        // Name
                        _buildTextField(
                          controller: _nameController,
                          hintText: "Enter your name",
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Name is required";
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: AppTokens.s16),

                        // Phone number with prefix
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 80,
                              height: 56,
                              decoration: BoxDecoration(
                                color: AppTokens.surface2(context),
                                border: Border.all(
                                    color: AppTokens.border(context)),
                                borderRadius:
                                    BorderRadius.circular(AppTokens.r12),
                              ),
                              child: Center(
                                child: Text(
                                  "+ 91",
                                  style: AppTokens.body(context).copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppTokens.ink(context),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildTextField(
                                controller: _phoneController,
                                hintText: "Enter mobile number",
                                keyboardType: TextInputType.phone,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return "Phone number is required";
                                  }
                                  if (value.length < 10) {
                                    return "Please enter a valid phone number";
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: AppTokens.s16),

                        // Email
                        _buildTextField(
                          controller: _emailController,
                          hintText: "Enter email",
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value != null && value.isNotEmpty) {
                              final bool emailValid = RegExp(
                                      r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
                                  .hasMatch(value);
                              if (!emailValid) {
                                return "Please enter a valid email";
                              }
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: AppTokens.s16),

                        // Address Line 1
                        _buildTextField(
                          controller: _addressLine1Controller,
                          hintText: "Address Line 1",
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Address is required";
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: AppTokens.s16),

                        // Address Line 2 (Optional)
                        _buildTextField(
                          controller: _addressLine2Controller,
                          hintText: "Address Line 2 (Optional)",
                        ),

                        const SizedBox(height: AppTokens.s16),

                        // City and State in a row
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _buildTextField(
                                controller: _cityController,
                                hintText: "City",
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return "City is required";
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildTextField(
                                controller: _stateController,
                                hintText: "State",
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return "State is required";
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: AppTokens.s16),

                        // Pincode - Prefilled and readonly
                        _buildTextField(
                          controller: _pincodeController,
                          hintText: "Pincode",
                          keyboardType: TextInputType.number,
                          readOnly: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Pincode is required";
                            }
                            if (value.length != 6) {
                              return "Please enter a valid 6-digit pincode";
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: AppTokens.s24),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Save button at bottom
          Observer(
            builder: (_) {
              return Container(
                width: double.infinity,
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  bottom: MediaQuery.of(context).padding.bottom + 16,
                  top: 16,
                ),
                decoration: BoxDecoration(
                  color: AppTokens.surface(context),
                  border: Border(
                    top: BorderSide(color: AppTokens.border(context)),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      offset: const Offset(0, -4),
                      blurRadius: 16,
                    ),
                  ],
                ),
                child: _SaveCta(
                  loading: _store.isAddressLoading,
                  onTap: _store.isAddressLoading ? null : _saveAddress,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _saveAddress() async {
    if (_formKey.currentState!.validate()) {
      // Prepare address data
      final addressData = {
        "name": _nameController.text,
        "phone": int.parse(_phoneController.text),
        "email": _emailController.text,
        "address": _addressLine1Controller.text,
        "buildingNumber": _addressLine2Controller.text,
        "City": _cityController.text,
        "State": _stateController.text,
        "Pincode": int.parse(_pincodeController.text),
      };

      // Create address through store
      final success = await _store.createAddress(addressData);

      if (success && mounted) {
        // Pop back to the SelectDeliveryType screen first
        Navigator.pop(context);

        // Then pop back to the NewCheckoutPlan screen to show the selected address and courier
        Navigator.pop(context);
      }
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
    bool readOnly = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: AppTokens.body(context).copyWith(
        color: AppTokens.ink(context),
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: AppTokens.body(context).copyWith(
          color: AppTokens.muted(context),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        filled: true,
        fillColor:
            readOnly ? AppTokens.surface2(context) : AppTokens.surface(context),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.r12),
          borderSide: BorderSide(color: AppTokens.border(context)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.r12),
          borderSide: const BorderSide(color: AppTokens.brand, width: 1.4),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.r12),
          borderSide: BorderSide(color: AppTokens.border(context)),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.r12),
          borderSide: BorderSide(color: AppTokens.danger(context)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.r12),
          borderSide:
              BorderSide(color: AppTokens.danger(context), width: 1.4),
        ),
      ),
      validator: validator,
      readOnly: readOnly,
    );
  }
}

/// Brand-gradient "Save Address" CTA with loading spinner.
class _SaveCta extends StatelessWidget {
  final bool loading;
  final VoidCallback? onTap;
  const _SaveCta({required this.loading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onTap == null ? 0.7 : 1,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTokens.r12),
          onTap: onTap,
          child: Ink(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTokens.brand, AppTokens.brand2],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppTokens.r12),
            ),
            child: Center(
              child: loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      "Save Address",
                      style: AppTokens.titleSm(context).copyWith(
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
