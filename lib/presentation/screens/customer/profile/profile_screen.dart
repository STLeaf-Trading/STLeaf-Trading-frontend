import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:stleaf_trading/core/theme/app_colors.dart';
import 'package:stleaf_trading/providers/auth_provider.dart';
import 'package:stleaf_trading/providers/app_providers.dart';
import 'package:stleaf_trading/presentation/widgets/common/common_widgets.dart';
import 'package:stleaf_trading/presentation/widgets/layout/customer_layout.dart';
import 'package:stleaf_trading/presentation/widgets/common/contact_support_widget.dart';
import 'package:stleaf_trading/presentation/screens/customer/profile/legal_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CustomerProvider>().loadCustomers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final orders = context.watch<OrderProvider>().allOrders;
    final formatter = NumberFormat.currency(symbol: 'RM ', decimalDigits: 2);

    final totalSpent = orders.fold(0.0, (sum, o) => sum + o.totalAmount);
    final user = auth.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Fetch credit score from CustomerProvider
    final customers = context.watch<CustomerProvider>().customers;
    final customer = customers.isNotEmpty
        ? customers.firstWhere((c) => c.id == user?.id, orElse: () => customers.first)
        : null;
    final creditScore = customer?.creditScore ?? 100.0;
    final creditHistory = customer?.creditHistory ?? [];
    final onTimeCount = creditHistory.where((h) => (h['delta'] as num? ?? 0) > 0).length;
    final lateCount = creditHistory.where((h) => (h['delta'] as num? ?? 0) < 0).length;
    Color creditColor = creditScore >= 80 ? AppColors.success : creditScore >= 50 ? AppColors.warning : AppColors.danger;

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
                      (user.name.isNotEmpty) ? user.name[0].toUpperCase() : 'U',
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
            const SizedBox(height: 12),

            // Credit Score Card
            AppCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Row(children: [
                    Icon(Icons.star_rate_rounded, color: AppColors.warning, size: 20),
                    SizedBox(width: 8),
                    Text('Credit Score', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  ]),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: creditColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('${creditScore.toStringAsFixed(0)}%',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: creditColor)),
                  ),
                ]),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: creditScore / 100,
                    minHeight: 10,
                    backgroundColor: AppColors.border,
                    color: creditColor,
                  ),
                ),
                const SizedBox(height: 12),
                Row(children: [
                  _creditStat('✅ On-time', onTimeCount.toString(), AppColors.success),
                  const SizedBox(width: 16),
                  _creditStat('⚠️ Late', lateCount.toString(), AppColors.danger),
                ]),
              ]),
            ),
            const SizedBox(height: 16),

            // Account options
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _optionTile(context, Icons.edit_rounded, 'Edit Profile', 'Update your details & address', () => context.push('/shop/edit-profile')),
                  _divider(),
                  _optionTile(context, Icons.receipt_long_rounded, 'My Orders', 'View your order history', () => context.go('/shop/orders')),
                  _divider(),
                  _optionTile(context, Icons.account_balance_wallet_rounded, 'Instalment Orders', 'View and pay instalment phases', () => context.go('/shop/instalments')),
                  _divider(),
                  _optionTile(context, Icons.storefront_rounded, 'Browse Products', 'Shop fresh vegetables', () => context.go('/shop')),
                  _divider(),
                  _optionTile(context, Icons.headset_mic_rounded, 'Contact Support', 'Get help with your orders', () => ContactSupportUtils.showContactOptions(context)),
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
            const SizedBox(height: 16),

            // Legal section
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _optionTile(context, Icons.gavel_rounded, 'Terms & Conditions', 'Read our terms of service',
                    () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const LegalScreen(title: 'Terms & Conditions', type: 'terms'),
                    ))),
                  _divider(),
                  _optionTile(context, Icons.privacy_tip_rounded, 'Privacy Policy', 'How we handle your data',
                    () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const LegalScreen(title: 'Privacy Policy', type: 'privacy'),
                    ))),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Danger zone
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _optionTile(
                    context, Icons.delete_forever_rounded, 'Delete Account', 'Permanently remove your account',
                    () => _showDeleteDialog(context),
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

  Future<void> _showDeleteDialog(BuildContext context) async {
    final passwordCtrl = TextEditingController();
    bool obscure = true;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(children: [
            Icon(Icons.warning_rounded, color: AppColors.danger),
            SizedBox(width: 8),
            Text('Delete Account', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.danger)),
          ]),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This action is permanent and cannot be undone.\n\n'
                '• Your account and profile will be permanently deleted.\n'
                '• Your order history will be preserved for our records.\n\n'
                'Please enter your password to confirm:',
                style: TextStyle(fontSize: 13, height: 1.5),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordCtrl,
                obscureText: obscure,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  suffixIcon: IconButton(
                    icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setStateDialog(() => obscure = !obscure),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (passwordCtrl.text.isEmpty) return;
                Navigator.pop(ctx);
                final auth = context.read<AuthProvider>();
                final error = await auth.deleteAccount(passwordCtrl.text);
                if (context.mounted) {
                  if (error == null) {
                    context.go('/login');
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(error),
                      backgroundColor: AppColors.danger,
                    ));
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
              child: const Text('Delete Account', style: TextStyle(color: AppColors.white)),
            ),
          ],
        ),
      ),
    );
    passwordCtrl.dispose();
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

  Widget _creditStat(String label, String value, Color color) {
    return Row(children: [
      Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      const SizedBox(width: 6),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
        child: Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
      ),
    ]);
  }
}

