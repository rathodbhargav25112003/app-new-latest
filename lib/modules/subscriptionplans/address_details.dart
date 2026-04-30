// ignore_for_file: deprecated_member_use, unused_import, unnecessary_import,
// dead_null_aware_expression

import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:shusruta_lms/modules/subscriptionplans/save_address_bottom_sheet.dart';
import 'package:shusruta_lms/modules/subscriptionplans/store/subscription_store.dart';
import '../../app/routes.dart';
import '../../helpers/app_tokens.dart';
import '../../helpers/colors.dart';
import '../../helpers/dimensions.dart';
import '../../helpers/styles.dart';
import '../../models/subscription_model.dart';
import 'edit_address_bottom_sheet.dart';
import 'model/get_address_model.dart';

/// AddressDetailScreen — address picker used right before the payment
/// step. Lists all saved addresses (via [SubscriptionStore]), lets the
/// user select one, add a new one (bottom-sheet on mobile, dialog on
/// desktop), or edit an existing one, then forwards to
/// [Routes.selectBookAndSubscriptionDetail] with the chosen address.
///
/// Public surface preserved exactly:
///   • class [AddressDetailScreen] + const constructor
///     `{super.key, required subscription, required store,
///      required totalAmount, required selectedBooks}`
///   • static [route] factory reading all four arguments
///   • private [_showCustomDialogOrBottomSheet] + [_showAddressUpdateDialogOrBottomSheet]
///   • [getUserAddress] → `store.onGetAllUserAddressApiCall()`
class AddressDetailScreen extends StatefulWidget {
  final SubscriptionModel subscription;
  final SubscriptionStore store;
  final num totalAmount;
  final List<Map<String, dynamic>> selectedBooks;
  const AddressDetailScreen({
    super.key,
    required this.subscription,
    required this.store,
    required this.totalAmount,
    required this.selectedBooks,
  });

  @override
  State<AddressDetailScreen> createState() => _AddressDetailScreenState();
  static Route<dynamic> route(RouteSettings routeSettings) {
    final arguments = routeSettings.arguments as Map<String, dynamic>;
    return CupertinoPageRoute(
      builder: (_) => AddressDetailScreen(
        subscription: arguments['subscription'],
        store: arguments['store'],
        totalAmount: arguments['totalAmount'],
        selectedBooks: arguments['selectedBooks'],
      ),
    );
  }
}

class _AddressDetailScreenState extends State<AddressDetailScreen> {
  int currentIndex = 0;
  @override
  void initState() {
    super.initState();
    getUserAddress();
  }

  Future<void> getUserAddress() async {
    final store = Provider.of<SubscriptionStore>(context, listen: false);
    await store.onGetAllUserAddressApiCall();
  }

  @override
  Widget build(BuildContext context) {
    final store = Provider.of<SubscriptionStore>(context);
    final isDesktop = Platform.isWindows || Platform.isMacOS;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppTokens.scaffold(context),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTokens.brand, AppTokens.brand2],
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: isDesktop
                  ? const EdgeInsets.symmetric(
                      vertical: Dimensions.PADDING_SIZE_LARGE * 1,
                      horizontal: Dimensions.PADDING_SIZE_LARGE * 1.2)
                  : const EdgeInsets.only(
                      top: Dimensions.PADDING_SIZE_LARGE * 3,
                      left: Dimensions.PADDING_SIZE_SMALL * 1.4,
                      right: Dimensions.PADDING_SIZE_LARGE * 1.2,
                      bottom: Dimensions.PADDING_SIZE_SMALL * 1.3),
              child: Row(
                children: [
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(AppTokens.r12),
                      child: Container(
                        width: 40,
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(AppTokens.r12),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.18),
                          ),
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: Dimensions.PADDING_SIZE_DEFAULT,
                  ),
                  Expanded(
                    child: Text(
                      "Address Details",
                      style: AppTokens.titleLg(context).copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () async {
                        showModalBottomSheet<void>(
                          isScrollControlled: true,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(25),
                            ),
                          ),
                          clipBehavior: Clip.antiAliasWithSaveLayer,
                          context: context,
                          builder: (BuildContext context) {
                            return const SaveAddressBottomSheet();
                          },
                        ).then((value) {
                          getUserAddress();
                        });
                      },
                      borderRadius: BorderRadius.circular(AppTokens.r12),
                      child: Container(
                        width: 40,
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(AppTokens.r12),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.18),
                          ),
                        ),
                        child: const Icon(
                          Icons.add_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.only(
                    left: Dimensions.PADDING_SIZE_DEFAULT,
                    right: Dimensions.PADDING_SIZE_DEFAULT,
                    top: Dimensions.PADDING_SIZE_LARGE * 1.9),
                decoration: BoxDecoration(
                  color: AppTokens.scaffold(context),
                  borderRadius: isDesktop
                      ? null
                      : const BorderRadius.only(
                          topLeft: Radius.circular(AppTokens.r28),
                          topRight: Radius.circular(AppTokens.r28),
                        ),
                ),
                child: Observer(builder: (context) {
                  if (store.isLoading) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: AppTokens.accent(context),
                      ),
                    );
                  }
                  if (store.getAllUserAddress.isEmpty) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Spacer(),
                        SvgPicture.asset("assets/image/noAddress.svg"),
                        const SizedBox(
                            height: Dimensions.PADDING_SIZE_DEFAULT),
                        Text(
                          "Add new address",
                          style: AppTokens.titleLg(context).copyWith(
                            color: AppTokens.ink(context),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AppTokens.s8),
                        Text(
                          "Save a delivery address so we can ship your books to you.",
                          textAlign: TextAlign.center,
                          style: AppTokens.body(context).copyWith(
                            color: AppTokens.ink2(context),
                          ),
                        ),
                        const Spacer(),
                        _PrimaryCta(
                          label: "Add Address",
                          onTap: () async {
                            await _showCustomDialogOrBottomSheet(context);
                          },
                        ),
                        const SizedBox(
                          height: Dimensions.PADDING_SIZE_LARGE * 1.3,
                        ),
                      ],
                    );
                  }
                  return Column(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Select Address",
                              style: AppTokens.titleMd(context).copyWith(
                                color: AppTokens.ink(context),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(
                              height: Dimensions.PADDING_SIZE_DEFAULT,
                            ),
                            Expanded(
                              child: ListView.builder(
                                itemCount: store.getAllUserAddress.length,
                                shrinkWrap: true,
                                padding: EdgeInsets.zero,
                                itemBuilder:
                                    (BuildContext context, int index) {
                                  GetAddressModel? address =
                                      store.getAllUserAddress[index];
                                  String addressText = [
                                    address?.buildingNumber,
                                    address?.landMark,
                                    address?.city,
                                    address?.state,
                                    address?.pincode,
                                  ].where((element) => true).join(", ");
                                  final bool selected = currentIndex == index;
                                  return Padding(
                                    padding: const EdgeInsets.only(
                                        bottom:
                                            Dimensions.PADDING_SIZE_DEFAULT),
                                    child: _AddressCard(
                                      name: "${address?.name}",
                                      addressText: addressText,
                                      selected: selected,
                                      onTap: () {
                                        setState(() {
                                          currentIndex = index;
                                        });
                                      },
                                      onEdit: () async {
                                        setState(() {
                                          currentIndex = index;
                                        });
                                        await _showAddressUpdateDialogOrBottomSheet(
                                            context, address!);
                                        await getUserAddress();
                                      },
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                          left: Dimensions.PADDING_SIZE_SMALL,
                          right: Dimensions.PADDING_SIZE_SMALL,
                        ),
                        child: _PrimaryCta(
                          label: "Select Address",
                          onTap: () {
                            Navigator.of(context).pushNamed(
                                Routes.selectBookAndSubscriptionDetail,
                                arguments: {
                                  'subscription': widget.subscription,
                                  'store': widget.store,
                                  'totalAmount': widget.totalAmount,
                                  'selectedBooks': widget.selectedBooks,
                                  'address':
                                      store.getAllUserAddress[currentIndex],
                                });
                          },
                        ),
                      ),
                      const SizedBox(
                        height: Dimensions.PADDING_SIZE_LARGE * 1.3,
                      ),
                    ],
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showCustomDialogOrBottomSheet(BuildContext context) async {
    if (Platform.isAndroid || Platform.isIOS) {
      // For mobile platforms, show the bottom sheet
      await showModalBottomSheet<void>(
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(25),
          ),
        ),
        clipBehavior: Clip.antiAliasWithSaveLayer,
        context: context,
        builder: (BuildContext context) {
          return const SaveAddressBottomSheet();
        },
      );
    } else if (Platform.isMacOS || Platform.isWindows) {
      // For desktop platforms, show the dialog
      await showDialog<void>(
        context: context,
        builder: (BuildContext context) {
          return Dialog(
            backgroundColor: AppTokens.surface(context),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
            child: const SaveAddressBottomSheet(),
          );
        },
      );
    }

    // Execute after the dialog/bottom sheet is closed
    getUserAddress();
  }

  Future<void> _showAddressUpdateDialogOrBottomSheet(
      BuildContext context, GetAddressModel address) async {
    if (Platform.isAndroid || Platform.isIOS) {
      // For mobile platforms, show the bottom sheet
      await showModalBottomSheet<void>(
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(25),
          ),
        ),
        clipBehavior: Clip.antiAliasWithSaveLayer,
        context: context,
        builder: (BuildContext context) {
          return UpdateAddressBottomSheet(
            address: address,
          );
        },
      );
    } else if (Platform.isMacOS || Platform.isWindows) {
      // For desktop platforms, show the dialog
      await showDialog<void>(
        context: context,
        builder: (BuildContext context) {
          return Dialog(
            backgroundColor: AppTokens.surface(context),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
            child: UpdateAddressBottomSheet(
              address: address,
            ),
          );
        },
      );
    }
  }
}

/// Address card — radio selector + name/address + edit button.
class _AddressCard extends StatelessWidget {
  const _AddressCard({
    required this.name,
    required this.addressText,
    required this.selected,
    required this.onTap,
    required this.onEdit,
  });
  final String name;
  final String addressText;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.only(
              left: Dimensions.PADDING_SIZE_SMALL * 1.8,
              right: Dimensions.PADDING_SIZE_SMALL * 1.4,
              top: Dimensions.PADDING_SIZE_LARGE,
              bottom: Dimensions.PADDING_SIZE_LARGE,
            ),
            decoration: BoxDecoration(
              color: selected
                  ? AppTokens.accentSoft(context)
                  : AppTokens.surface(context),
              borderRadius: BorderRadius.circular(AppTokens.r16),
              border: Border.all(
                color: selected
                    ? AppTokens.accent(context)
                    : AppTokens.border(context),
                width: selected ? 1.2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  offset: const Offset(0, 1),
                  blurRadius: 10,
                  spreadRadius: 0,
                  color: Colors.black.withOpacity(0.04),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(
                      top: Dimensions.PADDING_SIZE_EXTRA_SMALL),
                  width: Dimensions.PADDING_SIZE_LARGE,
                  height: Dimensions.PADDING_SIZE_LARGE,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppTokens.surface(context),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected
                          ? AppTokens.accent(context)
                          : AppTokens.border(context),
                      width: 2,
                    ),
                  ),
                  child: selected
                      ? Container(
                          width: Dimensions.PADDING_SIZE_SMALL,
                          height: Dimensions.PADDING_SIZE_SMALL,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppTokens.accent(context),
                            shape: BoxShape.circle,
                          ),
                        )
                      : const SizedBox(),
                ),
                const SizedBox(width: Dimensions.PADDING_SIZE_LARGE),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: AppTokens.body(context).copyWith(
                          color: AppTokens.ink(context),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        addressText,
                        style: AppTokens.body(context).copyWith(
                          color: AppTokens.ink2(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: Dimensions.PADDING_SIZE_SMALL,
            right: Dimensions.PADDING_SIZE_SMALL * 1.4,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onEdit,
                borderRadius: BorderRadius.circular(AppTokens.r8),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child:
                      SvgPicture.asset("assets/image/editAddress.svg"),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Gradient primary CTA — used by both the empty state and the
/// "Select Address" button so they look consistent.
class _PrimaryCta extends StatelessWidget {
  const _PrimaryCta({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTokens.r12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Ink(
            height: Dimensions.PADDING_SIZE_LARGE * 2.2,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTokens.brand, AppTokens.brand2],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppTokens.r12),
              boxShadow: [
                BoxShadow(
                  color: AppTokens.brand.withOpacity(0.28),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Center(
              child: Text(
                label,
                style: AppTokens.body(context).copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
