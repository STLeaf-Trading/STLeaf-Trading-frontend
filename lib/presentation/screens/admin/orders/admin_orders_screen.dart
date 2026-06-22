import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:stleaf_trading/core/theme/app_colors.dart';
import 'package:stleaf_trading/core/constants/app_constants.dart';
import 'package:stleaf_trading/data/models/order_model.dart';
import 'package:stleaf_trading/data/models/instalment_model.dart';
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
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _infoChip(Icons.calendar_today_rounded, DateFormat('d MMM yyyy').format(order.orderDate)),
              _infoChip(Icons.local_shipping_rounded, 'Deliver: ${DateFormat('d MMM').format(order.deliveryDate)}'),
              _infoChip(Icons.payment_rounded, order.paymentMethod),
              if (order.paymentStatus != 'Pending')
                StatusBadge(status: order.paymentStatus),
            ],
          ),
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
class AdminOrderDetailScreen extends StatefulWidget {
  final String orderId;
  const AdminOrderDetailScreen({super.key, required this.orderId});

  @override
  State<AdminOrderDetailScreen> createState() => _AdminOrderDetailScreenState();
}

class _AdminOrderDetailScreenState extends State<AdminOrderDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<OrderProvider>();
      if (provider.allOrders.isEmpty) provider.loadOrders();
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

    if (order == null || provider.isLoading) return AdminLayout(currentRoute: '/admin/orders', child: const LoadingWidget());

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
                  LayoutBuilder(builder: (ctx, constraints) {
                    if (constraints.maxWidth < 500) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: statusSteps.asMap().entries.map((e) {
                          final idx = e.key;
                          final step = e.value;
                          final currentIdx = statusSteps.indexOf(order.orderStatus);
                          final isDone = idx <= currentIdx;
                          final isCurrent = idx == currentIdx;
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Column(
                                children: [
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
                                  if (idx < statusSteps.length - 1)
                                    Container(width: 2, height: 24, color: isDone && idx < currentIdx ? AppColors.primary : AppColors.border),
                                ],
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(step, style: TextStyle(
                                    fontSize: 14, fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                                    color: isDone ? AppColors.primary : AppColors.textMuted,
                                  )),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: statusSteps.asMap().entries.map((e) {
                        final idx = e.key;
                        final step = e.value;
                        final currentIdx = statusSteps.indexOf(order.orderStatus);
                        final isDone = idx <= currentIdx;
                        final isCurrent = idx == currentIdx;
                        return Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
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
                                Expanded(child: Padding(
                                  padding: const EdgeInsets.only(top: 16),
                                  child: Container(height: 2, color: isDone && idx < currentIdx ? AppColors.primary : AppColors.border),
                                )),
                            ],
                          ),
                        );
                      }).toList(),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _CustomerNotesCard(order: order),

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
            // Instalment management card
            if (order.paymentMethod == 'Instalment') ...[
              const SizedBox(height: 20),
              AdminInstalmentCard(
                orderId: order.id,
                customerId: order.customerId,
              ),
            ],
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
                      Text('${item.quantity == item.quantity.truncate() ? item.quantity.toInt() : item.quantity.toStringAsFixed(2)} $unit x RM ${item.price.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),

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
          if (order.deliveryAddress != null) _row('Delivery Address', order.deliveryAddress!),
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
          if (order.paymentMethod != 'Instalment' && order.paymentStatus != 'Paid' && order.orderStatus != 'Cancelled') ...[
            const SizedBox(height: 12),
            AppButton(
              label: 'Mark Payment as Paid',
              icon: Icons.payments_outlined,
              width: double.infinity,
              onPressed: () => context.read<OrderProvider>().updatePaymentStatus(order.id, 'Paid'),
            ),
          ],
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

// ─── Instalment Management Card (Admin) ──────────────────────────
class AdminInstalmentCard extends StatefulWidget {
  final String orderId;
  final String customerId;
  const AdminInstalmentCard({super.key, required this.orderId, required this.customerId});

  @override
  State<AdminInstalmentCard> createState() => _AdminInstalmentCardState();
}

class _AdminInstalmentCardState extends State<AdminInstalmentCard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InstalmentProvider>().loadAllPlans();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InstalmentProvider>();
    final formatter = NumberFormat.currency(symbol: 'RM ', decimalDigits: 2);
    final plan = provider.planForOrder(widget.orderId);

    if (plan == null) return const SizedBox.shrink();

    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Row(children: [
            Icon(Icons.calendar_month_rounded, color: AppColors.primary, size: 18),
            SizedBox(width: 8),
            Text('Instalment Schedule', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          ]),
          _planBadge(plan.status),
        ]),
        const SizedBox(height: 8),
        Text('${plan.numberOfPeriods} × ${plan.periodUnit} | ${plan.perPeriodPaymentMethod}',
          style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
        const SizedBox(height: 6),
        _progressRow('Paid', '${plan.paidCount}/${plan.numberOfPeriods} periods'),
        _progressRow('Remaining', formatter.format(plan.totalRemaining)),
        _progressRow('Total', formatter.format(plan.totalAmount)),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: plan.totalAmount > 0 ? plan.totalPaid / plan.totalAmount : 0,
            minHeight: 8,
            backgroundColor: AppColors.border,
            color: plan.lateCount > 0 ? AppColors.danger : AppColors.success,
          ),
        ),
        const Divider(height: 24),
        ...plan.entries.asMap().entries.map((e) {
          final idx = e.key;
          final entry = e.value;
          final isOverdue = entry.isPending && entry.dueDate.isBefore(DateTime.now());
          return _entryRow(context, plan, entry, idx, isOverdue, formatter, provider);
        }),
      ]),
    );
  }

  Widget _entryRow(
    BuildContext context,
    InstalmentPlanModel plan,
    InstalmentEntry entry,
    int idx,
    bool isOverdue,
    NumberFormat formatter,
    InstalmentProvider provider,
  ) {
    Color statusColor;
    String statusText;
    if (entry.isPaid) { statusColor = AppColors.success; statusText = 'Paid'; }
    else if (entry.isLate) { statusColor = AppColors.danger; statusText = 'Late'; }
    else if (isOverdue) { statusColor = AppColors.danger; statusText = 'Overdue'; }
    else if (entry.status == 'Under Review') { statusColor = AppColors.warning; statusText = 'Under Review'; }
    else { statusColor = AppColors.pending; statusText = 'Pending'; }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: statusColor.withOpacity(0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('Period ${entry.periodNumber}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: statusColor.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
            child: Text(statusText, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: statusColor)),
          ),
        ]),
        const SizedBox(height: 6),
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Due: ${DateFormat('d MMM yyyy').format(entry.dueDate)}',
              style: TextStyle(fontSize: 12, color: isOverdue && entry.isPending ? AppColors.danger : AppColors.textMuted)),
            if (entry.paidAt != null)
              Text('Paid: ${DateFormat('d MMM yyyy').format(entry.paidAt!)}',
                style: const TextStyle(fontSize: 12, color: AppColors.success)),
            if (entry.adminNote != null && entry.adminNote!.isNotEmpty) ...[  
              const SizedBox(height: 4),
              Text('Note: ${entry.adminNote}',
                style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppColors.danger)),
            ],
            if (entry.paymentMethod != null) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(4)),
                child: Text('Method: ${entry.paymentMethod}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
              ),
              if (entry.paymentProofUrl != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: InkWell(
                    onTap: () {
                      // Mock open image
                    },
                    child: const Text('View Payment Proof ↗', style: TextStyle(fontSize: 11, color: AppColors.primary, decoration: TextDecoration.underline)),
                  ),
                ),
            ],
          ])),
          const SizedBox(width: 12),
          // Edit amount button (only unpaid)
          if (!entry.isPaid && !entry.isLate)
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 18),
              color: AppColors.textMuted,
              tooltip: 'Edit amount',
              onPressed: () => _showEditAmountDialog(context, plan, entry, idx, provider),
            ),
          Text(formatter.format(entry.amountDue),
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
        ]),
        if (!entry.isPaid && !entry.isLate) ...[  
          const SizedBox(height: 8),
          LayoutBuilder(builder: (ctx, constraints) {
            if (constraints.maxWidth < 400) {
              return Column(children: [
                AppButton(
                  label: entry.status == 'Under Review' ? 'Confirm Payment' : 'Mark Paid',
                  icon: Icons.check_circle_outline_rounded,
                  width: double.infinity,
                  onPressed: () => _showMarkPaidDialog(context, plan, entry, idx, false, provider),
                ),
                const SizedBox(height: 8),
                AppButton(
                  label: entry.status == 'Under Review' ? 'Reject (Mark Pending)' : 'Mark Late',
                  icon: entry.status == 'Under Review' ? Icons.close_rounded : Icons.warning_amber_rounded,
                  isDanger: true,
                  width: double.infinity,
                  onPressed: () {
                    if (entry.status == 'Under Review') {
                      provider.rejectPhasePayment(plan.id, idx);
                    } else {
                      _showMarkPaidDialog(context, plan, entry, idx, true, provider);
                    }
                  },
                ),
              ]);
            }
            return Row(children: [
              Expanded(
                child: AppButton(
                  label: entry.status == 'Under Review' ? 'Confirm Payment' : 'Mark Paid',
                  icon: Icons.check_circle_outline_rounded,
                  onPressed: () => _showMarkPaidDialog(context, plan, entry, idx, false, provider),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: AppButton(
                  label: entry.status == 'Under Review' ? 'Reject (Mark Pending)' : 'Mark Late',
                  icon: entry.status == 'Under Review' ? Icons.close_rounded : Icons.warning_amber_rounded,
                  isDanger: true,
                  onPressed: () {
                    if (entry.status == 'Under Review') {
                      provider.rejectPhasePayment(plan.id, idx);
                    } else {
                      _showMarkPaidDialog(context, plan, entry, idx, true, provider);
                    }
                  },
                ),
              ),
            ]);
          }),
        ],
      ]),
    );
  }

  Future<void> _showMarkPaidDialog(
    BuildContext context,
    InstalmentPlanModel plan,
    InstalmentEntry entry,
    int entryIndex,
    bool isLate,
    InstalmentProvider provider,
  ) async {
    final noteCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          Icon(isLate ? Icons.warning_rounded : Icons.check_circle_rounded,
            color: isLate ? AppColors.danger : AppColors.success),
          const SizedBox(width: 8),
          Text(isLate ? 'Mark as Late Payment' : 'Mark as Paid',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isLate ? AppColors.dangerLight : AppColors.successLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Period ${entry.periodNumber} — RM ${entry.amountDue.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(
                isLate
                    ? '⚠️ Credit score will decrease by 10%'
                    : '✅ Credit score will increase by 5% (max 100%)',
                style: TextStyle(
                  fontSize: 12,
                  color: isLate ? AppColors.danger : AppColors.success,
                ),
              ),
            ]),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: noteCtrl,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: isLate ? 'Admin Note (required for late)' : 'Admin Note (optional)',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              hintText: isLate ? 'Reason for late payment...' : 'Payment notes...',
            ),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isLate ? AppColors.danger : AppColors.success,
            ),
            onPressed: () {
              if (isLate && noteCtrl.text.trim().isEmpty) return;
              Navigator.pop(ctx, true);
            },
            child: Text(isLate ? 'Confirm Late' : 'Confirm Paid',
              style: const TextStyle(color: AppColors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await provider.markPeriodPaid(
        planId: plan.id,
        customerId: plan.customerId,
        entryIndex: entryIndex,
        isLate: isLate,
        adminNote: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
      );
    }
    noteCtrl.dispose();
  }

  Future<void> _showEditAmountDialog(
    BuildContext context,
    InstalmentPlanModel plan,
    InstalmentEntry entry,
    int entryIndex,
    InstalmentProvider provider,
  ) async {
    final ctrl = TextEditingController(text: entry.amountDue.toStringAsFixed(2));
    final totalOtherUnpaid = plan.entries.where((e) => e != entry).fold(0.0, (s, e) => s + e.amountDue);
    final maxAllowed = plan.totalAmount - totalOtherUnpaid;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Edit Period ${entry.periodNumber} Amount',
          style: const TextStyle(fontWeight: FontWeight.w700)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Max allowed: RM ${maxAllowed.toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
          const SizedBox(height: 12),
          TextField(
            controller: ctrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Amount (RM)',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final newAmt = double.tryParse(ctrl.text);
      if (newAmt != null) {
        await provider.updateEntryAmount(plan.id, entryIndex, newAmt);
      }
    }
    ctrl.dispose();
  }

  Widget _progressRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  Widget _planBadge(String status) {
    Color color;
    switch (status) {
      case 'Completed': color = AppColors.success; break;
      case 'Overdue': color = AppColors.danger; break;
      default: color = AppColors.info;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
      child: Text(status, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
    );
  }
}

class _CustomerNotesCard extends StatelessWidget {
  final OrderModel order;
  const _CustomerNotesCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final hasOrderNote = order.customerComment != null && order.customerComment!.isNotEmpty;
    final itemNotes = order.items.where((i) => i.remarks != null && i.remarks!.isNotEmpty).toList();
    
    if (!hasOrderNote && itemNotes.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.warningLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.warning),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.warning_amber_rounded, color: AppColors.warning),
            const SizedBox(width: 8),
            const Expanded(child: Text('Customer Comments & Instructions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.warning))),
          ]),
          const SizedBox(height: 16),
          if (hasOrderNote) ...[
            const Text('Checkout Note:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.warning)),
            const SizedBox(height: 4),
            Text(order.customerComment!, style: const TextStyle(fontSize: 14)),
            if (itemNotes.isNotEmpty) const Divider(height: 24, color: AppColors.warning),
          ],
          if (itemNotes.isNotEmpty) ...[
            const Text('Item-Specific Notes:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.warning)),
            const SizedBox(height: 8),
            ...itemNotes.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.warning)),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, fontFamily: 'Nunito'),
                        children: [
                          TextSpan(text: '${item.productName}: ', style: const TextStyle(fontWeight: FontWeight.w700)),
                          TextSpan(text: item.remarks!),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ],
      ),
    );
  }
}
