import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:stleaf_trading/core/theme/app_colors.dart';
import 'package:stleaf_trading/core/constants/app_constants.dart';
import 'package:stleaf_trading/data/models/order_model.dart';
import 'package:stleaf_trading/providers/app_providers.dart';
import 'package:stleaf_trading/presentation/widgets/common/common_widgets.dart';
import 'package:stleaf_trading/presentation/widgets/layout/admin_layout.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderProvider>().loadOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OrderProvider>();
    final formatter = NumberFormat.currency(symbol: 'RM ', decimalDigits: 2);
    final allStatuses = ['All', ...AppConstants.orderStatuses];

    return AdminLayout(
      currentRoute: '/admin/orders',
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 28, 28, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Orders', style: Theme.of(context).textTheme.displaySmall),
                  Text('${provider.allOrders.length} total orders', style: const TextStyle(color: AppColors.textSecondary)),
                ]),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Status filter tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Row(
              children: allStatuses.map((s) {
                final isSelected = provider.statusFilter == s;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(s),
                    selected: isSelected,
                    onSelected: (_) => provider.setStatusFilter(s),
                    selectedColor: AppColors.mint,
                    checkmarkColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: isSelected ? AppColors.primary : AppColors.textSecondary,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                      fontSize: 13,
                    ),
                    side: BorderSide(color: isSelected ? AppColors.primary : AppColors.border),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: provider.isLoading
                ? const LoadingWidget()
                : provider.orders.isEmpty
                    ? const EmptyState(title: 'No orders found', icon: Icons.receipt_long_outlined)
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        itemCount: provider.orders.length,
                        itemBuilder: (ctx, i) => _OrderCard(
                          order: provider.orders[i], formatter: formatter,
                          onTap: () => context.go('/admin/orders/${provider.orders[i].id}'),
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
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(color: AppColors.mint, borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.receipt_long_rounded, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(order.orderId, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                    Text(order.customerName ?? '', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(formatter.format(order.totalAmount),
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.primary)),
                const SizedBox(height: 4),
                StatusBadge(status: order.orderStatus),
              ]),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
            ],
          ),
          const SizedBox(height: 12),
          Row(children: [
            _infoChip(Icons.calendar_today_rounded, DateFormat('d MMM yyyy').format(order.orderDate)),
            const SizedBox(width: 8),
            _infoChip(Icons.local_shipping_rounded, 'Deliver: ${DateFormat('d MMM').format(order.deliveryDate)}'),
            const SizedBox(width: 8),
            _infoChip(Icons.payment_rounded, order.paymentMethod),
            const Spacer(),
            if (order.paymentStatus != 'Pending')
              StatusBadge(status: order.paymentStatus),
          ]),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Row(children: [
      Icon(icon, size: 12, color: AppColors.textMuted),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
    ]);
  }
}

// ─── Order Detail ───────────────────────────────────────────────
class AdminOrderDetailScreen extends StatelessWidget {
  final String orderId;
  const AdminOrderDetailScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    final orders = context.watch<OrderProvider>().allOrders;
    final formatter = NumberFormat.currency(symbol: 'RM ', decimalDigits: 2);
    final order = orders.isNotEmpty
        ? orders.firstWhere((o) => o.id == orderId, orElse: () => orders.first)
        : null;

    if (order == null) return AdminLayout(currentRoute: '/admin/orders', child: const LoadingWidget());

    final statusSteps = AppConstants.orderStatuses.take(5).toList();

    return AdminLayout(
      currentRoute: '/admin/orders',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              IconButton(
                onPressed: () => context.go('/admin/orders'),
                icon: const Icon(Icons.arrow_back_rounded),
                style: IconButton.styleFrom(backgroundColor: AppColors.mint),
              ),
              const SizedBox(width: 16),
              Text(order.orderId, style: Theme.of(context).textTheme.displaySmall),
            ]),
            const SizedBox(height: 24),

            // Status stepper
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Order Status', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 20),
                  Row(
                    children: statusSteps.asMap().entries.map((e) {
                      final idx = e.key;
                      final step = e.value;
                      final currentIdx = statusSteps.indexOf(order.orderStatus);
                      final isDone = idx <= currentIdx;
                      final isCurrent = idx == currentIdx;
                      return Expanded(
                        child: Row(
                          children: [
                            Column(children: [
                              Container(
                                width: 32, height: 32,
                                decoration: BoxDecoration(
                                  color: isDone ? AppColors.primary : AppColors.border,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isDone ? Icons.check_rounded : Icons.circle_outlined,
                                  size: 16, color: AppColors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(step, style: TextStyle(
                                fontSize: 10, fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w400,
                                color: isDone ? AppColors.primary : AppColors.textMuted,
                              ), textAlign: TextAlign.center),
                            ]),
                            if (idx < statusSteps.length - 1)
                              Expanded(child: Container(height: 2, color: isDone && idx < currentIdx ? AppColors.primary : AppColors.border)),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            LayoutBuilder(builder: (ctx, constraints) {
              final isWide = constraints.maxWidth > 700;
              return isWide
                  ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Expanded(flex: 3, child: _OrderItemsCard(order: order, formatter: formatter)),
                      const SizedBox(width: 20),
                      Expanded(flex: 2, child: _OrderSummaryCard(order: order, formatter: formatter)),
                    ])
                  : Column(children: [
                      _OrderItemsCard(order: order, formatter: formatter),
                      const SizedBox(height: 20),
                      _OrderSummaryCard(order: order, formatter: formatter),
                    ]);
            }),
          ],
        ),
      ),
    );
  }
}

class _OrderItemsCard extends StatelessWidget {
  final OrderModel order;
  final NumberFormat formatter;
  const _OrderItemsCard({required this.order, required this.formatter});

  @override
  Widget build(BuildContext context) {
    final products = context.watch<ProductProvider>().products;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Order Items (${order.items.length})', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          ...order.items.map((item) {
            final pIdx = products.indexWhere((p) => p.id == item.productId);
            final pData = pIdx >= 0 ? products[pIdx] : null;

            final name = item.product?.name ?? (item.productName == 'Unknown' && pData != null ? pData.name : (item.productName == 'Unknown' ? 'Item' : item.productName));
            final code = item.product?.itemCode ?? (item.itemCode.isEmpty && pData != null ? pData.itemCode : item.itemCode);
            final unit = item.product?.packType ?? (item.packType == 'kg' && pData != null ? pData.packType : item.packType);

            return Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.divider))),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(color: AppColors.mint, borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.eco_rounded, color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('$name ($code)', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      const SizedBox(height: 2),
                      Text('${item.quantity} $unit x RM ${item.price.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                      if (item.remarks != null && item.remarks!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: AppColors.warningLight, borderRadius: BorderRadius.circular(6)),
                          child: Text('Note: ${item.remarks}', style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppColors.warning)),
                        ),
                      ],
                    ]),
                  ),
                  Text(formatter.format(item.subtotal), style: const TextStyle(fontWeight: FontWeight.w700)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _OrderSummaryCard extends StatelessWidget {
  final OrderModel order;
  final NumberFormat formatter;
  const _OrderSummaryCard({required this.order, required this.formatter});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Order Summary', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          _row('Customer', order.customerName ?? ''),
          _row('Order Date', DateFormat('d MMM yyyy').format(order.orderDate)),
          _row('Delivery Date', DateFormat('d MMM yyyy').format(order.deliveryDate)),
          _row('Payment Method', order.paymentMethod),
          const Divider(height: 24),
          _row('Subtotal', formatter.format(order.subtotal)),
          _row('Delivery Fee', formatter.format(order.deliveryFee)),
          const Divider(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Total', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            Text(formatter.format(order.totalAmount),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.primary)),
          ]),
          const SizedBox(height: 16),
          Row(children: [
            if (order.paymentStatus != 'Pending') ...[
              StatusBadge(status: order.paymentStatus),
              const SizedBox(width: 8),
            ],
            StatusBadge(status: order.orderStatus),
          ]),
          // Show cancellation reason if cancelled
          if (order.orderStatus == 'Cancelled' && order.cancellationReason != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.dangerLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Cancellation Reason', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.danger)),
                const SizedBox(height: 4),
                Text(order.cancellationReason!, style: const TextStyle(fontSize: 13)),
              ]),
            ),
          ],
          const SizedBox(height: 24),
          _buildActionButtons(context),
          // Admin cancel button (any stage except already cancelled)
          if (order.orderStatus != 'Cancelled' && order.orderStatus != 'Delivered') ...[
            const SizedBox(height: 12),
            AppButton(
              label: 'Cancel Order',
              icon: Icons.cancel_outlined,
              isDanger: true,
              width: double.infinity,
              onPressed: () async {
                final reasonCtrl = TextEditingController();
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    title: const Text('Cancel Order?', style: TextStyle(fontWeight: FontWeight.w700)),
                    content: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Text('Enter a reason for cancelling this order (admin):'),
                      const SizedBox(height: 12),
                      TextField(
                        controller: reasonCtrl,
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: 'Reason...',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ]),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Go Back')),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
                        child: const Text('Cancel Order', style: TextStyle(color: AppColors.white)),
                      ),
                    ],
                  ),
                );
                if (confirm == true && context.mounted) {
                  final reason = reasonCtrl.text.trim().isEmpty ? 'Cancelled by admin' : reasonCtrl.text.trim();
                  await context.read<OrderProvider>().cancelOrder(order.id, reason);
                }
                reasonCtrl.dispose();
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final provider = context.read<OrderProvider>();
    final isPickup = order.deliveryFee == 0;

    if (order.orderStatus == 'Pending') {
      return AppButton(
        label: 'Confirm Order',
        icon: Icons.check_circle_outline_rounded,
        width: double.infinity,
        onPressed: () => provider.updateStatus(order.id, 'Confirmed'),
      );
    }
    
    if (order.orderStatus == 'Confirmed') {
      return AppButton(
        label: 'Mark as Packed',
        icon: Icons.inventory_2_outlined,
        width: double.infinity,
        onPressed: () => provider.updateStatus(order.id, 'Packed'),
      );
    }
    
    if (order.orderStatus == 'Packed') {
      if (isPickup) {
        return AppButton(
          label: 'Picked Up / Delivered',
          icon: Icons.done_all_rounded,
          width: double.infinity,
          onPressed: () => provider.updateStatus(order.id, 'Delivered'),
        );
      } else {
        return AppButton(
          label: 'Out for Delivery',
          icon: Icons.local_shipping_outlined,
          width: double.infinity,
          onPressed: () => provider.updateStatus(order.id, 'Out For Delivery'),
        );
      }
    }
    
    if (order.orderStatus == 'Out For Delivery') {
      return AppButton(
        label: 'Mark as Delivered',
        icon: Icons.done_all_rounded,
        width: double.infinity,
        onPressed: () => provider.updateStatus(order.id, 'Delivered'),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
