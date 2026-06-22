import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:stleaf_trading/core/theme/app_colors.dart';
import 'package:stleaf_trading/providers/auth_provider.dart';

class AdminLayout extends StatelessWidget {
  final Widget child;
  final String currentRoute;

  const AdminLayout({super.key, required this.child, required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 900;

    if (isWide) {
      return Scaffold(
        backgroundColor: AppColors.surface,
        body: Row(
          children: [
            _Sidebar(currentRoute: currentRoute),
            Expanded(child: child),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: _MobileAppBar(currentRoute: currentRoute),
      drawer: Drawer(
        backgroundColor: AppColors.sidebarBg,
        child: _SidebarContent(currentRoute: currentRoute),
      ),
      body: child,
    );
  }
}

class _Sidebar extends StatelessWidget {
  final String currentRoute;
  const _Sidebar({required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      height: double.infinity,
      color: AppColors.sidebarBg,
      child: _SidebarContent(currentRoute: currentRoute),
    );
  }
}

class _SidebarContent extends StatelessWidget {
  final String currentRoute;
  const _SidebarContent({required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final items = [
      _SidebarItem(icon: Icons.dashboard_rounded, label: 'Dashboard', route: '/admin/dashboard'),
      _SidebarItem(icon: Icons.inventory_2_rounded, label: 'Products', route: '/admin/products'),
      _SidebarItem(icon: Icons.warehouse_rounded, label: 'Inventory', route: '/admin/inventory'),
      _SidebarItem(icon: Icons.people_rounded, label: 'Customers', route: '/admin/customers'),
      _SidebarItem(icon: Icons.receipt_long_rounded, label: 'Orders', route: '/admin/orders'),
      _SidebarItem(icon: Icons.local_shipping_rounded, label: 'Delivery', route: '/admin/delivery'),
      _SidebarItem(icon: Icons.account_balance_wallet_rounded, label: 'Instalments', route: '/admin/instalments'),
      _SidebarItem(icon: Icons.bar_chart_rounded, label: 'Reports', route: '/admin/reports'),
    ];

    return Column(
      children: [
        // Logo
        Container(
          padding: const EdgeInsets.fromLTRB(20, 48, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.accent, borderRadius: BorderRadius.circular(12),
                    ),
                    child: ClipRRect(borderRadius: BorderRadius.circular(6), child: Image.asset('assets/images/logo.jpeg', width: 22, height: 22, fit: BoxFit.cover)),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ST Leaf', style: TextStyle(color: AppColors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                      Text('Trading', style: TextStyle(color: AppColors.sidebarText, fontSize: 11)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 16, backgroundColor: AppColors.accent,
                      child: Icon(Icons.person_rounded, size: 16, color: AppColors.white),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            auth.currentUser?.name ?? 'Admin',
                            style: const TextStyle(color: AppColors.white, fontSize: 12, fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const Text('Administrator', style: TextStyle(color: AppColors.sidebarText, fontSize: 10)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const Divider(color: Colors.white12, height: 1),
        const SizedBox(height: 8),

        // Nav items
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            itemCount: items.length,
            itemBuilder: (ctx, i) {
              final item = items[i];
              final isActive = currentRoute.startsWith(item.route);
              return _NavItem(item: item, isActive: isActive);
            },
          ),
        ),

        // Logout
        const Divider(color: Colors.white12, height: 1),
        Padding(
          padding: const EdgeInsets.all(12),
          child: InkWell(
            onTap: () async {
              await context.read<AuthProvider>().logout();
              if (context.mounted) context.go('/login');
            },
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: const Row(
                children: [
                  Icon(Icons.logout_rounded, color: Color(0xFFEF9A9A), size: 20),
                  SizedBox(width: 12),
                  Text('Logout', style: TextStyle(color: Color(0xFFEF9A9A), fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _SidebarItem {
  final IconData icon;
  final String label;
  final String route;
  const _SidebarItem({required this.icon, required this.label, required this.route});
}

class _NavItem extends StatefulWidget {
  final _SidebarItem item;
  final bool isActive;
  const _NavItem({required this.item, required this.isActive});

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.symmetric(vertical: 2),
        decoration: BoxDecoration(
          color: widget.isActive
              ? AppColors.sidebarActive
              : _hovered ? AppColors.sidebarHover : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: ListTile(
          dense: true,
          leading: Icon(widget.item.icon,
            color: widget.isActive ? AppColors.white : AppColors.sidebarText, size: 20),
          title: Text(widget.item.label,
            style: TextStyle(
              color: widget.isActive ? AppColors.white : AppColors.sidebarText,
              fontWeight: widget.isActive ? FontWeight.w600 : FontWeight.w400,
              fontSize: 14,
            ),
          ),
          onTap: () => context.go(widget.item.route),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
}

class _MobileAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String currentRoute;
  const _MobileAppBar({required this.currentRoute});

  String get _title {
    if (currentRoute.contains('dashboard')) return 'Dashboard';
    if (currentRoute.contains('products')) return 'Products';
    if (currentRoute.contains('inventory')) return 'Inventory';
    if (currentRoute.contains('customers')) return 'Customers';
    if (currentRoute.contains('orders')) return 'Orders';
    if (currentRoute.contains('delivery')) return 'Delivery';
    if (currentRoute.contains('instalments')) return 'Instalments';
    if (currentRoute.contains('reports')) return 'Reports';
    return 'ST Leaf Admin';
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.sidebarBg,
      foregroundColor: AppColors.white,
      title: Text(_title, style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w700)),
      iconTheme: const IconThemeData(color: AppColors.white),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

