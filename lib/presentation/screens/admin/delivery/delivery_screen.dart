import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:stleaf_trading/core/theme/app_colors.dart';
import 'package:stleaf_trading/providers/app_providers.dart';
import 'package:stleaf_trading/data/models/order_model.dart';
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
      context.read<CustomerProvider>().loadCustomers();
    });
  }

  List<OrderModel> _filterItems(String column, List<OrderModel> deliveries) {
    if (column == 'Pending / Packed') {
      return deliveries.where((d) => d.orderStatus == 'Pending' || d.orderStatus == 'Confirmed' || d.orderStatus == 'Packed').toList();
    }
    return deliveries.where((d) => d.orderStatus == column).toList();
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
                  Text('Track all delivery orders', style: const TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(height: 24),

                  // Stats
                  Row(children: [
                    for (final s in ['Pending / Packed', 'Out For Delivery', 'Delivered'])
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: StatCard(
                            title: s,
                            value: '${_filterItems(s, provider.deliveries).length}',
                            icon: _icon(s),
                            color: _color(s),
                          ),
                        ),
                      ),
                  ]),
                  const SizedBox(height: 28),

                  ...['Pending / Packed', 'Out For Delivery', 'Delivered'].map((status) {
                    final items = _filterItems(status, provider.deliveries);
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
                        ...items.map((d) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _DeliveryCard(order: d),
                        )),
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
      case 'Pending / Packed': return Icons.inventory_rounded;
      case 'Out For Delivery': return Icons.local_shipping_rounded;
      case 'Delivered': return Icons.check_circle_rounded;
      default: return Icons.cancel_rounded;
    }
  }

  Color _color(String status) {
    switch (status) {
      case 'Pending / Packed': return AppColors.warning;
      case 'Out For Delivery': return const Color(0xFF7B1FA2);
      case 'Delivered': return AppColors.success;
      default: return AppColors.danger;
    }
  }
}

class _DeliveryCard extends StatelessWidget {
  final OrderModel order;
  const _DeliveryCard({required this.order});

  @override
  Widget build(BuildContext context) {
    // Lookup customer to get company name and address
    final customers = context.watch<CustomerProvider>().customers;
    final custIdx = customers.indexWhere((c) => c.id == order.customerId);
    final customer = custIdx >= 0 ? customers[custIdx] : null;

    final companyName = customer?.companyName ?? order.customerName ?? 'Unknown Customer';
    final address = customer?.address ?? 'No Address Provided';

    final products = context.watch<ProductProvider>().products;

    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(order.orderId, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              StatusBadge(status: order.orderStatus),
            ],
          ),
          const Divider(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left column: Company info
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Delivery Address', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.primary)),
                    const SizedBox(height: 6),
                    Text(companyName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text(address, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(Icons.person_rounded, size: 14, color: AppColors.textMuted),
                        const SizedBox(width: 6),
                        Text(customer?.contactPerson ?? 'Unknown', style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
                        const SizedBox(width: 16),
                        const Icon(Icons.phone_rounded, size: 14, color: AppColors.textMuted),
                        const SizedBox(width: 6),
                        Text(customer?.phoneNumber ?? 'Unknown', style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Right column: Order items
              Expanded(
                flex: 3,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppColors.mint, borderRadius: BorderRadius.circular(8)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Items Ordered', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.primary)),
                      const SizedBox(height: 8),
                      ...order.items.map((i) {
                        final pIdx = products.indexWhere((p) => p.id == i.productId);
                        final pData = pIdx >= 0 ? products[pIdx] : null;

                        final name = i.product?.name ?? (i.productName == 'Unknown' && pData != null ? pData.name : (i.productName == 'Unknown' ? 'Item' : i.productName));
                        final code = i.product?.itemCode ?? (i.itemCode.isEmpty && pData != null ? pData.itemCode : i.itemCode);
                        final unit = i.product?.packType ?? (i.packType == 'kg' && pData != null ? pData.packType : i.packType);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(child: Text('• $name ($code)', style: const TextStyle(fontSize: 13))),
                                  Text('${i.quantity} $unit', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                ],
                              ),
                              if (i.remarks != null && i.remarks!.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4, left: 12),
                                  child: Text('Note: ${i.remarks}', style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppColors.warning)),
                                ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ],
          ),
          
          if (order.orderStatus == 'Out For Delivery') ...[
            const SizedBox(height: 20),
            AppButton(
              label: 'Mark as Delivered',
              icon: Icons.done_all_rounded,
              width: double.infinity,
              onPressed: () {
                context.read<DeliveryProvider>().updateStatus(order.id, 'Delivered');
              },
            ),
          ] else if (order.orderStatus == 'Delivered') ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.successLight,
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20),
                  SizedBox(width: 8),
                  Text('Successfully Delivered', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
