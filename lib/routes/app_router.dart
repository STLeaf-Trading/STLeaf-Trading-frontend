import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/auth_provider.dart';
import '../presentation/screens/auth/login_screen.dart';
import '../presentation/screens/auth/register_screen.dart';
import '../presentation/screens/admin/dashboard_screen.dart';
import '../presentation/screens/admin/products/products_screen.dart';
import '../presentation/screens/admin/products/product_form_screen.dart';
import '../presentation/screens/admin/inventory/inventory_screen.dart';
import '../presentation/screens/admin/customers/customers_screen.dart';
import '../presentation/screens/admin/orders/admin_orders_screen.dart';
import '../presentation/screens/admin/orders/admin_manage_order_screen.dart';
import '../presentation/screens/admin/delivery/delivery_screen.dart';
import '../presentation/screens/admin/reports/reports_screen.dart';
import '../presentation/screens/admin/instalments/admin_instalments_screen.dart';
import '../presentation/screens/customer/home/home_screen.dart';
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

// Routes that should NOT be persisted as "last page" (e.g. auth screens)
const _nonPersistPaths = ['/login', '/register'];

bool _requiresAuth(String location) {
  return _protectedPaths.any((p) => location.startsWith(p));
}

// ── Route Persistence ──────────────────────────────────────────────────────
const _kLastRouteKey = 'last_route';

/// Saves [location] to SharedPreferences so it survives app restarts.
void saveLastRoute(String location) async {
  if (_nonPersistPaths.any((p) => location.startsWith(p))) return;
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLastRouteKey, location);
  } catch (_) {}
}

/// Reads the previously saved route. Returns null if none was stored.
Future<String?> loadLastRoute() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kLastRouteKey);
  } catch (_) {
    return null;
  }
}

/// A [NavigatorObserver] that persists every route change.
/// Note: GoRouter v14 sets route names so this works correctly.
class _RoutePersistenceObserver extends NavigatorObserver {
  @override
  void didPush(Route route, Route? previousRoute) {
    _persist(route);
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    if (newRoute != null) _persist(newRoute);
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    if (previousRoute != null) _persist(previousRoute);
  }

  void _persist(Route route) {
    final name = route.settings.name;
    if (name != null && name.isNotEmpty) {
      saveLastRoute(name);
    }
  }
}

/// Call this once at startup (before [router] is used) to get the correct
/// initial location for the current platform.
Future<String> resolveInitialLocation(
    bool isAuthenticated, bool isAdmin) async {
  if (kIsWeb) {
    // Explicitly pass the browser's current path as initialLocation so
    // GoRouter starts there directly (avoids it briefly landing on a fallback
    // and triggering a spurious redirect to /shop).
    final browserPath = Uri.base.path;
    if (browserPath.isNotEmpty && browserPath != '/') {
      return browserPath;
    }
    // Root path '/' — send to the appropriate default page.
    if (isAuthenticated) {
      return isAdmin ? '/admin/dashboard' : '/shop';
    }
    return '/shop'; // Public landing page; redirect guard will handle unauth access
  }
  // On mobile, restore the last-visited route (if the user is still authenticated).
  if (isAuthenticated) {
    final saved = await loadLastRoute();
    if (saved != null && saved.isNotEmpty) {
      // Safety: don't restore a protected route if auth state changed
      if (_requiresAuth(saved) && !isAuthenticated) return '/login';
      return saved;
    }
    return isAdmin ? '/admin/dashboard' : '/shop';
  }
  return '/login';
}

GoRouter buildRouter(String initialLocation) {
  final goRouter = GoRouter(
    initialLocation: initialLocation,
    observers: [_RoutePersistenceObserver()],
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
      GoRoute(
          path: '/register', builder: (ctx, state) => const RegisterScreen()),

      // Admin Routes
      GoRoute(
          path: '/admin/dashboard',
          builder: (ctx, state) => const DashboardScreen()),
      GoRoute(
          path: '/admin/products',
          builder: (ctx, state) => const ProductsScreen()),
      GoRoute(
          path: '/admin/products/new',
          builder: (ctx, state) => const ProductFormScreen()),
      GoRoute(
          path: '/admin/products/:id/edit',
          builder: (ctx, state) =>
              ProductFormScreen(productId: state.pathParameters['id'])),
      GoRoute(
          path: '/admin/inventory',
          builder: (ctx, state) => const InventoryScreen()),
      GoRoute(
          path: '/admin/customers',
          builder: (ctx, state) => const CustomersScreen()),
      GoRoute(
          path: '/admin/customers/:id',
          builder: (ctx, state) =>
              CustomerDetailScreen(customerId: state.pathParameters['id']!)),
      GoRoute(
          path: '/admin/orders',
          builder: (ctx, state) => const AdminOrdersScreen()),
      GoRoute(
          path: '/admin/orders/:id',
          builder: (ctx, state) =>
              AdminOrderDetailScreen(orderId: state.pathParameters['id']!)),
      GoRoute(
          path: '/admin/delivery',
          builder: (ctx, state) => const DeliveryScreen()),
      GoRoute(
          path: '/admin/instalments',
          builder: (ctx, state) => const AdminInstalmentsScreen()),
      GoRoute(
          path: '/admin/reports',
          builder: (ctx, state) => const ReportsScreen()),
      GoRoute(
          path: '/admin/manage-order',
          builder: (ctx, state) => const AdminManageOrderScreen()),

      // Customer Routes
      GoRoute(path: '/shop', builder: (ctx, state) => const HomeScreen()),
      GoRoute(path: '/shop/cart', builder: (ctx, state) => const CartScreen()),
      GoRoute(
          path: '/shop/checkout',
          builder: (ctx, state) => const CheckoutScreen()),
      GoRoute(
          path: '/shop/orders',
          builder: (ctx, state) => const MyOrdersScreen()),
      GoRoute(
          path: '/shop/orders/:id',
          builder: (ctx, state) =>
              OrderDetailScreen(orderId: state.pathParameters['id']!)),
      GoRoute(
          path: '/shop/orders/:id/cancel',
          builder: (ctx, state) =>
              CancelOrderScreen(orderId: state.pathParameters['id']!)),
      GoRoute(
          path: '/shop/orders/:id/instalment',
          builder: (ctx, state) =>
              InstalmentDetailScreen(orderId: state.pathParameters['id']!)),
      GoRoute(
          path: '/shop/instalments',
          builder: (ctx, state) => const CustomerInstalmentsScreen()),
      GoRoute(
          path: '/shop/profile',
          builder: (ctx, state) => const ProfileScreen()),
      GoRoute(
          path: '/shop/edit-profile',
          builder: (ctx, state) => const EditProfileScreen()),
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

  // Also listen via GoRouter's own delegate for maximum reliability.
  // GoRouter fires notifyListeners() on every location change, and
  // routerDelegate.currentConfiguration holds the current RouteInformation.
  goRouter.routerDelegate.addListener(() {
    final location =
        goRouter.routerDelegate.currentConfiguration.uri.toString();
    if (location.isNotEmpty) saveLastRoute(location);
  });

  return goRouter;
}

// Legacy top-level router — kept for backward compatibility.
// Prefer calling buildRouter() after resolveInitialLocation().
final router = buildRouter(kIsWeb ? '/shop' : '/login');
