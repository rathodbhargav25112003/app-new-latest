// ignore_for_file: deprecated_member_use, use_build_context_synchronously, unused_import

import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:shusruta_lms/modules/subscriptionplans/save_address_bottom_sheet.dart';
import 'package:shusruta_lms/modules/subscriptionplans/store/subscription_store.dart';

import '../../app/routes.dart';
import '../../helpers/app_tokens.dart';
import '../../helpers/colors.dart';
import '../../models/subscription_model.dart';
import '../subscriptionplans/edit_address_bottom_sheet.dart';
import '../subscriptionplans/model/get_address_model.dart';
import 'confirm_purchase_bottom_sheet.dart';

/// Address selection for hardcopy purchase — redesigned with AppTokens.
/// Constructor, static route arguments contract, SubscriptionStore Provider
/// wiring, and all address-sheet / confirm-purchase flows preserved.
class HardCopyAddressDetailScreen extends StatefulWidget {
  final num totalAmount;
  final List<Map<String, dynamic>> selectedBooks;

  const HardCopyAddressDetailScreen({
    super.key,
    required this.totalAmount,
    required this.selectedBooks,
  });

  @override
  State<HardCopyAddressDetailScreen> createState() =>
      _HardCopyAddressDetailScreenState();

  static Route<dynamic> route(RouteSettings routeSettings) {
    final arguments = routeSettings.arguments as Map<String, dynamic>;
    return CupertinoPageRoute(
      builder: (_) => HardCopyAddressDetailScreen(
        totalAmount: arguments['totalAmount'],
        selectedBooks: arguments['selectedBooks'],
      ),
    );
  }
}

class _HardCopyAddressDetailScreenState
    extends State<HardCopyAddressDetailScreen> {
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

  Future<void> showPurchaseConfirmation(
      BuildContext context, store, int currentIndex) async {
    if (Platform.isWindows || Platform.isMacOS) {
      await showDialog<void>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: AppTokens.radius20,
            ),
            contentPadding: EdgeInsets.zero,
            clipBehavior: Clip.antiAliasWithSaveLayer,
            content: ConfirmHardCopyPurchaseBottomSheet(
              totalAmount: widget.totalAmount,
              selectedBooks: widget.selectedBooks,
              address: store.getAllUserAddress[currentIndex],
              store: store,
            ),
          );
        },
      );
    } else {
      await showModalBottomSheet<void>(
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppTokens.r28),
          ),
        ),
        clipBehavior: Clip.antiAliasWithSaveLayer,
        context: context,
        builder: (BuildContext context) {
          return ConfirmHardCopyPurchaseBottomSheet(
            totalAmount: widget.totalAmount,
            selectedBooks: widget.selectedBooks,
            address: store.getAllUserAddress[currentIndex],
            store: store,
          );
        },
      );
    }
  }

  Future<void> showAddressSheetOrDialog(
      BuildContext context, GetAddressModel? address) async {
    if (Platform.isWindows || Platform.isMacOS) {
      await showDialog<void>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: AppTokens.radius20,
            ),
            contentPadding: EdgeInsets.zero,
            clipBehavior: Clip.antiAliasWithSaveLayer,
            content: address != null
                ? UpdateAddressBottomSheet(address: address)
                : const SaveAddressBottomSheet(),
          );
        },
      ).then((value) {
        getUserAddress();
      });
    } else {
      await showModalBottomSheet<void>(
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppTokens.r28),
          ),
        ),
        clipBehavior: Clip.antiAliasWithSaveLayer,
        context: context,
        builder: (BuildContext context) {
          return address != null
              ? UpdateAddressBottomSheet(address: address)
              : const SaveAddressBottomSheet();
        },
      ).then((value) {
        getUserAddress();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = Provider.of<SubscriptionStore>(context);
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppTokens.scaffold(context),
      body: Column(
        children: [
          _Header(
            onBack: () => Navigator.pop(context),
            onAdd: () async => showAddressSheetOrDialog(context, null),
          ),
          Expanded(
            child: Observer(builder: (_) {
              if (store.isLoading) {
                return Center(
                  child: CircularProgressIndicator(
                    color: AppTokens.accent(context),
                  ),
                );
              }
              if (store.getAllUserAddress.isEmpty) {
                return _EmptyState(
                  onAdd: () async =>
                      showAddressSheetOrDialog(context, null),
                );
              }
              return Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppTokens.s16,
                  AppTokens.s20,
                  AppTokens.s16,
                  AppTokens.s16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Select Address',
                      style: AppTokens.titleSm(context),
                    ),
                    const SizedBox(height: AppTokens.s12),
                    Expanded(
                      child: ListView.separated(
                        padding: EdgeInsets.zero,
                        itemCount: store.getAllUserAddress.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: AppTokens.s12),
                        itemBuilder: (_, index) {
                          final GetAddressModel? address =
                              store.getAllUserAddress[index];
                          final addressText = [
                            address?.buildingNumber,
                            address?.landMark,
                            address?.city,
                            address?.state,
                            address?.pincode,
                          ].where((e) => e != null && '$e'.isNotEmpty).join(', ');
                          return _AddressCard(
                            name: address?.name ?? '',
                            address: addressText,
                            selected: currentIndex == index,
                            onSelect: () =>
                                setState(() => currentIndex = index),
                            onEdit: () async {
                              setState(() => currentIndex = index);
                              await showAddressSheetOrDialog(context, address);
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: AppTokens.s12),
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () => showPurchaseConfirmation(
                            context, store, currentIndex),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTokens.accent(context),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: AppTokens.radius12,
                          ),
                        ),
                        child: Text(
                          'Select Address',
                          style: AppTokens.titleSm(context).copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Header
// ---------------------------------------------------------------------------

class _Header extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onAdd;
  const _Header({required this.onBack, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTokens.brand, AppTokens.brand2],
        ),
        boxShadow: [
          BoxShadow(
            color: AppTokens.brand.withOpacity(0.25),
            blurRadius: 24,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTokens.s12,
            AppTokens.s8,
            AppTokens.s12,
            AppTokens.s16,
          ),
          child: Row(
            children: [
              _CircleBtn(icon: Icons.arrow_back_ios_new_rounded, onTap: onBack),
              const SizedBox(width: AppTokens.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Checkout',
                      style: AppTokens.overline(context).copyWith(
                        color: Colors.white.withOpacity(0.75),
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Address Details',
                      style: AppTokens.titleLg(context).copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              _CircleBtn(icon: Icons.add_rounded, onTap: onAdd),
            ],
          ),
        ),
      ),
    );
  }
}

class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.18),
      borderRadius: AppTokens.radius12,
      child: InkWell(
        borderRadius: AppTokens.radius12,
        onTap: onTap,
        child: SizedBox(
          height: 40,
          width: 40,
          child: Icon(icon, color: Colors.white, size: 18),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppTokens.s24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Spacer(),
          Container(
            width: 96,
            height: 96,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppTokens.accentSoft(context),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.location_on_outlined,
              size: 44,
              color: AppTokens.accent(context),
            ),
          ),
          const SizedBox(height: AppTokens.s16),
          Text(
            'No addresses yet',
            style: AppTokens.titleMd(context),
          ),
          const SizedBox(height: AppTokens.s8),
          Text(
            'Add a shipping address to continue your purchase.',
            style: AppTokens.body(context),
            textAlign: TextAlign.center,
          ),
          const Spacer(),
          SizedBox(
            height: 52,
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onAdd,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTokens.accent(context),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: AppTokens.radius12,
                ),
              ),
              icon: const Icon(Icons.add_rounded),
              label: Text(
                'Add Address',
                style: AppTokens.titleSm(context).copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Address card
// ---------------------------------------------------------------------------

class _AddressCard extends StatelessWidget {
  final String name;
  final String address;
  final bool selected;
  final VoidCallback onSelect;
  final VoidCallback onEdit;

  const _AddressCard({
    required this.name,
    required this.address,
    required this.selected,
    required this.onSelect,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: AppTokens.radius16,
      child: InkWell(
        borderRadius: AppTokens.radius16,
        onTap: onSelect,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(AppTokens.s16),
          decoration: BoxDecoration(
            color: selected
                ? AppTokens.accentSoft(context)
                : AppTokens.surface(context),
            borderRadius: AppTokens.radius16,
            border: Border.all(
              color: selected
                  ? AppTokens.accent(context)
                  : AppTokens.border(context),
              width: selected ? 1.5 : 1,
            ),
            boxShadow: selected ? null : AppTokens.shadow1(context),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 2),
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected
                      ? AppTokens.accent(context)
                      : AppTokens.surface(context),
                  border: Border.all(
                    color: selected
                        ? AppTokens.accent(context)
                        : AppTokens.borderStrong(context),
                    width: 2,
                  ),
                ),
                child: selected
                    ? const Icon(Icons.check_rounded,
                        size: 14, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: AppTokens.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: AppTokens.titleSm(context),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      address,
                      style: AppTokens.body(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppTokens.s8),
              Material(
                color: AppTokens.surface2(context),
                borderRadius: AppTokens.radius8,
                child: InkWell(
                  borderRadius: AppTokens.radius8,
                  onTap: onEdit,
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Icon(
                      Icons.edit_outlined,
                      size: 16,
                      color: AppTokens.ink2(context),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
