import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:stleaf_trading/core/theme/app_colors.dart';
import 'package:stleaf_trading/data/models/instalment_model.dart';
import 'package:stleaf_trading/providers/app_providers.dart';
import 'package:stleaf_trading/providers/auth_provider.dart';
import 'package:stleaf_trading/presentation/widgets/common/common_widgets.dart';
import 'package:stleaf_trading/presentation/widgets/layout/customer_layout.dart';
import 'package:stleaf_trading/presentation/screens/customer/orders/pay_phase_dialog.dart';
class InstalmentDetailScreen extends StatefulWidget {
  final String orderId;
  const InstalmentDetailScreen({super.key, required this.orderId});

  @override
  State<InstalmentDetailScreen> createState() => _InstalmentDetailScreenState();
}

class _InstalmentDetailScreenState extends State<InstalmentDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      final uid = auth.currentUser?.id;
      if (uid != null) {
        context.read<InstalmentProvider>().loadCustomerPlans(uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InstalmentProvider>();
    final formatter = NumberFormat.currency(symbol: 'RM ', decimalDigits: 2);
    final plan = provider.planForOrder(widget.orderId);

    return CustomerLayout(
      currentRoute: '/shop/orders',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              IconButton(
                onPressed: () => context.go('/shop/orders/${widget.orderId}'),
                icon: const Icon(Icons.arrow_back_rounded),
                style: IconButton.styleFrom(backgroundColor: AppColors.mint, foregroundColor: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Text('Instalment Plan', style: Theme.of(context).textTheme.headlineMedium),
            ]),
            const SizedBox(height: 20),

            if (provider.isLoading)
              const LoadingWidget()
            else if (plan == null)
              const EmptyState(title: 'No instalment plan found', icon: Icons.calendar_today_outlined)
            else ...[
              // Summary card
              AppCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: AppColors.mint, borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.calendar_month_rounded, color: AppColors.primary, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('${plan.numberOfPeriods} × ${plan.periodUnit}',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                      Text('via ${plan.perPeriodPaymentMethod}',
                        style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
                    ])),
                    _planStatusBadge(plan.status),
                  ]),
                  const Divider(height: 24),
                  _summaryRow('Total Amount', formatter.format(plan.totalAmount)),
                  _summaryRow('Paid So Far', formatter.format(plan.totalPaid)),
                  _summaryRow('Remaining', formatter.format(plan.totalRemaining)),
                  const SizedBox(height: 12),
                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: plan.totalAmount > 0 ? plan.totalPaid / plan.totalAmount : 0,
                      minHeight: 8,
                      backgroundColor: AppColors.border,
                      color: plan.lateCount > 0 ? AppColors.danger : AppColors.success,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text('${plan.paidCount} of ${plan.numberOfPeriods} periods paid',
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                ]),
              ),
              const SizedBox(height: 16),

              // Instalment schedule
              AppCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Payment Schedule',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 16),
                  ...plan.entries.asMap().entries.map((e) {
                    final idx = e.key;
                    final entry = e.value;
                    final isOverdue = entry.isPending && entry.dueDate.isBefore(DateTime.now());
                    return _periodRow(plan, entry, idx, isOverdue, formatter);
                  }),
                ]),
              ),

              // Info note
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.warningLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(children: [
                  Icon(Icons.info_outline_rounded, size: 16, color: AppColors.warning),
                  SizedBox(width: 10),
                  Expanded(child: Text(
                    'Payments are manually confirmed by admin. Contact us if you have made a payment.',
                    style: TextStyle(fontSize: 12, color: AppColors.warning),
                  )),
                ]),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _periodRow(InstalmentPlanModel plan, InstalmentEntry entry, int idx, bool isOverdue, NumberFormat formatter) {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    if (entry.isPaid) {
      statusColor = AppColors.success;
      statusIcon = Icons.check_circle_rounded;
      statusText = 'Paid';
    } else if (entry.isLate) {
      statusColor = AppColors.danger;
      statusIcon = Icons.cancel_rounded;
      statusText = 'Late';
    } else if (isOverdue) {
      statusColor = AppColors.danger;
      statusIcon = Icons.warning_rounded;
      statusText = 'Overdue';
    } else if (entry.status == 'Under Review') {
      statusColor = AppColors.warning;
      statusIcon = Icons.hourglass_empty_rounded;
      statusText = 'Under Review';
    } else {
      statusColor = AppColors.pending;
      statusIcon = Icons.schedule_rounded;
      statusText = 'Pending';
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.divider.withOpacity(0.5))),
      ),
      child: Row(children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: entry.isPaid || entry.isLate
                ? Icon(statusIcon, size: 16, color: statusColor)
                : Text('${entry.periodNumber}',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: statusColor)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Period ${entry.periodNumber}',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          Text('Due: ${DateFormat('d MMM yyyy').format(entry.dueDate)}',
            style: TextStyle(fontSize: 12, color: isOverdue && entry.isPending ? AppColors.danger : AppColors.textMuted)),
          if (entry.paidAt != null)
            Text('Paid: ${DateFormat('d MMM yyyy').format(entry.paidAt!)}',
              style: const TextStyle(fontSize: 11, color: AppColors.success)),
          if (entry.adminNote != null && entry.adminNote!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: AppColors.dangerLight, borderRadius: BorderRadius.circular(6)),
              child: Text('Note: ${entry.adminNote}',
                style: const TextStyle(fontSize: 11, color: AppColors.danger, fontStyle: FontStyle.italic)),
            ),
          ],
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(formatter.format(entry.amountDue),
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(statusText,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: statusColor)),
          ),
          if (entry.isPending || entry.isLate) ...[
            const SizedBox(height: 8),
            AppButton(
              label: 'Pay Phase',
              icon: Icons.payment_rounded,
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => PayPhaseDialog(
                    planId: plan.id,
                    entryIndex: idx,
                    amountDue: entry.amountDue,
                  ),
                );
              },
            ),
          ],
        ]),
      ]),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
      ]),
    );
  }

  Widget _planStatusBadge(String status) {
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
