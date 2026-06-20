import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:stleaf_trading/core/theme/app_colors.dart';
import 'package:stleaf_trading/providers/auth_provider.dart';
import 'package:stleaf_trading/providers/app_providers.dart';
import 'package:stleaf_trading/presentation/widgets/common/common_widgets.dart';
import 'package:stleaf_trading/presentation/widgets/layout/customer_layout.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final orders = context.watch<OrderProvider>().allOrders;
    final formatter = NumberFormat.currency(symbol: 'RM ', decimalDigits: 2);

    final totalSpent = orders.fold(0.0, (sum, o) => sum + o.totalAmount);
    final user = auth.currentUser;

    return CustomerLayout(
      currentRoute: '/shop/profile',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile header
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: AppColors.heroGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40, backgroundColor: Colors.white.withOpacity(0.2),
                    child: Text(
                      (user?.name ?? 'U')[0].toUpperCase(),
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.white),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(user?.name ?? '', style: const TextStyle(color: AppColors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(user?.email ?? '', style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 14)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      user?.role ?? '', style: const TextStyle(color: AppColors.white, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Stats
            Row(children: [
              Expanded(child: StatCard(title: 'Total Orders', value: '${orders.length}',
                icon: Icons.receipt_long_rounded, color: AppColors.primary)),
              const SizedBox(width: 12),
              Expanded(child: StatCard(title: 'Total Spent', value: formatter.format(totalSpent),
                icon: Icons.payments_rounded, color: AppColors.success)),
            ]),
            const SizedBox(height: 16),

            // Account options
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _optionTile(context, Icons.receipt_long_rounded, 'My Orders', 'View your order history', () => context.go('/shop/orders')),
                  _divider(),
                  _optionTile(context, Icons.storefront_rounded, 'Browse Products', 'Shop fresh vegetables', () => context.go('/shop')),
                  _divider(),
                  _optionTile(context, Icons.headset_mic_rounded, 'Contact Support', 'Get help with your orders', () {}),
                  _divider(),
                  _optionTile(
                    context, Icons.logout_rounded, 'Logout', 'Sign out of your account',
                    () async {
                      await context.read<AuthProvider>().logout();
                      if (context.mounted) context.go('/login');
                    },
                    isRed: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // App info
            Column(
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(gradient: AppColors.primaryGradient, shape: BoxShape.circle),
                  child: ClipRRect(borderRadius: BorderRadius.circular(6), child: Image.asset('assets/images/logo.jpeg', width: 24, height: 24, fit: BoxFit.cover)),
                ),
                const SizedBox(height: 8),
                const Text('ST Leaf Trading', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary)),
                const Text('v1.0.0 · Fresh from Farm to Table', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _optionTile(BuildContext context, IconData icon, String title, String subtitle, VoidCallback onTap, {bool isRed = false}) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: isRed ? AppColors.dangerLight : AppColors.mint,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 20, color: isRed ? AppColors.danger : AppColors.primary),
      ),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: isRed ? AppColors.danger : AppColors.textPrimary)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
      trailing: Icon(Icons.chevron_right_rounded, color: isRed ? AppColors.danger : AppColors.textMuted),
    );
  }

  Widget _divider() => const Divider(height: 1, indent: 72);
}

