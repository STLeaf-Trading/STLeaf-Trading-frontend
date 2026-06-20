import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:stleaf_trading/core/theme/app_colors.dart';
import 'package:stleaf_trading/providers/app_providers.dart';
import 'package:stleaf_trading/data/models/inventory_model.dart';
import 'package:stleaf_trading/presentation/widgets/common/common_widgets.dart';
import 'package:stleaf_trading/presentation/widgets/layout/admin_layout.dart';

class DeliveryScreen extends StatefulWidget {
  const DeliveryScreen({super.key});

  @override
  State<DeliveryScreen> createState() => _DeliveryScreenState();
}

class _DeliveryScreenState extends State<DeliveryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DeliveryProvider>().loadDeliveries();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DeliveryProvider>();

    return AdminLayout(
      currentRoute: '/admin/delivery',
      child: provider.isLoading
          ? const LoadingWidget()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Delivery', style: Theme.of(context).textTheme.displaySmall),
                  Text('Track all deliveries', style: const TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(height: 24),

                  // Stats
                  Row(children: [
                    for (final s in ['Scheduled', 'Loading', 'In Transit', 'Delivered'])
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: StatCard(
                            title: s,
                            value: '${provider.deliveries.where((d) => d.status == s).length}',
                            icon: _icon(s),
                            color: _color(s),
                          ),
                        ),
                      ),
                  ]),
                  const SizedBox(height: 28),

                  ...['Scheduled', 'Loading', 'In Transit', 'Delivered', 'Failed'].map((status) {
                    final items = provider.deliveries.where((d) => d.status == status).toList();
                    if (items.isEmpty) return const SizedBox.shrink();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Container(width: 10, height: 10, decoration: BoxDecoration(color: _color(status), shape: BoxShape.circle)),
                          const SizedBox(width: 8),
                          Text(status, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _color(status))),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: _color(status).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                            child: Text('${items.length}', style: TextStyle(color: _color(status), fontWeight: FontWeight.w700, fontSize: 12)),
                          ),
                        ]),
                        const SizedBox(height: 12),
                        ...items.map((d) => _DeliveryCard(delivery: d)),
                        const SizedBox(height: 24),
                      ],
                    );
                  }),
                ],
              ),
            ),
    );
  }

  IconData _icon(String status) {
    switch (status) {
      case 'Scheduled': return Icons.schedule_rounded;
      case 'Loading': return Icons.inventory_rounded;
      case 'In Transit': return Icons.local_shipping_rounded;
      case 'Delivered': return Icons.check_circle_rounded;
      default: return Icons.cancel_rounded;
    }
  }

  Color _color(String status) {
    switch (status) {
      case 'Scheduled': return AppColors.info;
      case 'Loading': return AppColors.warning;
      case 'In Transit': return const Color(0xFF7B1FA2);
      case 'Delivered': return AppColors.success;
      default: return AppColors.danger;
    }
  }
}

class _DeliveryCard extends StatelessWidget {
  final DeliveryModel delivery;
  const _DeliveryCard({required this.delivery});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: AppColors.mint, borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.local_shipping_rounded, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(delivery.orderCode ?? '', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                Text(delivery.customerName ?? '', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                const SizedBox(height: 6),
                Row(children: [
                  const Icon(Icons.person_rounded, size: 13, color: AppColors.textMuted),
                  const SizedBox(width: 4),
                  Text(delivery.driverName, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  const SizedBox(width: 12),
                  const Icon(Icons.directions_car_rounded, size: 13, color: AppColors.textMuted),
                  const SizedBox(width: 4),
                  Text(delivery.vehicleNumber, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                ]),
              ],
            ),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(DateFormat('d MMM').format(delivery.deliveryDate),
              style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            StatusBadge(status: delivery.status),
          ]),
        ],
      ),
    );
  }
}
