import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
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
import '../presentation/screens/admin/instalments/admin_instalments_screen.dart';
import '../presentation/screens/customer/home/home_screen.dart';
import '../presentation/screens/customer/products/product_detail_screen.dart';
import '../presentation/screens/customer/cart/cart_screen.dart';
import '../presentation/screens/customer/checkout/checkout_screen.dart';
import '../presentation/screens/customer/orders/my_orders_screen.dart';
import '../presentation/screens/customer/orders/cancel_order_screen.dart';
import '../presentation/screens/customer/orders/instalment_detail_screen.dart';
import '../presentation/screens/customer/profile/profile_screen.dart';
import '../presentation/screens/customer/profile/edit_profile_screen.dart';
import '../presentation/screens/customer/orders/customer_instalments_screen.dart';
import '../presentation/screens/customer/checkout/payment_proof_screen.dart';

// Routes that require the user to be logged in
const _protectedPaths = [
  '/shop/checkout',
  '/shop/orders',
  '/shop/profile',
  '/shop/edit-profile',
  '/shop/instalments',
  '/shop/payment-proof',
  '/admin',
];

bool _requiresAuth(String location) {
  return _protectedPaths.any((p) => location.startsWith(p));
}

final router = GoRouter(
  initialLocation: kIsWeb ? '/shop' : '/login',
  redirect: (context, state) {
    final auth = context.read<AuthProvider>();
    final isLoggedIn = auth.isAuthenticated;
    final location = state.matchedLocation;
    final isAuthPage = location == '/login' || location == '/register';

    if (kIsWeb) {
      // WEB: Only protected routes require login
      if (!isLoggedIn && _requiresAuth(location)) return '/login';
      if (isLoggedIn && isAuthPage) {
        return auth.isAdmin ? '/admin/dashboard' : '/shop';
      }
    } else {
      // ANDROID: All routes require login (original behavior)
      if (!isLoggedIn && !isAuthPage) return '/login';
      if (isLoggedIn && isAuthPage) {
        return auth.isAdmin ? '/admin/dashboard' : '/shop';
      }
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
    GoRoute(path: '/admin/instalments', builder: (ctx, state) => const AdminInstalmentsScreen()),
    GoRoute(path: '/admin/reports', builder: (ctx, state) => const ReportsScreen()),

    // Customer Routes
    GoRoute(path: '/shop', builder: (ctx, state) => const HomeScreen()),
    GoRoute(path: '/shop/cart', builder: (ctx, state) => const CartScreen()),
    GoRoute(path: '/shop/checkout', builder: (ctx, state) => const CheckoutScreen()),
    GoRoute(path: '/shop/orders', builder: (ctx, state) => const MyOrdersScreen()),
    GoRoute(path: '/shop/orders/:id',
      builder: (ctx, state) => OrderDetailScreen(orderId: state.pathParameters['id']!)),
    GoRoute(path: '/shop/orders/:id/cancel',
      builder: (ctx, state) => CancelOrderScreen(orderId: state.pathParameters['id']!)),
    GoRoute(path: '/shop/orders/:id/instalment',
      builder: (ctx, state) => InstalmentDetailScreen(orderId: state.pathParameters['id']!)),
    GoRoute(path: '/shop/instalments', builder: (ctx, state) => const CustomerInstalmentsScreen()),
    GoRoute(path: '/shop/profile', builder: (ctx, state) => const ProfileScreen()),
    GoRoute(path: '/shop/edit-profile', builder: (ctx, state) => const EditProfileScreen()),
    GoRoute(
      path: '/shop/payment-proof/:orderId',
      builder: (ctx, state) {
        final extra = state.extra as Map<String, dynamic>? ?? {};
        return PaymentProofScreen(
          orderId: state.pathParameters['orderId']!,
          orderRef: extra['orderRef'] as String? ?? '',
          paymentMethod: extra['paymentMethod'] as String? ?? '',
          totalAmount: (extra['totalAmount'] as num?)?.toDouble() ?? 0.0,
          isDeliveryFee: extra['isDeliveryFee'] as bool? ?? false,
        );
      },
    ),
  ],
);
