import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:stleaf_trading/core/theme/app_colors.dart';
import 'package:stleaf_trading/providers/app_providers.dart';
import 'package:stleaf_trading/providers/auth_provider.dart';
import 'package:stleaf_trading/presentation/widgets/common/contact_support_widget.dart';
import 'package:stleaf_trading/presentation/widgets/auth/auth_dialog.dart';

class CustomerLayout extends StatelessWidget {
  final Widget child;
  final String currentRoute;

  const CustomerLayout({super.key, required this.child, required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: _CustomerAppBar(currentRoute: currentRoute),
      // On mobile, use an end-drawer for the cart slide-out
      endDrawer: isMobile ? const _CartDrawer() : null,
      body: child,
      floatingActionButton: (currentRoute == '/shop' || currentRoute.startsWith('/shop/orders'))
          ? const ContactSupportFAB()
          : null,
      bottomNavigationBar: isMobile ? _BottomNav(currentRoute: currentRoute) : null,
    );
  }
}

class _CustomerAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String currentRoute;
  const _CustomerAppBar({required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final auth = context.watch<AuthProvider>();
    final isLoggedIn = auth.isAuthenticated;
    final isWide = MediaQuery.of(context).size.width > 600;

    return AppBar(
      toolbarHeight: 75,
      backgroundColor: AppColors.white,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      centerTitle: true,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: AppColors.divider),
      ),
      title: InkWell(
        onTap: () => context.go('/shop'),
        borderRadius: BorderRadius.circular(8),
        child: Image.asset(
          'assets/images/logo.jpeg',
          height: isWide ? 56 : 48,
          fit: BoxFit.contain,
        ),
      ),
      actions: [
        if (isWide) ...[
          _NavLink(label: 'Products', route: '/shop', currentRoute: currentRoute),
          // On web, only show My Orders for logged-in users. On Android, always show (user is always logged in)
          if (!kIsWeb || isLoggedIn)
            _NavLink(label: 'My Orders', route: '/shop/orders', currentRoute: currentRoute),
        ],
        const SizedBox(width: 4),
        // Cart button
        Builder(builder: (ctx) {
          return IconButton(
            onPressed: () {
              if (!isWide) {
                Scaffold.of(ctx).openEndDrawer();
              } else {
                context.go('/shop/cart');
              }
            },
            icon: Badge(
              isLabelVisible: cart.itemCount > 0,
              label: Text('${cart.itemCount}'),
              backgroundColor: AppColors.primary,
              child: Icon(
                Icons.shopping_basket_rounded,
                color: AppColors.textPrimary,
                size: isWide ? 24 : 22,
              ),
            ),
          );
        }),
        // Auth actions — on web show Login/Register for guests; on Android always show profile avatar
        if (isLoggedIn)
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: PopupMenuButton<String>(
              offset: const Offset(0, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              onSelected: (val) async {
                if (val == 'profile') context.go('/shop/profile');
                if (val == 'orders') context.go('/shop/orders');
                if (val == 'admin') context.go('/admin/dashboard');
                if (val == 'logout') {
                  await context.read<AuthProvider>().logout();
                  // On web after logout, go to shop (guest browsing). On Android, go to login.
                  if (context.mounted) context.go(kIsWeb ? '/shop' : '/login');
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(value: 'profile', child: _menuItem(Icons.person_outline_rounded, 'My Profile')),
                PopupMenuItem(value: 'orders', child: _menuItem(Icons.receipt_long_rounded, 'My Orders')),
                // Show admin switch only for admin accounts
                if (auth.isAdmin) ...[
                  const PopupMenuDivider(),
                  PopupMenuItem(value: 'admin',
                    child: _menuItem(Icons.admin_panel_settings_rounded, 'Admin Dashboard', isGreen: true)),
                ],
                const PopupMenuDivider(),
                PopupMenuItem(value: 'logout', child: _menuItem(Icons.logout_rounded, 'Logout', isRed: true)),
              ],
              child: CircleAvatar(
                radius: isWide ? 18 : 15,
                backgroundColor: AppColors.mint,
                child: Text(
                  (auth.currentUser?.name != null && auth.currentUser!.name.isNotEmpty)
                      ? auth.currentUser!.name[0].toUpperCase()
                      : 'U',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: isWide ? 14 : 12,
                  ),
                ),
              ),
            ),
          )
        else if (kIsWeb) // Single 'Sign In' button on web for guests — opens popup dialog
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ElevatedButton(
              onPressed: () => showAuthDialog(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                elevation: 0,
              ),
              child: const Text('Sign In', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            ),
          ),
      ],
    );
  }

  Widget _menuItem(IconData icon, String label, {bool isRed = false, bool isGreen = false}) {
    final color = isRed
        ? AppColors.danger
        : isGreen
            ? const Color(0xFF2E7D32)
            : AppColors.textSecondary;
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(
          color: isRed ? AppColors.danger : isGreen ? const Color(0xFF2E7D32) : AppColors.textPrimary,
          fontSize: 14,
        )),
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

// ─── Slide-out Cart Drawer (Mobile) ──────────────────────────────
class _CartDrawer extends StatelessWidget {
  const _CartDrawer();

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    return Drawer(
      width: MediaQuery.of(context).size.width * 0.85,
      backgroundColor: AppColors.surface,
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              color: AppColors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.shopping_basket_rounded, color: AppColors.primary, size: 22),
                  const SizedBox(width: 10),
                  Text(
                    'My Cart (${cart.itemCount})',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.primary),
                  ),
                  const Spacer(),
                  // Close button
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.mint,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.close_rounded, size: 18, color: AppColors.primary),
                    ),
                  ),
                ],
              ),
            ),
            Container(height: 1, color: AppColors.divider),

            // Items
            Expanded(
              child: cart.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.shopping_basket_outlined, size: 48, color: AppColors.textMuted),
                          SizedBox(height: 12),
                          Text('Your cart is empty', style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: cart.items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (ctx, i) => _DrawerCartItem(item: cart.items[i]),
                    ),
            ),

            // Bottom summary + buttons
            if (!cart.isEmpty) ...[
              Container(height: 1, color: AppColors.divider),
              Container(
                color: AppColors.white,
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Subtotal', style: TextStyle(color: AppColors.textSecondary)),
                        Text('RM ${cart.subtotal.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          final auth = context.read<AuthProvider>();
                          Navigator.of(context).pop();
                          // On web, redirect guests to login. On Android, user is always logged in.
                          if (!kIsWeb || auth.isAuthenticated) {
                            context.go('/shop/checkout');
                          } else {
                            Navigator.of(context).pop(); // close drawer first
                            showAuthDialog(context);
                          }
                        },
                        icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                        label: const Text('Checkout'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          context.go('/shop/cart');
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          side: const BorderSide(color: AppColors.primary),
                        ),
                        child: const Text('View Full Cart'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DrawerCartItem extends StatelessWidget {
  final CartItem item;
  const _DrawerCartItem({required this.item});

  @override
  Widget build(BuildContext context) {
    final cart = context.read<CartProvider>();
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: AppColors.mint, borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.eco_rounded, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(item.product.name,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                maxLines: 1, overflow: TextOverflow.ellipsis),
              Text('RM ${item.selectedSize.effectivePrice.toStringAsFixed(2)} / ${item.selectedSize.unit}',
                style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
            ]),
          ),
          // Qty controls
          Row(children: [
            GestureDetector(
              onTap: () {
                final newQty = item.quantity - 1;
                if (newQty <= 0) {
                  cart.removeItem(item.product.id, item.selectedSize.unit);
                } else {
                  cart.updateQuantity(item.product.id, item.selectedSize.unit, newQty);
                }
              },
              child: Container(
                width: 24, height: 24,
                decoration: BoxDecoration(color: AppColors.mint, borderRadius: BorderRadius.circular(6)),
                child: const Icon(Icons.remove_rounded, size: 14, color: AppColors.primary),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                item.quantity == item.quantity.truncate()
                    ? item.quantity.toInt().toString()
                    : item.quantity.toStringAsFixed(1),
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
              ),
            ),
            GestureDetector(
              onTap: () => cart.updateQuantity(item.product.id, item.selectedSize.unit, item.quantity + 1),
              child: Container(
                width: 24, height: 24,
                decoration: BoxDecoration(color: AppColors.mint, borderRadius: BorderRadius.circular(6)),
                child: const Icon(Icons.add_rounded, size: 14, color: AppColors.primary),
              ),
            ),
          ]),
        ],
      ),
    );
  }
}

// ─── Bottom Navigation Bar ───────────────────────────────────────
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

    final auth = context.read<AuthProvider>();

    return NavigationBar(
      selectedIndex: index,
      onDestinationSelected: (i) {
        switch (i) {
          case 0: context.go('/shop'); break;
          case 1:
            // On web, show auth dialog for guests. On Android, user is always logged in.
            (!kIsWeb || auth.isAuthenticated) ? context.go('/shop/orders') : showAuthDialog(context);
            break;
          case 2: context.go('/shop/cart'); break;
          case 3:
            (!kIsWeb || auth.isAuthenticated) ? context.go('/shop/profile') : showAuthDialog(context);
            break;
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
