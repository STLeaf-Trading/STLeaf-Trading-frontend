import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:stleaf_trading/core/theme/app_colors.dart';
import 'package:stleaf_trading/providers/app_providers.dart';
import 'package:stleaf_trading/presentation/widgets/layout/admin_layout.dart';
import 'package:stleaf_trading/presentation/widgets/common/common_widgets.dart';
import 'export_wizard_dialog.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final stats = context.watch<DashboardProvider>().stats;
    final formatter = NumberFormat.currency(symbol: 'RM ', decimalDigits: 2);

    if (stats == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<DashboardProvider>().loadStats();
      });
      return AdminLayout(currentRoute: '/admin/reports', child: const LoadingWidget());
    }

    return AdminLayout(
      currentRoute: '/admin/reports',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Reports', style: Theme.of(context).textTheme.displaySmall),
                  const Text('Business analytics overview', style: TextStyle(color: AppColors.textSecondary)),
                ]),
                AppButton(
                  label: 'Export PDF',
                  icon: Icons.download_rounded,
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => const ExportWizardDialog(defaultFormat: 'PDF'),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Summary KPIs
            Row(children: [
              Expanded(child: StatCard(title: 'Weekly Revenue', value: formatter.format(stats.revenueData.fold(0.0, (s, e) => s + e.amount)),
                icon: Icons.payments_rounded, color: AppColors.primary, isGradient: true)),
              const SizedBox(width: 16),
              Expanded(child: StatCard(title: 'Total Orders', value: '${context.watch<OrderProvider>().allOrders.length}',
                icon: Icons.receipt_long_rounded, color: AppColors.success, isGradient: true)),
              const SizedBox(width: 16),
              Expanded(child: StatCard(title: 'Outstanding Debt', value: formatter.format(stats.outstandingDebts),
                icon: Icons.account_balance_wallet_rounded, color: AppColors.danger, isGradient: true)),
            ]),
            const SizedBox(height: 28),

            // Revenue Chart
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Revenue Trend (7 Days)', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 220,
                    child: BarChart(
                      BarChartData(
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: 500,
                          getDrawingHorizontalLine: (_) => const FlLine(color: AppColors.divider, strokeWidth: 1),
                        ),
                        borderData: FlBorderData(show: false),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (val, meta) {
                                final i = val.toInt();
                                if (i >= 0 && i < stats.revenueData.length) {
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(stats.revenueData[i].label,
                                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                          ),
                        ),
                        barGroups: List.generate(stats.revenueData.length, (i) => BarChartGroupData(
                          x: i,
                          barRods: [BarChartRodData(
                            toY: stats.revenueData[i].amount,
                            color: AppColors.primary,
                            width: 28,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                          )],
                        )),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            LayoutBuilder(builder: (ctx, constraints) {
              final isWide = constraints.maxWidth > 700;
              return isWide
                  ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Expanded(child: _TopProductsTable(stats: stats, formatter: formatter)),
                      const SizedBox(width: 20),
                      Expanded(child: _TopCustomersTable(stats: stats, formatter: formatter)),
                    ])
                  : Column(children: [
                      _TopProductsTable(stats: stats, formatter: formatter),
                      const SizedBox(height: 20),
                      _TopCustomersTable(stats: stats, formatter: formatter),
                    ]);
            }),
          ],
        ),
      ),
    );
  }
}

class _TopProductsTable extends StatelessWidget {
  final stats;
  final NumberFormat formatter;
  const _TopProductsTable({required this.stats, required this.formatter});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Top Selling Products', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          ...List.generate(stats.topProducts.length, (i) {
            final p = stats.topProducts[i];
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.divider))),
              child: Row(
                children: [
                  Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(
                      gradient: i == 0 ? AppColors.cardGradient : null,
                      color: i > 0 ? AppColors.mint : null,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(child: Text('#${i + 1}',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800,
                        color: i == 0 ? AppColors.white : AppColors.primary))),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14))),
                  Text('${p.quantity} kg', style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
                  const SizedBox(width: 12),
                  Text(formatter.format(p.revenue),
                    style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _TopCustomersTable extends StatelessWidget {
  final stats;
  final NumberFormat formatter;
  const _TopCustomersTable({required this.stats, required this.formatter});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Top Customers', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          ...List.generate(stats.topCustomers.length, (i) {
            final c = stats.topCustomers[i];
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.divider))),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16, backgroundColor: AppColors.mint,
                    child: Text(c.name[0], style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 13)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(c.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    Text('${c.orders} orders', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  ])),
                  Text(formatter.format(c.totalSpent),
                    style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
