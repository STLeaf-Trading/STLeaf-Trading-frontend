import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:html' as html;
import 'package:stleaf_trading/core/theme/app_colors.dart';
import 'package:stleaf_trading/providers/app_providers.dart';
import 'package:stleaf_trading/providers/settings_provider.dart';
import 'package:stleaf_trading/presentation/widgets/common/common_widgets.dart';
import 'package:stleaf_trading/presentation/widgets/layout/admin_layout.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().loadStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DashboardProvider>();
    final formatter = NumberFormat.currency(symbol: 'RM ', decimalDigits: 2);

    return AdminLayout(
      currentRoute: '/admin/dashboard',
      child: provider.isLoading
          ? const LoadingWidget(message: 'Loading dashboard...')
          : _DashboardBody(stats: provider.stats!, formatter: formatter),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  final stats;
  final NumberFormat formatter;

  const _DashboardBody({required this.stats, required this.formatter});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Dashboard', style: Theme.of(context).textTheme.displaySmall),
                  Text(
                    DateFormat('EEEE, d MMMM yyyy').format(DateTime.now()),
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),

          // KPI Cards
          _KpiGrid(stats: stats, formatter: formatter),
          const SizedBox(height: 28),

          // Charts Row
          LayoutBuilder(builder: (ctx, constraints) {
            final isWide = constraints.maxWidth > 700;
            if (isWide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: _RevenueChartCard(stats: stats, formatter: formatter)),
                  const SizedBox(width: 20),
                  Expanded(flex: 2, child: _TopProductsCard(stats: stats)),
                ],
              );
            }
            return Column(
              children: [
                _RevenueChartCard(stats: stats, formatter: formatter),
                const SizedBox(height: 20),
                _TopProductsCard(stats: stats),
              ],
            );
          }),
          const SizedBox(height: 28),

          // Bottom row
          LayoutBuilder(builder: (ctx, constraints) {
            final isWide = constraints.maxWidth > 700;
            if (isWide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _RecentOrdersCard()),
                  const SizedBox(width: 20),
                  Expanded(child: _TopCustomersCard(stats: stats, formatter: formatter)),
                ],
              );
            }
            return Column(
              children: [
                _RecentOrdersCard(),
                const SizedBox(height: 20),
                _TopCustomersCard(stats: stats, formatter: formatter),
              ],
            );
          }),
          const SizedBox(height: 28),
          _SettingsCard(),
        ],
      ),
    );
  }
}

class _SettingsCard extends StatefulWidget {
  @override
  State<_SettingsCard> createState() => _SettingsCardState();
}

class _SettingsCardState extends State<_SettingsCard> {
  final _feeCtrl = TextEditingController();
  bool _synced = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final fee = context.read<SettingsProvider>().deliveryFee;
    // Only auto-sync when fee loads from Firestore and user hasn't typed
    if (!_synced && fee != 15.00 || _feeCtrl.text.isEmpty) {
      _feeCtrl.text = fee.toStringAsFixed(2);
      _synced = true;
    }
  }

  @override
  void dispose() {
    _feeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Store Settings', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  label: 'Default Delivery Fee (RM)',
                  hint: '15.00',
                  controller: _feeCtrl,
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 16),
              AppButton(
                label: 'Save',
                isLoading: settings.isLoading,
                onPressed: () {
                  final newFee = double.tryParse(_feeCtrl.text);
                  if (newFee != null) {
                    settings.updateDeliveryFee(newFee);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Settings updated!'), backgroundColor: AppColors.success),
                    );
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _KpiGrid extends StatelessWidget {
  final stats;
  final NumberFormat formatter;
  const _KpiGrid({required this.stats, required this.formatter});

  @override
  Widget build(BuildContext context) {
    final cards = [
      (Icons.receipt_long_rounded, 'Today\'s Orders', '${stats.todayOrders}', null, AppColors.primary, true),
      (Icons.payments_rounded, 'Today\'s Revenue', formatter.format(stats.todayRevenue), null, AppColors.success, true),
      (Icons.pending_actions_rounded, 'Pending Orders', '${stats.pendingOrders}', null, AppColors.warning, false),
      (Icons.local_shipping_rounded, 'Pending Deliveries', '${stats.pendingDeliveries}', null, AppColors.info, false),
      (Icons.inventory_rounded, 'Low Stock Items', '${stats.lowStockProducts}', 'Needs restocking', AppColors.danger, false),
      (Icons.account_balance_wallet_rounded, 'Outstanding Debts', formatter.format(stats.outstandingDebts), 'Total receivable', const Color(0xFF7B1FA2), false),
    ];

    return LayoutBuilder(
      builder: (ctx, constraints) {
        final crossCount = constraints.maxWidth > 900 ? 3 : (constraints.maxWidth > 600 ? 2 : 1);
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.6,
          ),
          itemCount: cards.length,
          itemBuilder: (ctx, i) {
            final c = cards[i];
            return StatCard(
              icon: c.$1, title: c.$2, value: c.$3,
              subtitle: c.$4, color: c.$5, isGradient: c.$6,
            );
          },
        );
      },
    );
  }
}

class _RevenueChartCard extends StatelessWidget {
  final stats;
  final NumberFormat formatter;
  const _RevenueChartCard({required this.stats, required this.formatter});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Weekly Revenue', style: Theme.of(context).textTheme.titleLarge),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: AppColors.mint, borderRadius: BorderRadius.circular(20)),
                child: const Text('This Week', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            formatter.format(stats.revenueData.fold(0.0, (s, e) => s + e.amount)),
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.primary),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  horizontalInterval: 500,
                  getDrawingHorizontalLine: (_) => const FlLine(color: AppColors.divider, strokeWidth: 1),
                  drawVerticalLine: false,
                ),
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
                              style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w500)),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => AppColors.white,
                    tooltipBorder: const BorderSide(color: AppColors.textPrimary),
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) => LineTooltipItem(
                        spot.y.toStringAsFixed(0),
                        const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
                      )).toList();
                    },
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(stats.revenueData.length, (i) =>
                      FlSpot(i.toDouble(), stats.revenueData[i].amount)),
                    isCurved: true,
                    color: AppColors.primary,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, pct, bar, idx) => FlDotCirclePainter(
                        radius: 4, color: AppColors.primary, strokeWidth: 2, strokeColor: AppColors.white,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [AppColors.primary.withOpacity(0.2), AppColors.primary.withOpacity(0)],
                        begin: Alignment.topCenter, end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopProductsCard extends StatelessWidget {
  final stats;
  const _TopProductsCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final colors = [AppColors.chart1, AppColors.chart2, AppColors.chart3, AppColors.chart4, AppColors.chart5];

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Top Products', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 50,
                sections: List.generate(stats.topProducts.length, (i) {
                  final total = stats.topProducts.fold(0.0, (s, e) => s + e.quantity.toDouble());
                  return PieChartSectionData(
                    value: stats.topProducts[i].quantity.toDouble(),
                    color: colors[i % colors.length],
                    radius: 60,
                    title: '${((stats.topProducts[i].quantity / total) * 100).toStringAsFixed(0)}%',
                    titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.white),
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 20),
          ...List.generate(stats.topProducts.length, (i) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Container(width: 10, height: 10, decoration: BoxDecoration(
                  color: colors[i % colors.length], shape: BoxShape.circle,
                )),
                const SizedBox(width: 10),
                Expanded(child: Text(stats.topProducts[i].name,
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary))),
                Text('${stats.topProducts[i].quantity} kg',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

class _RecentOrdersCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final orders = context.watch<OrderProvider>().allOrders;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Recent Orders', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          if (orders.isEmpty)
            const EmptyState(title: 'No orders yet', icon: Icons.receipt_long_outlined)
          else
            ...orders.take(4).map((order) => Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.divider))),
              child: Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(color: AppColors.mint, borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.receipt_long_rounded, color: AppColors.primary, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(order.orderId, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        Text(order.customerName ?? '', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('RM ${order.totalAmount.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                      StatusBadge(status: order.orderStatus),
                    ],
                  ),
                ],
              ),
            )),
        ],
      ),
    );
  }
}

class _TopCustomersCard extends StatelessWidget {
  final stats;
  final NumberFormat formatter;
  const _TopCustomersCard({required this.stats, required this.formatter});

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
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.divider))),
              child: Row(
                children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(child: Text('${i + 1}',
                      style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w800, fontSize: 14))),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        Text('${c.orders} orders', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                  Text(formatter.format(c.totalSpent),
                    style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary, fontSize: 13)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
