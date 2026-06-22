import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:stleaf_trading/core/theme/app_colors.dart';
import 'package:stleaf_trading/providers/app_providers.dart';
import 'package:stleaf_trading/data/models/inventory_model.dart';
import 'package:stleaf_trading/presentation/widgets/common/common_widgets.dart';
import 'package:stleaf_trading/presentation/widgets/layout/admin_layout.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InventoryProvider>().loadInventory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InventoryProvider>();

    return AdminLayout(
      currentRoute: '/admin/inventory',
      child: provider.isLoading
          ? const LoadingWidget(message: 'Loading inventory...')
          : SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Inventory', style: Theme.of(context).textTheme.displaySmall),
                  const Text('Monitor and update stock levels', style: TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(height: 24),

                  // Alerts
                  if (provider.outOfStock.isNotEmpty)
                    _AlertBanner(
                      color: AppColors.dangerLight, textColor: AppColors.danger,
                      icon: Icons.error_outline_rounded,
                      message: '${provider.outOfStock.length} product(s) are out of stock!',
                    ),
                  if (provider.lowStock.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _AlertBanner(
                      color: AppColors.warningLight, textColor: AppColors.warning,
                      icon: Icons.warning_amber_rounded,
                      message: '${provider.lowStock.length} product(s) are running low on stock.',
                    ),
                  ],
                  const SizedBox(height: 24),

                  // Stats
                  LayoutBuilder(builder: (context, constraints) {
                    if (constraints.maxWidth < 600) {
                      return Column(
                        children: [
                          StatCard(title: 'Total Products', value: '${provider.inventory.length}',
                            icon: Icons.inventory_2_rounded, color: AppColors.primary),
                          const SizedBox(height: 16),
                          StatCard(title: 'Low Stock', value: '${provider.lowStock.length}',
                            icon: Icons.warning_amber_rounded, color: AppColors.warning),
                          const SizedBox(height: 16),
                          StatCard(title: 'Out of Stock', value: '${provider.outOfStock.length}',
                            icon: Icons.remove_shopping_cart_rounded, color: AppColors.danger),
                        ],
                      );
                    }
                    return Row(children: [
                      Expanded(child: StatCard(title: 'Total Products', value: '${provider.inventory.length}',
                        icon: Icons.inventory_2_rounded, color: AppColors.primary)),
                      const SizedBox(width: 16),
                      Expanded(child: StatCard(title: 'Low Stock', value: '${provider.lowStock.length}',
                        icon: Icons.warning_amber_rounded, color: AppColors.warning)),
                      const SizedBox(width: 16),
                      Expanded(child: StatCard(title: 'Out of Stock', value: '${provider.outOfStock.length}',
                        icon: Icons.remove_shopping_cart_rounded, color: AppColors.danger)),
                    ]);
                  }),
                  const SizedBox(height: 28),

                  // Table
                  LayoutBuilder(builder: (context, constraints) {
                    return AppCard(
                      padding: EdgeInsets.zero,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SizedBox(
                          width: constraints.maxWidth > 800 ? constraints.maxWidth : 800,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(20),
                                child: Row(children: [
                                  Text('Stock Levels', style: Theme.of(context).textTheme.titleLarge),
                                ]),
                              ),
                              const Divider(height: 1),
                              ...provider.inventory.map((item) => _InventoryRow(item: item)),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
    );
  }
}

class _AlertBanner extends StatelessWidget {
  final Color color, textColor;
  final IconData icon;
  final String message;
  const _AlertBanner({required this.color, required this.textColor, required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
      child: Row(children: [
        Icon(icon, color: textColor, size: 18),
        const SizedBox(width: 10),
        Text(message, style: TextStyle(color: textColor, fontWeight: FontWeight.w500)),
      ]),
    );
  }
}

class _InventoryRow extends StatefulWidget {
  final InventoryModel item;
  const _InventoryRow({required this.item});

  @override
  State<_InventoryRow> createState() => _InventoryRowState();
}

class _InventoryRowState extends State<_InventoryRow> {
  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final pct = item.currentStock == 0 ? 0.0 : (item.availableStock / item.currentStock).clamp(0.0, 1.0);

    Color barColor = AppColors.success;
    if (item.isOutOfStock) barColor = AppColors.danger;
    else if (item.isLowStock) barColor = AppColors.warning;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.divider))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.productName ?? 'Product', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    Text(item.productCode ?? '', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  ],
                ),
              ),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text('${item.currentStock}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  const Text('Total', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                ],
              )),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text('${item.reservedStock}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.warning)),
                  const Text('Reserved', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                ],
              )),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text('${item.availableStock}', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: barColor)),
                  const Text('Available', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                ],
              )),
              StatusBadge(status: item.stockStatus),
              const SizedBox(width: 12),
              IconButton(
                onPressed: () => context.go('/admin/products/${item.productId}/edit'),
                icon: const Icon(Icons.edit_rounded, size: 18),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.surface,
                  foregroundColor: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: AppColors.border,
              color: barColor,
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}
