import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../presentation/screens/auth/login_screen.dart';
import '../presentation/screens/auth/register_screen.dart';
import '../presentation/screens/admin/dashboard_screen.dart';
import '../presentation/screens/admin/products/products_screen.dart';
import '../presentation/screens/admin/products/product_form_screen.dart';
import '../presentation/screens/admin/inventory/inventory_screen.dart';
import '../presentation/screens/admin/customers/customers_screen.dart';
import '../presentation/screens/admin/orders/admin_orders_screen.dart';
import '../presentation/screens/admin/delivery/delivery_screen.dart';
import '../presentation/screens/admin/reports/reports_screen.dart';
import '../presentation/screens/customer/home/home_screen.dart';
import '../presentation/screens/customer/products/product_detail_screen.dart';
import '../presentation/screens/customer/cart/cart_screen.dart';
import '../presentation/screens/customer/checkout/checkout_screen.dart';
import '../presentation/screens/customer/orders/my_orders_screen.dart';
import '../presentation/screens/customer/profile/profile_screen.dart';

final router = GoRouter(
  initialLocation: '/login',
  redirect: (context, state) {
    final auth = context.read<AuthProvider>();
    final isLoggedIn = auth.isAuthenticated;
    final isLoginPage = state.matchedLocation == '/login' || state.matchedLocation == '/register';

    if (!isLoggedIn && !isLoginPage) return '/login';
    if (isLoggedIn && isLoginPage) {
      return auth.isAdmin ? '/admin/dashboard' : '/shop';
    }
    return null;
  },
  routes: [
    // Auth
    GoRoute(path: '/login', builder: (ctx, state) => const LoginScreen()),
    GoRoute(path: '/register', builder: (ctx, state) => const RegisterScreen()),

    // Admin Routes
    GoRoute(path: '/admin/dashboard', builder: (ctx, state) => const DashboardScreen()),
    GoRoute(path: '/admin/products', builder: (ctx, state) => const ProductsScreen()),
    GoRoute(path: '/admin/products/new', builder: (ctx, state) => const ProductFormScreen()),
    GoRoute(path: '/admin/products/:id/edit',
      builder: (ctx, state) => ProductFormScreen(productId: state.pathParameters['id'])),
    GoRoute(path: '/admin/inventory', builder: (ctx, state) => const InventoryScreen()),
    GoRoute(path: '/admin/customers', builder: (ctx, state) => const CustomersScreen()),
    GoRoute(path: '/admin/customers/:id',
      builder: (ctx, state) => CustomerDetailScreen(customerId: state.pathParameters['id']!)),
    GoRoute(path: '/admin/orders', builder: (ctx, state) => const AdminOrdersScreen()),
    GoRoute(path: '/admin/orders/:id',
      builder: (ctx, state) => AdminOrderDetailScreen(orderId: state.pathParameters['id']!)),
    GoRoute(path: '/admin/delivery', builder: (ctx, state) => const DeliveryScreen()),
    GoRoute(path: '/admin/reports', builder: (ctx, state) => const ReportsScreen()),

    // Customer Routes
    GoRoute(path: '/shop', builder: (ctx, state) => const HomeScreen()),
    GoRoute(path: '/shop/products/:id',
      builder: (ctx, state) => ProductDetailScreen(productId: state.pathParameters['id']!)),
    GoRoute(path: '/shop/cart', builder: (ctx, state) => const CartScreen()),
    GoRoute(path: '/shop/checkout', builder: (ctx, state) => const CheckoutScreen()),
    GoRoute(path: '/shop/orders', builder: (ctx, state) => const MyOrdersScreen()),
    GoRoute(path: '/shop/orders/:id',
      builder: (ctx, state) => OrderDetailScreen(orderId: state.pathParameters['id']!)),
    GoRoute(path: '/shop/profile', builder: (ctx, state) => const ProfileScreen()),
  ],
);
