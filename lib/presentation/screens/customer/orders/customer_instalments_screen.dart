import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:stleaf_trading/core/theme/app_colors.dart';
import 'package:stleaf_trading/providers/auth_provider.dart';
import 'package:stleaf_trading/providers/app_providers.dart';
import 'package:stleaf_trading/data/models/instalment_model.dart';
import 'package:stleaf_trading/presentation/widgets/common/common_widgets.dart';
import 'package:stleaf_trading/presentation/widgets/layout/customer_layout.dart';

class CustomerInstalmentsScreen extends StatefulWidget {
  const CustomerInstalmentsScreen({super.key});

  @override
  State<CustomerInstalmentsScreen> createState() => _CustomerInstalmentsScreenState();
}

class _CustomerInstalmentsScreenState extends State<CustomerInstalmentsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.currentUser != null) {
        context.read<InstalmentProvider>().loadCustomerPlans(auth.currentUser!.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InstalmentProvider>();

    return CustomerLayout(
      currentRoute: '/shop/instalments',
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            width: double.infinity,
            color: AppColors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Instalment Orders', style: Theme.of(context).textTheme.headlineMedium),
                const Text('Manage and pay your active instalment phases', style: TextStyle(color: AppColors.textSecondary)),
              ],
            ),
          ),
          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : provider.plans.isEmpty
                    ? const EmptyState(
                        title: 'No Instalment Plans',
                        subtitle: 'You do not have any active instalment orders.',
                        icon: Icons.account_balance_wallet_outlined,
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: provider.plans.length,
                        itemBuilder: (ctx, i) => _InstalmentCard(plan: provider.plans[i]),
                      ),
          ),
        ],
      ),
    );
  }
}

class _InstalmentCard extends StatelessWidget {
  final InstalmentPlanModel plan;
  const _InstalmentCard({required this.plan});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(symbol: 'RM ', decimalDigits: 2);
    final isCompleted = plan.isCompleted;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: AppCard(
        child: InkWell(
        onTap: () => context.go('/shop/orders/${plan.orderId}/instalment'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Order #${plan.orderId.substring(0, 8).toUpperCase()}', style: const TextStyle(fontWeight: FontWeight.w800)),
                  StatusBadge(status: isCompleted ? 'Completed' : plan.status),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Total Amount', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                        Text(fmt.format(plan.totalAmount), style: const TextStyle(fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Outstanding', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                        Text(fmt.format(plan.totalRemaining), style: TextStyle(fontWeight: FontWeight.w700, color: isCompleted ? AppColors.success : AppColors.danger)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Progress', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                        Text('${plan.paidCount} / ${plan.numberOfPeriods} Paid', style: const TextStyle(fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: 'View Order',
                      icon: Icons.receipt_rounded,
                      isOutlined: true,
                      onPressed: () => context.go('/shop/orders/${plan.orderId}'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppButton(
                      label: isCompleted ? 'Details' : 'Pay Phase',
                      icon: isCompleted ? Icons.receipt_long_rounded : Icons.payment_rounded,
                      onPressed: () => context.go('/shop/orders/${plan.orderId}/instalment'),
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
