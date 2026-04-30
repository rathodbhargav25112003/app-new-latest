// ignore_for_file: deprecated_member_use, unused_import, unnecessary_import, library_private_types_in_public_api, use_build_context_synchronously, use_super_parameters

import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/routes.dart';
import '../../helpers/app_tokens.dart';
import '../../helpers/colors.dart';
import '../../helpers/dimensions.dart';
import '../../helpers/styles.dart';
import 'model/delivery_service_model.dart';
import 'new_add_address.dart';
import 'store/new_subscription_store.dart';

/// SelectDeliveryType — courier picker shown once serviceability returns
/// one or more [DeliveryServiceModel] entries for the given pincode. On
/// Proceed/Confirm the chosen service is written into
/// [NewSubscriptionStore.setSelectedDeliveryService] and the user is
/// either returned to checkout (if an address is already selected) or
/// routed onward to [NewAddAddress].
///
/// Public surface preserved exactly:
///   • class [SelectDeliveryType] + const constructor
///     `{super.key, required deliveryServices, required pincode}`
///   • static [route] factory reading
///     `arguments['deliveryServices']`, `arguments['pincode']`
///   • MobX: `_store.setPincode`, `_store.setSelectedDeliveryService`,
///     observable `selectedAddress`
///   • Public class [CourierOptionCard] + const constructor
///     `{Key? key, required title, icon, bgColor, isSelected, service, onChanged}`
class SelectDeliveryType extends StatefulWidget {
  final List<DeliveryServiceModel> deliveryServices;
  final String pincode;

  const SelectDeliveryType({
    super.key,
    required this.deliveryServices,
    required this.pincode,
  });

  @override
  State<SelectDeliveryType> createState() => _SelectDeliveryTypeState();

  static Route<dynamic> route(RouteSettings routeSettings) {
    final args = routeSettings.arguments as Map<String, dynamic>?;

    return CupertinoPageRoute(
      builder: (_) => MultiProvider(
        providers: [
          Provider<NewSubscriptionStore>(
            create: (_) => NewSubscriptionStore(),
          ),
        ],
        child: SelectDeliveryType(
          deliveryServices: args?['deliveryServices'] ?? [],
          pincode: args?['pincode'] ?? '',
        ),
      ),
    );
  }
}

class _SelectDeliveryTypeState extends State<SelectDeliveryType> {
  DeliveryServiceModel? selectedDeliveryService;
  late NewSubscriptionStore _store;

  @override
  void initState() {
    super.initState();
    if (widget.deliveryServices.isNotEmpty) {
      selectedDeliveryService = widget.deliveryServices.first;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _store = Provider.of<NewSubscriptionStore>(context);

    // Make sure the pincode is set in the store
    if (_store.pincode != widget.pincode) {
      _store.setPincode(widget.pincode);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Add a navigation helper method
    void navigateToAddAddress() {
      // Ensure the pincode is set in the store
      _store.setPincode(widget.pincode);

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => Provider<NewSubscriptionStore>.value(
            value: _store,
            child: const NewAddAddress(),
          ),
        ),
      );
    }

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
                  const SizedBox(width: 12),
                  Text(
                    "Choose Delivery Type",
                    style: AppTokens.titleMd(context).copyWith(
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            // Rounded content panel
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppTokens.scaffold(context),
                  borderRadius: (Platform.isWindows || Platform.isMacOS)
                      ? null
                      : const BorderRadius.only(
                          topLeft: Radius.circular(AppTokens.r28),
                          topRight: Radius.circular(AppTokens.r28),
                        ),
                ),
                child: Column(
                  children: [
                    // Scrollable delivery options list
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Dimensions.PADDING_SIZE_DEFAULT,
                          vertical: Dimensions.PADDING_SIZE_DEFAULT,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(6, 6, 6, 14),
                              child: Text(
                                "Pick how you'd like your order shipped",
                                style: AppTokens.caption(context).copyWith(
                                  color: AppTokens.muted(context),
                                ),
                              ),
                            ),
                            ...widget.deliveryServices.map((service) {
                              return CourierOptionCard(
                                title: service.courierName,
                                icon: _getCourierIcon(service.courierName),
                                bgColor:
                                    _getCourierColor(service.courierName),
                                isSelected:
                                    selectedDeliveryService == service,
                                service: service,
                                onChanged: () {
                                  setState(() {
                                    selectedDeliveryService = service;
                                  });
                                },
                              );
                            }),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),

                    // Fixed proceed button at bottom
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppTokens.surface(context),
                        border: Border(
                          top: BorderSide(color: AppTokens.border(context)),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 10,
                            offset: const Offset(0, -4),
                          ),
                        ],
                      ),
                      child: SafeArea(
                        top: false,
                        child: _ProceedCta(
                          label: _store.selectedAddress != null
                              ? "Confirm"
                              : "Proceed",
                          enabled: selectedDeliveryService != null,
                          onTap: selectedDeliveryService != null
                              ? () {
                                  // Save selected delivery service
                                  _store.setSelectedDeliveryService(
                                      selectedDeliveryService!);

                                  // Check if we already have an address selected
                                  if (_store.selectedAddress != null) {
                                    // If address is already selected, just go back to checkout page
                                    Navigator.pop(context);
                                  } else {
                                    // Otherwise, navigate to add address screen
                                    navigateToAddAddress();
                                  }
                                }
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCourierIcon(String courierName) {
    if (courierName.toLowerCase().contains('amazon')) {
      return Icons.local_shipping;
    } else if (courierName.toLowerCase().contains('ekart')) {
      return Icons.motorcycle;
    } else if (courierName.toLowerCase().contains('delhivery')) {
      return Icons.fire_truck;
    } else if (courierName.toLowerCase().contains('dtdc')) {
      return Icons.flight;
    }

    // Default icon
    return Icons.local_shipping;
  }

  Color _getCourierColor(String courierName) {
    if (courierName.toLowerCase().contains('amazon')) {
      return Colors.amber[100]!;
    } else if (courierName.toLowerCase().contains('ekart')) {
      return Colors.blue[100]!;
    } else if (courierName.toLowerCase().contains('delhivery')) {
      return Colors.red[100]!;
    } else if (courierName.toLowerCase().contains('dtdc')) {
      return Colors.green[100]!;
    }

    // Default color
    return Colors.orange[100]!;
  }
}

class CourierOptionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color bgColor;
  final bool isSelected;
  final DeliveryServiceModel service;
  final VoidCallback onChanged;

  const CourierOptionCard({
    Key? key,
    required this.title,
    required this.icon,
    required this.bgColor,
    required this.isSelected,
    required this.service,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTokens.r16),
          onTap: onChanged,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.all(AppTokens.s16),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTokens.accentSoft(context)
                  : AppTokens.surface(context),
              borderRadius: BorderRadius.circular(AppTokens.r16),
              border: Border.all(
                color:
                    isSelected ? AppTokens.brand : AppTokens.border(context),
                width: isSelected ? 1.6 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppTokens.brand.withOpacity(0.12),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(AppTokens.r12),
                      ),
                      padding: const EdgeInsets.all(10),
                      child: Icon(icon, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        title,
                        style: AppTokens.body(context).copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppTokens.ink(context),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.visible,
                      ),
                    ),
                    Radio(
                      value: true,
                      groupValue: isSelected,
                      onChanged: (_) => onChanged(),
                      activeColor: AppTokens.brand,
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize:
                          MaterialTapTargetSize.shrinkWrap,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Divider(
                  height: 1,
                  color: AppTokens.border(context),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      flex: 6,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Est. delivery on",
                            style: AppTokens.caption(context).copyWith(
                              color: AppTokens.muted(context),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            service.estimatedDeliveryDate,
                            style: AppTokens.body(context).copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppTokens.ink(context),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            "Charges",
                            style: AppTokens.caption(context).copyWith(
                              color: AppTokens.muted(context),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "\u20B9 ${service.rate.toStringAsFixed(2)}",
                            style: AppTokens.body(context).copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppTokens.ink(context),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
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
}

/// Brand-gradient "Proceed"/"Confirm" CTA; grayed out when [enabled] is false.
class _ProceedCta extends StatelessWidget {
  final String label;
  final bool enabled;
  final VoidCallback? onTap;
  const _ProceedCta({
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTokens.r12),
          onTap: enabled ? onTap : null,
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
              child: Text(
                label,
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
