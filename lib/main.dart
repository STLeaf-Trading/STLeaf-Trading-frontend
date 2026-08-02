import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/app_providers.dart';
import 'routes/app_router.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AppInitializer());
}

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  late Future<void> _initFuture;
  AuthProvider? _authProvider;
  GoRouter? _router;

  @override
  void initState() {
    super.initState();
    _initFuture = _initializeServices();
  }

  Future<void> _initializeServices() async {
    debugPrint("ST_DEBUG: Loading dotenv...");
    await dotenv.load(fileName: ".env");

    debugPrint("ST_DEBUG: Initializing Firebase...");
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (e) {
      if (!e.toString().contains('duplicate-app')) {
        rethrow;
      }
    }


    debugPrint("ST_DEBUG: Initializing AuthProvider...");
    _authProvider = AuthProvider();
    await _authProvider!.init();

    // Resolve the startup route now that auth is known.
    final initialLocation = await resolveInitialLocation(
      _authProvider!.isAuthenticated,
      _authProvider!.isAdmin,
    );
    _router = buildRouter(initialLocation);
    debugPrint("ST_DEBUG: Initial location resolved to: $initialLocation");
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const MaterialApp(
            home: Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          );
        } else if (snapshot.hasError) {
          return MaterialApp(
            home: Scaffold(
              body: Center(
                child: Text('Error initializing app: ${snapshot.error}', textDirection: TextDirection.ltr),
              ),
            ),
          );
        }

        return MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: _authProvider!),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => CustomerProvider()),
        ChangeNotifierProvider(create: (_) => InventoryProvider()),
        ChangeNotifierProvider(create: (_) => DeliveryProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
            ChangeNotifierProvider(create: (_) => InstalmentProvider()),
            ChangeNotifierProvider(create: (_) => CategoryProvider()),
          ],
          child: STLeafApp(router: _router!),
        );
      },
    );
  }
}

class STLeafApp extends StatefulWidget {
  final GoRouter router;
  const STLeafApp({super.key, required this.router});

  @override
  State<STLeafApp> createState() => _STLeafAppState();
}

class _STLeafAppState extends State<STLeafApp> {
  String? _lastLoadedUid;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    // When a customer logs in, load their persisted cart
    final uid = auth.currentUser?.id;
    if (uid != null && uid != _lastLoadedUid) {
      _lastLoadedUid = uid;
      // Load products, categories, then cart (customers only)
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        final products = context.read<ProductProvider>();
        final categories = context.read<CategoryProvider>();
        await Future.wait([
          products.loadProducts(),
          categories.loadCategories(),
        ]);
        if (auth.isCustomer) {
          final cart = context.read<CartProvider>();
          await cart.loadCart(uid, products.allProducts);
        }
      });
    }
    // When user logs out, clear cart state
    if (uid == null && _lastLoadedUid != null) {
      _lastLoadedUid = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.read<CartProvider>().setUid(null);
      });
    }

    return MaterialApp.router(
      title: 'ST Leaf Trading',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: widget.router,
    );
  }
}
