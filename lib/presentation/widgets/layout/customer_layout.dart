import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:stleaf_trading/core/theme/app_colors.dart';
import 'package:stleaf_trading/providers/app_providers.dart';
import 'package:stleaf_trading/providers/auth_provider.dart';

class CustomerLayout extends StatelessWidget {
  final Widget child;
  final String currentRoute;

  const CustomerLayout({super.key, required this.child, required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: _CustomerAppBar(currentRoute: currentRoute),
      body: child,
      bottomNavigationBar: MediaQuery.of(context).size.width < 600
          ? _BottomNav(currentRoute: currentRoute)
          : null,
    );
  }
}

class _CustomerAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String currentRoute;
  const _CustomerAppBar({required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final auth = context.read<AuthProvider>();
    final isWide = MediaQuery.of(context).size.width > 600;

    return AppBar(
      backgroundColor: AppColors.white,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: AppColors.divider),
      ),
      titleSpacing: 20,
      title: InkWell(
        onTap: () => context.go('/shop'),
        borderRadius: BorderRadius.circular(8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.eco_rounded, color: AppColors.white, size: 18),
            ),
            const SizedBox(width: 10),
            const Text('ST Leaf', style: TextStyle(
              color: AppColors.primary, fontSize: 18, fontWeight: FontWeight.w800,
            )),
          ],
        ),
      ),
      actions: [
        if (isWide) ...[
          _NavLink(label: 'Products', route: '/shop', currentRoute: currentRoute),
          _NavLink(label: 'My Orders', route: '/shop/orders', currentRoute: currentRoute),
        ],
        const SizedBox(width: 8),
        // Cart
        IconButton(
          onPressed: () => context.go('/shop/cart'),
          icon: Badge(
            isLabelVisible: cart.itemCount > 0,
            label: Text('${cart.itemCount}'),
            backgroundColor: AppColors.primary,
            child: const Icon(Icons.shopping_basket_rounded, color: AppColors.textPrimary),
          ),
        ),
        // Profile
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: PopupMenuButton<String>(
            offset: const Offset(0, 50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onSelected: (val) async {
              if (val == 'profile') context.go('/shop/profile');
              if (val == 'orders') context.go('/shop/orders');
              if (val == 'logout') {
                await context.read<AuthProvider>().logout();
                if (context.mounted) context.go('/login');
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(value: 'profile', child: _menuItem(Icons.person_outline_rounded, 'My Profile')),
              PopupMenuItem(value: 'orders', child: _menuItem(Icons.receipt_long_rounded, 'My Orders')),
              const PopupMenuDivider(),
              PopupMenuItem(value: 'logout', child: _menuItem(Icons.logout_rounded, 'Logout', isRed: true)),
            ],
            child: CircleAvatar(
              radius: 18, backgroundColor: AppColors.mint,
              child: Text(
                (auth.currentUser?.name ?? 'U')[0].toUpperCase(),
                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 14),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _menuItem(IconData icon, String label, {bool isRed = false}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: isRed ? AppColors.danger : AppColors.textSecondary),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(color: isRed ? AppColors.danger : AppColors.textPrimary, fontSize: 14)),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 1);
}

class _NavLink extends StatelessWidget {
  final String label;
  final String route;
  final String currentRoute;
  const _NavLink({required this.label, required this.route, required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    final isActive = currentRoute.startsWith(route);
    return TextButton(
      onPressed: () => context.go(route),
      style: TextButton.styleFrom(
        foregroundColor: isActive ? AppColors.primary : AppColors.textSecondary,
      ),
      child: Text(label, style: TextStyle(
        fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
        fontSize: 14,
      )),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final String currentRoute;
  const _BottomNav({required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    int index = 0;
    if (currentRoute.startsWith('/shop/orders')) index = 1;
    if (currentRoute.startsWith('/shop/cart')) index = 2;
    if (currentRoute.startsWith('/shop/profile')) index = 3;

    return NavigationBar(
      selectedIndex: index,
      onDestinationSelected: (i) {
        switch (i) {
          case 0: context.go('/shop'); break;
          case 1: context.go('/shop/orders'); break;
          case 2: context.go('/shop/cart'); break;
          case 3: context.go('/shop/profile'); break;
        }
      },
      backgroundColor: AppColors.white,
      indicatorColor: AppColors.mint,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.black12,
      elevation: 8,
      destinations: [
        const NavigationDestination(icon: Icon(Icons.storefront_rounded), label: 'Shop'),
        const NavigationDestination(icon: Icon(Icons.receipt_long_rounded), label: 'Orders'),
        NavigationDestination(
          icon: Badge(
            isLabelVisible: cart.itemCount > 0,
            label: Text('${cart.itemCount}'),
            backgroundColor: AppColors.primary,
            child: const Icon(Icons.shopping_basket_rounded),
          ),
          label: 'Cart',
        ),
        const NavigationDestination(icon: Icon(Icons.person_rounded), label: 'Profile'),
      ],
    );
  }
}
