import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/app_providers.dart';
import 'providers/settings_provider.dart';
import 'routes/app_router.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final authProvider = AuthProvider();
  await authProvider.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => CustomerProvider()),
        ChangeNotifierProvider(create: (_) => InventoryProvider()),
        ChangeNotifierProvider(create: (_) => DeliveryProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => InstalmentProvider()),
      ],
      child: const STLeafApp(),
    ),
  );
}

class STLeafApp extends StatefulWidget {
  const STLeafApp({super.key});

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
      // Load products first, then cart (only if customer)
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        final products = context.read<ProductProvider>();
        await products.loadProducts();
        
        // Ensure settings re-sync after authentication
        context.read<SettingsProvider>().loadSettings();
        
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
      routerConfig: router,
    );
  }
}
