// ignore_for_file: deprecated_member_use, library_private_types_in_public_api

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:provider/provider.dart';

import 'package:shusruta_lms/helpers/app_tokens.dart';
import 'package:shusruta_lms/helpers/colors.dart';
import 'package:shusruta_lms/modules/orders/store/order_store.dart';

/// Order-tracking screen opened from the "Track Order" button on the
/// Hardcopy / Ordered Books flow. Shows product details, a vertical
/// timeline of shipment activities from [OrderStore], and a summary
/// panel with estimated delivery.
///
/// Preserved public contract:
///   • `TrackOrderScreen({super.key, required this.orderId,
///     this.productName, this.productImage, this.bookType,
///     this.quantity})` constructor with five fields (orderId is
///     required non-null, the rest are optional).
///   • Static `route(RouteSettings)` factory reading the 5-key args
///     map `{orderId, productName, productImage, bookType, quantity}`
///     with the `orderId: arguments['orderId'] ?? ''` fallback
///     preserved byte-for-byte, and returning a `CupertinoPageRoute`.
///   • MobX wiring: `Provider.of<OrderStore>(context, listen: false)`
///     captured in initState, `trackOrder(widget.orderId, "", context)`
///     called on mount. The `Observer` rebuild reads `isLoading`,
///     `error`, `hasShipmentDetails`, `currentStatus`,
///     `shipmentActivities`, `estimatedDeliveryDate`.
///   • Retry button re-invokes `_fetchOrderTracking()` which calls
///     `trackOrder` with the same parameters.
///   • Fallback product image URL `"https://picsum.photos/200"`,
///     fallback product name `"Surgery notes Powerhouse"`, fallback
///     book type `"Book Type 1"`, fallback quantity `1` preserved.
class TrackOrderScreen extends StatefulWidget {
  final String orderId;
  final String? productName;
  final String? productImage;
  final String? bookType;
  final int? quantity;

  const TrackOrderScreen({
    super.key,
    required this.orderId,
    this.productName,
    this.productImage,
    this.bookType,
    this.quantity,
  });

  static Route<dynamic> route(RouteSettings routeSettings) {
    final arguments = routeSettings.arguments as Map<String, dynamic>;
    return CupertinoPageRoute(
      builder: (_) => TrackOrderScreen(
        orderId: arguments['orderId'] ?? '',
        productName: arguments['productName'],
        productImage: arguments['productImage'],
        bookType: arguments['bookType'],
        quantity: arguments['quantity'],
      ),
    );
  }

  @override
  State<TrackOrderScreen> createState() => _TrackOrderScreenState();
}

class _TrackOrderScreenState extends State<TrackOrderScreen> {
  late OrderStore _orderStore;

  @override
  void initState() {
    super.initState();
    _orderStore = Provider.of<OrderStore>(context, listen: false);
    _fetchOrderTracking();
  }

  Future<void> _fetchOrderTracking() async {
    await _orderStore.trackOrder(widget.orderId, "", context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTokens.scaffold(context),
      body: Column(
        children: [
          const _HeroHeader(),
          Expanded(
            child: Observer(
              builder: (_) {
                if (_orderStore.isLoading) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: AppTokens.accent(context),
                    ),
                  );
                }
                if (_orderStore.error != null) {
                  return _ErrorState(
                    message: _orderStore.error!,
                    onRetry: _fetchOrderTracking,
                  );
                }
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(AppTokens.s16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _ProductCard(
                        productName: widget.productName,
                        productImage: widget.productImage,
                        bookType: widget.bookType,
                        quantity: widget.quantity,
                      ),
                      const SizedBox(height: AppTokens.s16),
                      _OrderStatusCard(
                        orderId: widget.orderId,
                        activities: _orderStore.shipmentActivities,
                      ),
                      const SizedBox(height: AppTokens.s16),
                      _ShipmentInfoCard(
                        hasShipmentDetails: _orderStore.hasShipmentDetails,
                        currentStatus: _orderStore.currentStatus,
                        orderId: widget.orderId,
                        lastUpdate: _orderStore.shipmentActivities.isNotEmpty
                            ? _orderStore.shipmentActivities.first.date
                            : "Not available",
                        estimatedDelivery: _orderStore.estimatedDeliveryDate,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
// Presentational widgets — private, purely visual.
// ══════════════════════════════════════════════════════════════════════

class _HeroHeader extends StatelessWidget {
  const _HeroHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTokens.brand, AppTokens.brand2],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.only(
            left: AppTokens.s8,
            right: AppTokens.s20,
            top: AppTokens.s8,
            bottom: AppTokens.s20,
          ),
          child: Row(
            children: [
              IconButton(
                highlightColor: Colors.transparent,
                hoverColor: Colors.transparent,
                onPressed: () => Navigator.pop(context),
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: AppColors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppTokens.s8),
              Text(
                "Track Order",
                style: AppTokens.titleSm(context).copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppTokens.s24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: AppTokens.s32 + AppTokens.s32,
              width: AppTokens.s32 + AppTokens.s32,
              decoration: BoxDecoration(
                color: AppTokens.dangerSoft(context),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                color: AppTokens.danger(context),
                size: 32,
              ),
            ),
            const SizedBox(height: AppTokens.s16),
            Text(
              'Error loading tracking data',
              style: AppTokens.titleSm(context).copyWith(
                fontWeight: FontWeight.w700,
                color: AppTokens.ink(context),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTokens.s8),
            Text(
              message,
              style: AppTokens.body(context).copyWith(
                color: AppTokens.muted(context),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTokens.s16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTokens.accent(context),
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTokens.s24,
                  vertical: AppTokens.s12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTokens.r12),
                ),
              ),
              onPressed: onRetry,
              child: Text(
                'Retry',
                style: AppTokens.body(context).copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardShell extends StatelessWidget {
  const _CardShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTokens.s16),
      decoration: BoxDecoration(
        color: AppTokens.surface(context),
        borderRadius: BorderRadius.circular(AppTokens.r16),
        border: Border.all(color: AppTokens.border(context)),
        boxShadow: AppTokens.shadow1(context),
      ),
      child: child,
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.productName,
    required this.productImage,
    required this.bookType,
    required this.quantity,
  });

  final String? productName;
  final String? productImage;
  final String? bookType;
  final int? quantity;

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTokens.r12),
            child: Image.network(
              productImage ?? "https://picsum.photos/200",
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 80,
                height: 80,
                color: AppTokens.surface2(context),
                child: Icon(
                  Icons.image_not_supported_rounded,
                  color: AppTokens.muted(context),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppTokens.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  productName ?? "Surgery notes Powerhouse",
                  style: AppTokens.body(context).copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTokens.ink(context),
                  ),
                ),
                const SizedBox(height: AppTokens.s4),
                Text(
                  bookType ?? "Book Type 1",
                  style: AppTokens.caption(context).copyWith(
                    color: AppTokens.muted(context),
                  ),
                ),
                const SizedBox(height: AppTokens.s4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTokens.s8,
                    vertical: AppTokens.s4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTokens.accentSoft(context),
                    borderRadius: BorderRadius.circular(AppTokens.r8),
                  ),
                  child: Text(
                    "Qty: ${quantity ?? 1}",
                    style: AppTokens.caption(context).copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTokens.accent(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderStatusCard extends StatelessWidget {
  const _OrderStatusCard({
    required this.orderId,
    required this.activities,
  });

  final String orderId;
  final List<dynamic> activities;

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.local_shipping_outlined,
                color: AppTokens.muted(context),
                size: 20,
              ),
              const SizedBox(width: AppTokens.s8),
              Text(
                "My Order",
                style: AppTokens.caption(context).copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTokens.muted(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.s12),
          Text(
            "Your Hardcopy order",
            style: AppTokens.titleSm(context).copyWith(
              fontWeight: FontWeight.w700,
              color: AppTokens.ink(context),
            ),
          ),
          const SizedBox(height: AppTokens.s4),
          Text(
            "Order ID : $orderId",
            style: AppTokens.caption(context).copyWith(
              color: AppTokens.muted(context),
            ),
          ),
          const SizedBox(height: AppTokens.s20),
          _TrackingTimeline(activities: activities),
        ],
      ),
    );
  }
}

class _TrackingTimeline extends StatelessWidget {
  const _TrackingTimeline({required this.activities});

  final List<dynamic> activities;

  @override
  Widget build(BuildContext context) {
    if (activities.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppTokens.s16),
        child: Text(
          "No tracking information available",
          style: AppTokens.body(context).copyWith(
            color: AppTokens.muted(context),
          ),
        ),
      );
    }
    return Column(
      children: List.generate(
        activities.length,
        (index) => _OrderStep(
          title: activities[index].srStatusLabel,
          subtitle:
              "${activities[index].date}\n${activities[index].activity}",
          isCompleted: true,
          isLast: index == activities.length - 1,
        ),
      ),
    );
  }
}

class _OrderStep extends StatelessWidget {
  const _OrderStep({
    required this.title,
    required this.subtitle,
    required this.isCompleted,
    this.isLast = false,
  });

  final String title;
  final String subtitle;
  final bool isCompleted;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final dotColor = isCompleted
        ? AppTokens.accent(context)
        : AppTokens.surface(context);
    final borderColor = isCompleted
        ? AppTokens.accent(context)
        : AppTokens.border(context);
    final railColor = isCompleted
        ? AppTokens.accent(context)
        : AppTokens.border(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: dotColor,
                border: Border.all(color: borderColor, width: 2),
              ),
              child: isCompleted
                  ? const Icon(
                      Icons.check_rounded,
                      color: AppColors.white,
                      size: 14,
                    )
                  : null,
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: railColor,
                margin: const EdgeInsets.symmetric(vertical: AppTokens.s4),
              ),
          ],
        ),
        const SizedBox(width: AppTokens.s12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTokens.body(context).copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTokens.ink(context),
                ),
              ),
              const SizedBox(height: AppTokens.s4),
              Text(
                subtitle,
                style: AppTokens.caption(context).copyWith(
                  color: AppTokens.muted(context),
                ),
              ),
              SizedBox(height: isLast ? 0 : AppTokens.s24),
            ],
          ),
        ),
      ],
    );
  }
}

class _ShipmentInfoCard extends StatelessWidget {
  const _ShipmentInfoCard({
    required this.hasShipmentDetails,
    required this.currentStatus,
    required this.orderId,
    required this.lastUpdate,
    required this.estimatedDelivery,
  });

  final bool hasShipmentDetails;
  final String currentStatus;
  final String orderId;
  final String lastUpdate;
  final String estimatedDelivery;

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Shipment Information",
            style: AppTokens.titleSm(context).copyWith(
              fontWeight: FontWeight.w700,
              color: AppTokens.ink(context),
            ),
          ),
          const SizedBox(height: AppTokens.s12),
          if (hasShipmentDetails) ...[
            _InfoRow(label: "Status", value: currentStatus),
            const SizedBox(height: AppTokens.s8),
            _InfoRow(label: "Order ID", value: orderId),
            const SizedBox(height: AppTokens.s8),
            _InfoRow(label: "Last Update", value: lastUpdate),
            const SizedBox(height: AppTokens.s8),
            _InfoRow(label: "Estimated Delivery", value: estimatedDelivery),
          ] else ...[
            Text(
              "Shipment details not available",
              style: AppTokens.body(context).copyWith(
                color: AppTokens.muted(context),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTokens.caption(context).copyWith(
            color: AppTokens.muted(context),
          ),
        ),
        const SizedBox(width: AppTokens.s8),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: AppTokens.caption(context).copyWith(
              fontWeight: FontWeight.w700,
              color: AppTokens.ink(context),
            ),
          ),
        ),
      ],
    );
  }
}
