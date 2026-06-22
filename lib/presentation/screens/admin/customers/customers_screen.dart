import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:stleaf_trading/core/theme/app_colors.dart';
import 'package:stleaf_trading/data/models/customer_model.dart';
import 'package:stleaf_trading/providers/app_providers.dart';
import 'package:stleaf_trading/presentation/widgets/common/common_widgets.dart';
import 'package:stleaf_trading/presentation/widgets/layout/admin_layout.dart';

import 'add_customer_dialog.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CustomerProvider>().loadCustomers();
      context.read<InstalmentProvider>().loadAllPlans();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CustomerProvider>();
    final formatter = NumberFormat.currency(symbol: 'RM ', decimalDigits: 2);

    return AdminLayout(
      currentRoute: '/admin/customers',
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 28, 28, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Customers', style: Theme.of(context).textTheme.displaySmall),
                  const Text('Manage wholesale customer accounts', style: TextStyle(color: AppColors.textSecondary)),
                ]),
                AppButton(
                  label: 'Add Customer',
                  icon: Icons.person_add_rounded,
                  onPressed: () {
                    showDialog(context: context, builder: (_) => const AddCustomerDialog());
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: TextField(
              onChanged: provider.setSearch,
              decoration: InputDecoration(
                hintText: 'Search by company, customer code or contact...',
                prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.textMuted),
                filled: true, fillColor: AppColors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: provider.isLoading
                ? const LoadingWidget()
                : provider.customers.isEmpty
                    ? const EmptyState(title: 'No customers found', icon: Icons.people_outline)
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        itemCount: provider.customers.length,
                        itemBuilder: (ctx, i) => _CustomerCard(
                          customer: provider.customers[i], formatter: formatter,
                          onTap: () => context.go('/admin/customers/${provider.customers[i].id}'),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _CustomerCard extends StatefulWidget {
  final CustomerModel customer;
  final NumberFormat formatter;
  final VoidCallback onTap;
  const _CustomerCard({required this.customer, required this.formatter, required this.onTap});

  @override
  State<_CustomerCard> createState() => _CustomerCardState();
}

class _CustomerCardState extends State<_CustomerCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.customer;
    final creditUsedPct = c.creditLimit == 0 ? 0.0 : (c.outstandingBalance / c.creditLimit).clamp(0.0, 1.0);
    Color creditColor = AppColors.success;
    if (creditUsedPct > 0.9) creditColor = AppColors.danger;
    else if (creditUsedPct > 0.7) creditColor = AppColors.warning;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _hovered ? AppColors.primary.withOpacity(0.3) : AppColors.border),
            boxShadow: [BoxShadow(color: _hovered ? AppColors.primary.withOpacity(0.08) : Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24, backgroundColor: AppColors.mint,
                child: Text(c.companyName[0], style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 18)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Text(c.companyName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                      const SizedBox(width: 10),
                      StatusBadge(status: c.status),
                    ]),
                    const SizedBox(height: 4),
                    Text('${c.customerCode} • ${c.contactPerson} • ${c.phoneNumber}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                    const SizedBox(height: 10),
                    Row(children: [
                      _infoChip(Icons.verified_user_rounded, 'Credit Score: ${c.creditScore.toInt()}%'),
                    ]),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Outstanding Debt', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                  Text(widget.formatter.format(c.outstandingBalance),
                    style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w800,
                      color: c.outstandingBalance > 0 ? AppColors.danger : AppColors.success,
                    )),
                ],
              ),
              const SizedBox(width: 12),
              const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: AppColors.mint, borderRadius: BorderRadius.circular(20)),
      child: Row(children: [
        Icon(icon, size: 11, color: AppColors.primary),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w500)),
      ]),
    );
  }
}

// ─── Customer Detail ────────────────────────────────────────────
class CustomerDetailScreen extends StatelessWidget {
  final String customerId;
  const CustomerDetailScreen({super.key, required this.customerId});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CustomerProvider>();
    final formatter = NumberFormat.currency(symbol: 'RM ', decimalDigits: 2);
    final customers = provider.customers;
    final c = customers.isNotEmpty
        ? customers.firstWhere((c) => c.id == customerId, orElse: () => customers.first)
        : null;

    if (c == null) return AdminLayout(currentRoute: '/admin/customers', child: const LoadingWidget());

    return AdminLayout(
      currentRoute: '/admin/customers',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              IconButton(
                onPressed: () => context.go('/admin/customers'),
                icon: const Icon(Icons.arrow_back_rounded),
                style: IconButton.styleFrom(backgroundColor: AppColors.mint),
              ),
              const SizedBox(width: 16),
              Text(c.companyName, style: Theme.of(context).textTheme.displaySmall),
              const SizedBox(width: 12),
              StatusBadge(status: c.status),
            ]),
            const SizedBox(height: 28),
            LayoutBuilder(builder: (ctx, constraints) {
              if (constraints.maxWidth > 700) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _CustomerInfoCard(c: c)),
                    const SizedBox(width: 20),
                    Expanded(child: _CreditCard(c: c, formatter: formatter)),
                  ],
                );
              }
              return Column(children: [
                _CustomerInfoCard(c: c),
                const SizedBox(height: 20),
                _CreditCard(c: c, formatter: formatter),
              ]);
            }),
          ],
        ),
      ),
    );
  }
}

class _CustomerInfoCard extends StatelessWidget {
  final CustomerModel c;
  const _CustomerInfoCard({required this.c});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Business Information', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 20),
          _row('Customer Code', c.customerCode),
          _row('Company Name', c.companyName),
          _row('Contact Person', c.contactPerson),
          _row('Phone Number', c.phoneNumber),
          _row('Email', c.email),
          _row('Address', c.address),
          _row('Credit Score', '${c.creditScore.toInt()}%'),
          _row('Status', c.status),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 140, child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textMuted))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}

class _CreditCard extends StatelessWidget {
  final CustomerModel c;
  final NumberFormat formatter;
  const _CreditCard({required this.c, required this.formatter});

  @override
  Widget build(BuildContext context) {
    final instalmentsProvider = context.watch<InstalmentProvider>();
    final activePlans = instalmentsProvider.plans.where((p) => p.customerId == c.id && p.status == 'Active').toList();

    if (activePlans.isEmpty) {
      return AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Instalment Overview', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 20),
            const Text('This customer currently has no active instalments.', style: TextStyle(color: AppColors.textMuted)),
          ],
        ),
      );
    }

    double totalDebt = 0;
    double totalPaid = 0;
    double totalAmount = 0;
    int totalPaidPhases = 0;
    int totalPhases = 0;
    DateTime? nextPaymentDate;

    for (var p in activePlans) {
      totalDebt += p.totalRemaining;
      totalPaid += p.totalPaid;
      totalAmount += p.totalAmount;
      totalPaidPhases += p.paidCount;
      totalPhases += p.numberOfPeriods;
      
      final pendingEntries = p.entries.where((e) => !e.isPaid).toList()
        ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
      if (pendingEntries.isNotEmpty) {
        final date = pendingEntries.first.dueDate;
        if (nextPaymentDate == null || date.isBefore(nextPaymentDate)) {
          nextPaymentDate = date;
        }
      }
    }

    final pct = totalAmount == 0 ? 0.0 : (totalPaid / totalAmount).clamp(0.0, 1.0);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Instalment Overview', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: _creditStat('Active Debt', formatter.format(totalDebt), AppColors.danger)),
            Expanded(child: _creditStat('Payment Phase', '$totalPaidPhases / $totalPhases', AppColors.primary)),
            Expanded(child: _creditStat('Next Payment', nextPaymentDate != null ? DateFormat('d MMM yyyy').format(nextPaymentDate) : 'N/A', AppColors.warning)),
          ]),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Instalment Progress (Paid %)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              Text('${(pct * 100).toStringAsFixed(1)}%', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: pct, minHeight: 12,
              backgroundColor: AppColors.border,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _creditStat(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
      ],
    );
  }
}
