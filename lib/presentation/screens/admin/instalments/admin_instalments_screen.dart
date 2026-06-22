import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:stleaf_trading/core/theme/app_colors.dart';
import 'package:stleaf_trading/providers/app_providers.dart';
import 'package:stleaf_trading/data/models/instalment_model.dart';
import 'package:stleaf_trading/data/models/customer_model.dart';
import 'package:stleaf_trading/presentation/widgets/common/common_widgets.dart';
import 'package:stleaf_trading/presentation/widgets/layout/admin_layout.dart';
import 'package:url_launcher/url_launcher.dart';

class AdminInstalmentsScreen extends StatefulWidget {
  const AdminInstalmentsScreen({super.key});

  @override
  State<AdminInstalmentsScreen> createState() => _AdminInstalmentsScreenState();
}

class _AdminInstalmentsScreenState extends State<AdminInstalmentsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InstalmentProvider>().loadAllPlans();
      context.read<CustomerProvider>().loadCustomers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InstalmentProvider>();
    final customers = context.watch<CustomerProvider>().customers;

    return AdminLayout(
      currentRoute: '/admin/instalments',
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(28, 28, 28, 20),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Instalment Tracking', style: Theme.of(context).textTheme.displaySmall),
                    const Text('Manage customer instalment phases and payments', style: TextStyle(color: AppColors.textSecondary)),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : provider.plans.isEmpty
                    ? const EmptyState(
                        title: 'No Instalments',
                        subtitle: 'There are no active instalment plans in the system.',
                        icon: Icons.account_balance_wallet_outlined,
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
                        itemCount: provider.plans.length,
                        itemBuilder: (ctx, i) {
                          final plan = provider.plans[i];
                          final customer = customers.firstWhere((c) => c.id == plan.customerId, orElse: () => CustomerModel(
                            id: '', customerCode: '', companyName: plan.customerName, contactPerson: 'Unknown',
                            phoneNumber: '', email: '', businessRegistrationNo: '', address: '', creditLimit: 0, creditTerm: '', status: '',
                          ));
                          return _AdminInstalmentCard(plan: plan, customer: customer);
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _AdminInstalmentCard extends StatelessWidget {
  final InstalmentPlanModel plan;
  final CustomerModel customer;
  
  const _AdminInstalmentCard({required this.plan, required this.customer});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(symbol: 'RM ', decimalDigits: 2);
    final isCompleted = plan.isCompleted;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: AppCard(
        child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(customer.companyName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.primary)),
                      const SizedBox(height: 2),
                      Text('PIC: ${customer.contactPerson} • Order #${plan.orderId.substring(0, 8).toUpperCase()}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    StatusBadge(status: isCompleted ? 'Completed' : plan.status),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () => context.go('/admin/orders/${plan.orderId}'),
                      icon: const Icon(Icons.receipt_rounded, size: 16),
                      label: const Text('View Order'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        visualDensity: VisualDensity.compact,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 32),
            LayoutBuilder(builder: (context, constraints) {
              if (constraints.maxWidth < 400) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _summaryBox('Total Amount', fmt.format(plan.totalAmount)),
                    const SizedBox(height: 12),
                    _summaryBox('Remaining', fmt.format(plan.totalRemaining), color: isCompleted ? AppColors.success : AppColors.danger),
                    const SizedBox(height: 12),
                    _summaryBox('Progress', '${plan.paidCount} / ${plan.numberOfPeriods} Paid'),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: _summaryBox('Total Amount', fmt.format(plan.totalAmount))),
                  Expanded(child: _summaryBox('Remaining', fmt.format(plan.totalRemaining), color: isCompleted ? AppColors.success : AppColors.danger)),
                  Expanded(child: _summaryBox('Progress', '${plan.paidCount} / ${plan.numberOfPeriods} Paid')),
                ],
              );
            }),
            const SizedBox(height: 20),
            const Text('Phases', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
            const SizedBox(height: 12),
            Column(
              children: plan.entries.asMap().entries.map((e) {
                final idx = e.key;
                final entry = e.value;
                return _AdminPhaseRow(plan: plan, entry: entry, entryIndex: idx);
              }).toList(),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _summaryBox(String label, String value, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: color ?? AppColors.textPrimary)),
      ],
    );
  }
}

class _AdminPhaseRow extends StatelessWidget {
  final InstalmentPlanModel plan;
  final InstalmentEntry entry;
  final int entryIndex;

  const _AdminPhaseRow({required this.plan, required this.entry, required this.entryIndex});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(symbol: 'RM ', decimalDigits: 2);
    final isOverdue = entry.isPending && DateTime.now().isAfter(entry.dueDate);
    
    Color statusColor;
    String statusText;

    if (entry.isPaid) {
      statusColor = AppColors.success;
      statusText = 'Paid';
    } else if (entry.status == 'Under Review') {
      statusColor = AppColors.warning;
      statusText = 'Under Review';
    } else if (isOverdue) {
      statusColor = AppColors.danger;
      statusText = 'Overdue';
    } else {
      statusColor = AppColors.pending;
      statusText = 'Pending';
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: LayoutBuilder(builder: (context, constraints) {
        final isWide = constraints.maxWidth > 500;
        final mainRow = Row(
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: statusColor.withOpacity(0.12),
              child: Text('${entry.periodNumber}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: statusColor)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Due: ${DateFormat('d MMM yyyy').format(entry.dueDate)}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isOverdue ? AppColors.danger : AppColors.textPrimary)),
                  if (entry.paymentMethod?.isNotEmpty == true && entry.status != 'Pending')
                    Text('Method: ${entry.paymentMethod}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(fmt.format(entry.amountDue), style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: statusColor.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
                  child: Text(statusText, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: statusColor)),
                ),
              ],
            ),
            if (isWide && !entry.isPaid) ...[
              const SizedBox(width: 16),
              AppButton(
                label: entry.status == 'Under Review' ? 'Review' : 'Mark Done',
                icon: entry.status == 'Under Review' ? Icons.visibility_rounded : Icons.check_circle_rounded,
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => _AdminVerifyPhaseDialog(plan: plan, entryIndex: entryIndex),
                  );
                },
              ),
            ],
          ],
        );
        if (isWide) {
          return mainRow;
        } else {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              mainRow,
              if (!entry.isPaid) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: AppButton(
                    label: entry.status == 'Under Review' ? 'Review' : 'Mark Done',
                    icon: entry.status == 'Under Review' ? Icons.visibility_rounded : Icons.check_circle_rounded,
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => _AdminVerifyPhaseDialog(plan: plan, entryIndex: entryIndex),
                      );
                    },
                  ),
                ),
              ],
            ],
          );
        }
      }),
    );
  }
}

class _AdminVerifyPhaseDialog extends StatefulWidget {
  final InstalmentPlanModel plan;
  final int entryIndex;

  const _AdminVerifyPhaseDialog({required this.plan, required this.entryIndex});

  @override
  State<_AdminVerifyPhaseDialog> createState() => _AdminVerifyPhaseDialogState();
}

class _AdminVerifyPhaseDialogState extends State<_AdminVerifyPhaseDialog> {
  final TextEditingController _noteCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final entry = widget.plan.entries[widget.entryIndex];
    final fmt = NumberFormat.currency(symbol: 'RM ', decimalDigits: 2);

    return AlertDialog(
      title: Text('Verify Phase ${entry.periodNumber} Payment'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoRow('Amount Due:', fmt.format(entry.amountDue)),
            _infoRow('Due Date:', DateFormat('d MMM yyyy').format(entry.dueDate)),
            if (entry.paymentMethod?.isNotEmpty == true && entry.status != 'Pending')
              _infoRow('Payment Method:', entry.paymentMethod!),
            
            const SizedBox(height: 16),
            if (entry.paymentProofUrl != null && entry.paymentProofUrl!.isNotEmpty) ...[
              const Text('Payment Proof:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 8),
              InkWell(
                onTap: () => launchUrl(Uri.parse(entry.paymentProofUrl!)),
                child: Container(
                  height: 120,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(8),
                    image: DecorationImage(
                      image: NetworkImage(entry.paymentProofUrl!),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                      child: const Icon(Icons.open_in_new_rounded, color: Colors.white, size: 24),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            const Text('Admin Note (Optional):', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 8),
            TextField(
              controller: _noteCtrl,
              decoration: const InputDecoration(
                hintText: 'Add a note about this payment...',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _isLoading ? null : () => _verifyPayment(context, 'Paid'),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
          child: _isLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Mark as Paid'),
        ),
        if (entry.status == 'Under Review')
          ElevatedButton(
            onPressed: _isLoading ? null : () => _verifyPayment(context, 'Pending'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Reject Proof'),
          ),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
        ],
      ),
    );
  }

  Future<void> _verifyPayment(BuildContext context, String newStatus) async {
    setState(() => _isLoading = true);
    try {
      if (newStatus == 'Paid') {
        await context.read<InstalmentProvider>().markPeriodPaid(
          planId: widget.plan.id,
          customerId: widget.plan.customerId,
          entryIndex: widget.entryIndex,
          isLate: false,
          adminNote: _noteCtrl.text.trim().isNotEmpty ? _noteCtrl.text.trim() : null,
        );
      } else if (newStatus == 'Pending') {
        await context.read<InstalmentProvider>().rejectPhasePayment(
          widget.plan.id,
          widget.entryIndex,
        );
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(newStatus == 'Paid' ? 'Phase marked as Paid' : 'Payment proof rejected'), backgroundColor: newStatus == 'Paid' ? AppColors.success : AppColors.danger));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.danger));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
