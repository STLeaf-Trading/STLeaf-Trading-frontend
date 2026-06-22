import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:stleaf_trading/core/theme/app_colors.dart';
import 'package:stleaf_trading/core/constants/app_constants.dart';
import 'package:stleaf_trading/data/models/order_model.dart';
import 'package:stleaf_trading/providers/app_providers.dart';
import 'package:stleaf_trading/providers/auth_provider.dart';
import 'package:stleaf_trading/presentation/widgets/common/common_widgets.dart';
import 'package:stleaf_trading/presentation/widgets/layout/customer_layout.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      context.read<OrderProvider>().loadOrders(customerId: auth.currentUser?.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OrderProvider>();
    final formatter = NumberFormat.currency(symbol: 'RM ', decimalDigits: 2);

    return CustomerLayout(
      currentRoute: '/shop/orders',
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(children: [
              Text('My Orders', style: Theme.of(context).textTheme.headlineLarge),
            ]),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: ['All', ...AppConstants.orderStatuses].map((s) {
                final isSelected = provider.statusFilter == s;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(s, style: const TextStyle(fontSize: 12)),
                    selected: isSelected,
                    onSelected: (_) => provider.setStatusFilter(s),
                    selectedColor: AppColors.mint,
                    checkmarkColor: AppColors.primary,
                    side: BorderSide(color: isSelected ? AppColors.primary : AppColors.border),
                    labelStyle: TextStyle(
                      color: isSelected ? AppColors.primary : AppColors.textSecondary,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: provider.isLoading
                ? const LoadingWidget()
                : provider.orders.isEmpty
                    ? EmptyState(
                        title: 'No orders yet',
                        subtitle: 'Start shopping to place your first order.',
                        icon: Icons.receipt_long_outlined,
                        action: AppButton(label: 'Shop Now', onPressed: () => context.go('/shop')),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: provider.orders.length,
                        itemBuilder: (ctx, i) => _OrderCard(
                          order: provider.orders[i],
                          formatter: formatter,
                          onTap: () => context.go('/shop/orders/${provider.orders[i].id}'),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final OrderModel order;
  final NumberFormat formatter;
  final VoidCallback onTap;
  const _OrderCard({required this.order, required this.formatter, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(order.orderStatus);
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: AppColors.mint, borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.receipt_long_rounded, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(order.orderId, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              Text(DateFormat('d MMM yyyy').format(order.orderDate),
                style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
            ])),
            Text(formatter.format(order.totalAmount),
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.primary)),
          ]),
          const SizedBox(height: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (order.paymentMethod == 'Instalment')
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: const Color(0xFFE1BEE7), borderRadius: BorderRadius.circular(4)),
                    child: const Text('INSTALMENT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF6A1B9A))),
                  )
                else
                  const SizedBox(),
                StatusBadge(status: order.orderStatus),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _statusProgress(order.orderStatus),
                minHeight: 5,
                backgroundColor: AppColors.border,
                color: statusColor,
              ),
            ),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            const Icon(Icons.local_shipping_outlined, size: 13, color: AppColors.textMuted),
            const SizedBox(width: 4),
            Text('Deliver: ${DateFormat('d MMM yyyy').format(order.deliveryDate)}',
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
            const Spacer(),
            const Text('View Details ›', style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600)),
          ]),
        ],
      ),
    );
  }

  double _statusProgress(String status) {
    const steps = ['Pending', 'Confirmed', 'Packed', 'Out For Delivery', 'Delivered'];
    final idx = steps.indexOf(status);
    return idx < 0 ? 0 : (idx + 1) / steps.length;
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Delivered': return AppColors.success;
      case 'Out For Delivery': return const Color(0xFF7B1FA2);
      case 'Packed': return AppColors.info;
      case 'Confirmed': return AppColors.primaryLight;
      case 'Cancelled': return AppColors.danger;
      default: return AppColors.pending;
    }
  }
}

// ─── Order Detail ──────────────────────────────────────────────
class OrderDetailScreen extends StatefulWidget {
  final String orderId;
  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<OrderProvider>();
      final auth = context.read<AuthProvider>();
      if (provider.allOrders.isEmpty && auth.currentUser != null) {
        provider.loadOrders(customerId: auth.currentUser!.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OrderProvider>();
    final orders = provider.allOrders;
    final formatter = NumberFormat.currency(symbol: 'RM ', decimalDigits: 2);
    final order = orders.isNotEmpty
        ? orders.firstWhere((o) => o.id == widget.orderId, orElse: () => orders.first)
        : null;

    if (order == null || provider.isLoading) return CustomerLayout(currentRoute: '/shop/orders', child: const LoadingWidget());

    final statusSteps = ['Pending', 'Confirmed', 'Packed', 'Out For Delivery', 'Delivered'];
    final currentIdx = order.orderStatus == 'Cancelled' ? -1 : statusSteps.indexOf(order.orderStatus);

    return CustomerLayout(
      currentRoute: '/shop/orders',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              IconButton(
                onPressed: () => context.go('/shop/orders'),
                icon: const Icon(Icons.arrow_back_rounded),
                style: IconButton.styleFrom(backgroundColor: AppColors.mint, foregroundColor: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Text(order.orderId, style: Theme.of(context).textTheme.headlineMedium),
            ]),
            const SizedBox(height: 20),

            // Status tracker
            AppCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Delivery Status', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 20),
                if (order.orderStatus == 'Cancelled')
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: AppColors.dangerLight, borderRadius: BorderRadius.circular(10)),
                    child: const Row(children: [
                      Icon(Icons.cancel_rounded, color: AppColors.danger),
                      SizedBox(width: 8),
                      Text('Order Cancelled', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w700)),
                    ]),
                  )
                else
                  Column(
                    children: statusSteps.asMap().entries.map((e) {
                      final isDone = e.key <= currentIdx;
                      final isCurrent = e.key == currentIdx;
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(children: [
                            Container(
                              width: 28, height: 28,
                              decoration: BoxDecoration(
                                color: isDone ? AppColors.primary : AppColors.border,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(isDone ? Icons.check_rounded : Icons.circle_outlined, size: 14, color: AppColors.white),
                            ),
                            if (e.key < statusSteps.length - 1)
                              Container(width: 2, height: 30, color: isDone && e.key < currentIdx ? AppColors.primary : AppColors.border),
                          ]),
                          const SizedBox(width: 14),
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(e.value, style: TextStyle(
                              fontSize: 14,
                              fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w400,
                              color: isDone ? AppColors.primary : AppColors.textMuted,
                            )),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
              ]),
            ),
            const SizedBox(height: 16),

            // Delivery Address
            if (order.deliveryAddress != null && order.deliveryAddress != 'Pickup') ...[
              AppCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Row(children: [
                    Icon(Icons.location_on_outlined, color: AppColors.primary, size: 18),
                    SizedBox(width: 8),
                    Text('Delivery Address', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  ]),
                  const SizedBox(height: 8),
                  Text(order.deliveryAddress!, style: const TextStyle(fontSize: 13)),
                ]),
              ),
              const SizedBox(height: 16),
            ],

            // Customer comment (visible to customer)
            if (order.customerComment != null && order.customerComment!.isNotEmpty) ...[
              AppCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Row(children: [
                    Icon(Icons.chat_bubble_outline_rounded, color: AppColors.info, size: 18),
                    SizedBox(width: 8),
                    Text('Your Order Notes', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.info)),
                  ]),
                  const SizedBox(height: 8),
                  Text(order.customerComment!, style: const TextStyle(fontSize: 13)),
                ]),
              ),
              const SizedBox(height: 16),
            ],

            // Items
            AppCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Items (${order.items.length})', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 12),
                ...order.items.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(children: [
                    const Icon(Icons.eco_rounded, color: AppColors.primary, size: 16),
                    const SizedBox(width: 10),
                    Expanded(child: Text(
                      '${item.productName} × ${item.quantity == item.quantity.truncate() ? item.quantity.toInt() : item.quantity.toStringAsFixed(2)} ${item.packType}',
                    )),
                    Text(formatter.format(item.subtotal), style: const TextStyle(fontWeight: FontWeight.w700)),
                  ]),
                )),
                const Divider(height: 24),
                _summaryRow('Subtotal', formatter.format(order.subtotal)),
                _summaryRow('Delivery', formatter.format(order.deliveryFee)),
                const Divider(height: 16),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Text('Total', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  Text(formatter.format(order.totalAmount),
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.primary)),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  Text('Payment Method: ${order.paymentMethod}', style: const TextStyle(fontSize: 13, color: AppColors.textMuted, fontWeight: FontWeight.w500)),
                ]),
                if (order.orderStatus == 'Cancelled' && order.cancellationReason != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.dangerLight,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.danger.withOpacity(0.2)),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Cancellation Reason', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.danger)),
                      const SizedBox(height: 4),
                      Text(order.cancellationReason!, style: const TextStyle(fontSize: 13)),
                    ]),
                  ),
                ],
              ]),
            ),

            // Instalment schedule button
            if (order.paymentMethod == 'Instalment') ...[
              const SizedBox(height: 16),
              AppButton(
                label: 'View Instalment Schedule',
                icon: Icons.calendar_month_rounded,
                isOutlined: true,
                width: double.infinity,
                onPressed: () => context.push('/shop/orders/${order.id}/instalment'),
              ),
            ],

            // Cancel button
            if (order.orderStatus == 'Pending' || order.orderStatus == 'Confirmed') ...[
              const SizedBox(height: 16),
              AppButton(
                label: 'Cancel Order',
                icon: Icons.cancel_outlined,
                isDanger: true,
                width: double.infinity,
                onPressed: () => context.push('/shop/orders/${order.id}/cancel'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ]),
    );
  }
}
