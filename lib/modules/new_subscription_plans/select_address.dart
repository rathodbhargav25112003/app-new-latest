// ignore_for_file: deprecated_member_use, unused_import, unnecessary_import, library_private_types_in_public_api, use_build_context_synchronously

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:provider/provider.dart';
import 'package:shusruta_lms/helpers/colors.dart';
import 'package:shusruta_lms/helpers/dimensions.dart';
import 'package:shusruta_lms/helpers/styles.dart';
import 'package:shusruta_lms/modules/new_subscription_plans/new_add_address.dart';
import 'package:shusruta_lms/modules/new_subscription_plans/select_delivery_type.dart';
import 'package:shusruta_lms/modules/new_subscription_plans/store/new_subscription_store.dart';
import 'package:shusruta_lms/modules/widgets/bottom_toast.dart';

import '../../helpers/app_tokens.dart';
import 'model/pincode_address_model.dart';

/// SelectAddress — delivery-address picker for hardcopy orders. Loads
/// addresses bound to the given [pincode] from
/// [NewSubscriptionStore.getPincodeAddresses], lets the user tap one to
/// confirm serviceability, and routes forward to [SelectDeliveryType].
/// Provides a "+ Add New" shortcut that opens [NewAddAddress]; on success
/// the flow jumps straight to delivery selection.
///
/// Public surface preserved exactly:
///   • class [SelectAddress] + const constructor
///     `{super.key, required pincode, required books}`
///   • MobX calls: `_store.getPincodeAddresses`, `_store.selectAddress`,
///     `_store.checkServiceability`, observables
///     `pincodeAddresses / isPincodeAddressLoading / pincodeAddressError /
///     deliveryServices / selectedDeliveryService / bookDimensions`
///   • Navigation: [NewAddAddress] then (if true) [SelectDeliveryType],
///     each wrapped in `Provider<NewSubscriptionStore>.value`
///   • [_checkServiceability] recomputes dimensions from `books` exactly
///     the same way — unchanged numeric behaviour
class SelectAddress extends StatefulWidget {
  final String pincode;
  final List<Map<String, dynamic>> books;

  const SelectAddress({
    super.key,
    required this.pincode,
    required this.books,
  });

  @override
  State<SelectAddress> createState() => _SelectAddressState();
}

class _SelectAddressState extends State<SelectAddress> {
  late NewSubscriptionStore _store;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAddresses();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _store = Provider.of<NewSubscriptionStore>(context);
  }

  void _loadAddresses() async {
    await _store.getPincodeAddresses(widget.pincode);
  }

  void _navigateToAddAddress() {
    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (context) => Provider<NewSubscriptionStore>.value(
          value: _store,
          child: NewAddAddress(pincode: widget.pincode),
        ),
      ),
    )
        .then((result) {
      if (result == true) {
        _navigateToDeliveryType();
      }
    });
  }

  void _navigateToDeliveryType() {
    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (context) => Provider<NewSubscriptionStore>.value(
          value: _store,
          child: SelectDeliveryType(
            deliveryServices: _store.deliveryServices,
            pincode: _store.pincode,
          ),
        ),
      ),
    )
        .then((_) {
      // If delivery type has been selected, return to checkout page
      if (_store.selectedDeliveryService != null) {
        // Navigate back to checkout page (pop twice)
        Navigator.of(context).pop();
      }
    });
  }

  void _selectAddress(Map<String, dynamic> address) {
    _store.selectAddress(address);
    if (_store.deliveryServices.isNotEmpty) {
      _navigateToDeliveryType();
    } else {
      // If delivery services aren't loaded yet, check serviceability first
      _checkServiceability();
    }
  }

  Future<void> _checkServiceability() async {
    // Calculate book dimensions from actual book data
    double totalWeight = 0.0;
    double maxHeight = 0.0;
    double maxWidth = 0.0;
    double maxLength = 0.0;

    // Default values if no books are provided
    if (widget.books.isEmpty) {
      totalWeight = 2.0;
      maxHeight = 24.0;
      maxWidth = 16.0;
      maxLength = 4.0;
    } else {
      // Calculate dimensions from actual book data
      for (var bookData in widget.books) {
        // Get quantity for this book (default to 1 if not specified)
        int quantity = 1;
        if (bookData.containsKey('quantity')) {
          quantity = int.tryParse(bookData['quantity'].toString()) ?? 1;
        }

        // Get dimensions from book data, with fallback to defaults
        double height =
            double.tryParse(bookData['height']?.toString() ?? '') ?? 24.0;
        double width =
            double.tryParse(bookData['width']?.toString() ?? '') ?? 16.0;
        double length =
            double.tryParse(bookData['length']?.toString() ?? '') ?? 4.0;
        double weight =
            double.tryParse(bookData['weight']?.toString() ?? '') ?? 2.0;

        // Update maximums
        if (height > maxHeight) maxHeight = height;
        if (width > maxWidth) maxWidth = width;
        if (length > maxLength) maxLength = length;

        // Sum up weight for all books (including quantity)
        totalWeight += weight * quantity;
      }
    }

    Map<String, double> dimensions = {
      'height': maxHeight,
      'width': maxWidth,
      'length': maxLength,
      'weight': totalWeight
    };

    // Only use store dimensions if we don't have any books (for backward compatibility)
    if (widget.books.isEmpty && _store.bookDimensions.isNotEmpty) {
      dimensions = Map.from(_store.bookDimensions);
      totalWeight = _store.bookDimensions['weight'] ?? totalWeight;
    }

    await _store.checkServiceability(
      widget.pincode,
      totalWeight,
      height: dimensions['height'],
      width: dimensions['width'],
      length: dimensions['length'],
      breadth: dimensions['width'],
    );

    if (_store.deliveryServices.isNotEmpty) {
      _navigateToDeliveryType();
    } else {
      BottomToast.showBottomToastOverlay(
        context: context,
        errorMessage: "No delivery services available for this pincode",
        backgroundColor: Theme.of(context).colorScheme.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTabletOrDesktop = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      backgroundColor: AppTokens.scaffold(context),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTokens.brand, AppTokens.brand2],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            // Brand gradient hero header
            Padding(
              padding: (Platform.isWindows || Platform.isMacOS)
                  ? const EdgeInsets.symmetric(
                      vertical: Dimensions.PADDING_SIZE_LARGE * 1.2,
                      horizontal: Dimensions.PADDING_SIZE_LARGE * 1.2)
                  : const EdgeInsets.only(
                      top: Dimensions.PADDING_SIZE_LARGE * 2,
                      left: Dimensions.PADDING_SIZE_LARGE,
                      right: Dimensions.PADDING_SIZE_LARGE,
                      bottom: Dimensions.PADDING_SIZE_SMALL),
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
                  const SizedBox(width: Dimensions.PADDING_SIZE_DEFAULT),
                  Text(
                    "Select Address",
                    style: AppTokens.titleMd(context).copyWith(
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  _PillAction(
                    icon: Icons.add_rounded,
                    label: "Add New",
                    onTap: _navigateToAddAddress,
                  ),
                ],
              ),
            ),

            // Rounded content panel
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Dimensions.PADDING_SIZE_DEFAULT,
                  vertical: Dimensions.PADDING_SIZE_DEFAULT,
                ),
                decoration: BoxDecoration(
                  color: AppTokens.scaffold(context),
                  borderRadius: (Platform.isWindows || Platform.isMacOS)
                      ? null
                      : const BorderRadius.only(
                          topLeft: Radius.circular(AppTokens.r28),
                          topRight: Radius.circular(AppTokens.r28),
                        ),
                ),
                child: Observer(
                  builder: (_) {
                    if (_store.isPincodeAddressLoading) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppTokens.brand,
                        ),
                      );
                    }

                    if (_store.pincodeAddressError != null) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppTokens.dangerSoft(context),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.error_outline_rounded,
                                size: 36,
                                color: AppTokens.danger(context),
                              ),
                            ),
                            const SizedBox(height: AppTokens.s16),
                            Text(
                              "Error loading addresses",
                              style: AppTokens.titleSm(context).copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppTokens.ink(context),
                              ),
                            ),
                            const SizedBox(height: AppTokens.s8),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: AppTokens.s24),
                              child: Text(
                                _store.pincodeAddressError!,
                                style: AppTokens.caption(context).copyWith(
                                  color: AppTokens.muted(context),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: AppTokens.s20),
                            _RetryCta(onTap: _loadAddresses),
                          ],
                        ),
                      );
                    }

                    if (_store.pincodeAddresses.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: AppTokens.accentSoft(context),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.location_off_rounded,
                                size: 44,
                                color: AppTokens.accent(context),
                              ),
                            ),
                            const SizedBox(height: AppTokens.s20),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: AppTokens.s24),
                              child: Text(
                                "No addresses found for pincode ${widget.pincode}",
                                style: AppTokens.body(context).copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppTokens.ink(context),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: AppTokens.s24),
                            SizedBox(
                              width:
                                  isTabletOrDesktop ? 320 : double.infinity,
                              child: _PrimaryCta(
                                label: "Add New Address",
                                onTap: _navigateToAddAddress,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.only(top: 4, bottom: 24),
                      itemCount: _store.pincodeAddresses.length,
                      itemBuilder: (context, index) {
                        final address = _store.pincodeAddresses[index];
                        return _buildAddressCard(address);
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressCard(PincodeAddressModel address) {
    // Convert the model to a Map for easier handling in the store
    final addressMap = address.toJson();
    final bool selected = _store.selectedAddress?['_id'] == address.id;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTokens.r16),
          onTap: () => _selectAddress(addressMap),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.all(AppTokens.s16),
            decoration: BoxDecoration(
              color: selected
                  ? AppTokens.accentSoft(context)
                  : AppTokens.surface(context),
              borderRadius: BorderRadius.circular(AppTokens.r16),
              border: Border.all(
                color:
                    selected ? AppTokens.brand : AppTokens.border(context),
                width: selected ? 1.6 : 1,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: AppTokens.brand.withOpacity(0.12),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Radio<String?>(
                  value: address.id,
                  groupValue: _store.selectedAddress?['_id'],
                  onChanged: (_) => _selectAddress(addressMap),
                  activeColor: AppTokens.brand,
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize:
                      MaterialTapTargetSize.shrinkWrap,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        address.name ?? "Unknown Name",
                        style: AppTokens.body(context).copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppTokens.ink(context),
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (address.buildingNumber != null ||
                          address.landMark != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Text(
                            "${address.buildingNumber ?? ''} ${address.landMark ?? ''}"
                                .trim(),
                            style: AppTokens.caption(context).copyWith(
                              color: AppTokens.muted(context),
                            ),
                          ),
                        ),
                      if (address.address != null &&
                          address.address!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Text(
                            address.address!,
                            style: AppTokens.caption(context).copyWith(
                              color: AppTokens.muted(context),
                            ),
                          ),
                        ),
                      Text(
                        "${address.city ?? ''}, ${address.state ?? ''} - ${address.pincode ?? ''}",
                        style: AppTokens.caption(context).copyWith(
                          color: AppTokens.muted(context),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.phone_rounded,
                            size: 14,
                            color: AppTokens.muted(context),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "+91 ${address.phone ?? ''}",
                            style: AppTokens.caption(context).copyWith(
                              color: AppTokens.muted(context),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Pill-shaped "+ Add New" action placed in the gradient header.
class _PillAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _PillAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Ink(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
            border:
                Border.all(color: Colors.white.withOpacity(0.22)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 16),
              const SizedBox(width: 4),
              Text(
                label,
                style: AppTokens.caption(context).copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Brand-gradient primary CTA used in empty/add state.
class _PrimaryCta extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _PrimaryCta({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTokens.r12),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTokens.brand, AppTokens.brand2],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppTokens.r12),
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

/// Compact "Retry" CTA used in the error state.
class _RetryCta extends StatelessWidget {
  final VoidCallback onTap;
  const _RetryCta({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTokens.r12),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(
              horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTokens.brand, AppTokens.brand2],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppTokens.r12),
          ),
          child: Text(
            "Retry",
            style: AppTokens.body(context).copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
