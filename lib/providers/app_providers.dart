import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../data/models/product_model.dart';
import '../data/models/customer_model.dart';
import '../data/models/order_model.dart';
import '../data/models/instalment_model.dart';
import 'dart:typed_data';
import '../data/models/inventory_model.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../core/constants/app_constants.dart';

// PRODUCT PROVIDER
class ProductProvider extends ChangeNotifier {
  final FirebaseFirestore _db;
  ProductProvider({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;
  List<ProductModel> _products = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String _selectedCategory = 'All';
  StreamSubscription? _sub;

  List<ProductModel> get products => _filtered;
  List<ProductModel> get allProducts => _products;
  bool get isLoading => _isLoading;
  String get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;

  List<String> get dynamicCategories {
    final Set<String> cats = {'All'};
    cats.addAll(AppConstants.productCategories);
    for (var p in _products) {
      if (p.category.isNotEmpty) cats.add(p.category);
    }
    // Remove legacy mock categories so they don't pollute the filter
    cats.removeAll({'Leafy Greens', 'Root Vegetables', 'Herbs'});
    return cats.toList();
  }

  List<ProductModel> get _filtered {
    return _products.where((p) {
      final matchesCategory = _selectedCategory == 'All' || p.category == _selectedCategory;
      final matchesSearch = _searchQuery.isEmpty ||
          p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.itemCode.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  Future<void> loadProducts() async {
    _isLoading = true;
    notifyListeners();
    _sub?.cancel();
    _sub = _db.collection('products').snapshots().listen((snap) {
      _products = snap.docs.map((doc) => ProductModel.fromFirestore(doc)).toList();
      _isLoading = false;
      notifyListeners();
    });
  }

  void setSearch(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  Future<void> addProduct(ProductModel product) async {
    await _db.collection('products').add(product.toJson());
  }

  Future<void> updateProduct(ProductModel updated) async {
    await _db.collection('products').doc(updated.id).update(updated.toJson());
  }

  Future<void> deleteProduct(String id) async {
    await _db.collection('products').doc(id).delete();
  }

  bool isItemCodeUnique(String code, String? excludeId) {
    return !_products.any((p) => p.itemCode.toLowerCase() == code.toLowerCase() && p.id != excludeId);
  }

  Future<String?> uploadProductImage(Uint8List fileBytes, String fileName) async {
    try {
      final ref = FirebaseStorage.instance.ref().child('products/$fileName');
      final metadata = SettableMetadata(contentType: 'image/jpeg');
      await ref.putData(fileBytes, metadata);
      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint('Image upload error: $e');
      return null;
    }
  }

  List<ProductModel> get lowStockProducts => _products.where((p) => p.isLowStock).toList();
  
  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

// CART PROVIDER
class CartItem {
  final ProductModel product;
  double quantity;
  final String? remarks;
  CartItem({required this.product, required this.quantity, this.remarks});
  double get subtotal => product.effectivePrice * quantity;
}

class CartProvider extends ChangeNotifier {
  final FirebaseFirestore _db;
  CartProvider({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;
  final List<CartItem> _items = [];
  String? _uid;

  List<CartItem> get items => _items;
  int get itemCount => _items.length;
  double get subtotal => _items.fold(0, (sum, i) => sum + i.subtotal);
  double get total => subtotal;
  bool get isEmpty => _items.isEmpty;

  /// Call this after login with all loaded products so we can reconstruct cart items.
  Future<void> loadCart(String uid, List<ProductModel> allProducts) async {
    _uid = uid;
    try {
      final doc = await _db.collection('carts').doc(uid).get();
      if (!doc.exists) return;
      final data = doc.data() as Map<String, dynamic>? ?? {};
      final rawItems = data['items'] as List<dynamic>? ?? [];
      _items.clear();
      for (final raw in rawItems) {
        final productId = raw['productId'] as String? ?? '';
        final quantity = (raw['quantity'] as num?)?.toDouble() ?? 1.0;
        final remarks = raw['remarks'] as String?;
        // Match against loaded products
        final product = allProducts.firstWhere(
          (p) => p.id == productId,
          orElse: () => ProductModel(
            id: productId,
            itemCode: raw['itemCode'] ?? '',
            name: raw['productName'] ?? 'Product',
            category: '',
            description: '',
            precaution: '',
            price: (raw['price'] as num?)?.toDouble() ?? 0,
            packType: raw['packType'] ?? 'kg',
            weightKg: (raw['weightKg'] as num?)?.toDouble() ?? 1.0,
            stockQuantity: 0,
            freshnessLevel: 5,
            promotionPrice: null,
            imageUrl: raw['imageUrl'],
            lowStockLevel: 5,
            status: 'Active',
          ),
        );
        final idx = _items.indexWhere((i) => i.product.id == productId && i.remarks == remarks);
        if (idx != -1) {
          _items[idx].quantity += quantity;
        } else {
          _items.add(CartItem(product: product, quantity: quantity, remarks: remarks));
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint('CartProvider.loadCart error: $e');
    }
  }

  Future<void> _saveCart() async {
    if (_uid == null) return;
    try {
      final itemsJson = _items.map((i) => {
        'productId': i.product.id,
        'productName': i.product.name,
        'itemCode': i.product.itemCode,
        'price': i.product.effectivePrice,
        'packType': i.product.packType,
        'weightKg': i.product.weightKg,
        'imageUrl': i.product.imageUrl,
        'quantity': i.quantity,
        if (i.remarks != null && i.remarks!.isNotEmpty) 'remarks': i.remarks,
      }).toList();
      await _db.collection('carts').doc(_uid).set({'items': itemsJson, 'updatedAt': FieldValue.serverTimestamp()});
    } catch (e) {
      debugPrint('CartProvider._saveCart error: $e');
    }
  }

  void addToCart(ProductModel product, {double quantity = 1.0, String? remarks}) {
    if (!product.isActive || product.isOutOfStock) {
      throw Exception('This product is currently unavailable.');
    }

    final idx = _items.indexWhere((i) => i.product.id == product.id && i.remarks == remarks);
    if (idx != -1) {
      if (_items[idx].quantity + quantity > product.stockQuantity) {
        throw Exception('Cannot add more. Max stock available: ${product.stockQuantity}');
      }
      _items[idx].quantity += quantity;
    } else {
      if (quantity > product.stockQuantity) {
        throw Exception('Cannot add more. Max stock available: ${product.stockQuantity}');
      }
      _items.add(CartItem(product: product, quantity: quantity, remarks: remarks));
    }
    notifyListeners();
    _saveCart();
  }

  void updateQuantity(String productId, double qty) {
    final idx = _items.indexWhere((i) => i.product.id == productId);
    if (idx != -1) {
      if (qty <= 0) {
        _items.removeAt(idx);
      } else {
        if (qty > _items[idx].product.stockQuantity) {
          throw Exception('Max stock available: ${_items[idx].product.stockQuantity}');
        }
        _items[idx].quantity = qty;
      }
      notifyListeners();
      _saveCart();
    }
  }

  void removeItem(String productId) {
    _items.removeWhere((i) => i.product.id == productId);
    notifyListeners();
    _saveCart();
  }

  Future<void> clear() async {
    _items.clear();
    notifyListeners();
    if (_uid != null) {
      try {
        await _db.collection('carts').doc(_uid).delete();
      } catch (e) {
        debugPrint('CartProvider.clear error: $e');
      }
    }
  }

  void setUid(String? uid) {
    if (uid == null) {
      _uid = null;
      _items.clear();
      notifyListeners();
    }
  }
}

// ORDER PROVIDER
class OrderProvider extends ChangeNotifier {
  final FirebaseFirestore _db;
  OrderProvider({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;
  List<OrderModel> _orders = [];
  bool _isLoading = false;
  String _statusFilter = 'All';
  StreamSubscription? _sub;

  bool get isLoading => _isLoading;
  String get statusFilter => _statusFilter;

  List<OrderModel> get _visibleOrders {
    final now = DateTime.now();
    return _orders.where((o) {
      if (o.orderStatus == 'Delivered') {
        // Hide if more than 1 day has passed since scheduled delivery date
        final endOfDeliveryDay = DateTime(o.deliveryDate.year, o.deliveryDate.month, o.deliveryDate.day, 23, 59, 59);
        if (now.isAfter(endOfDeliveryDay.add(const Duration(days: 1)))) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  List<OrderModel> get orders {
    if (_statusFilter == 'All') return _visibleOrders;
    return _visibleOrders.where((o) => o.orderStatus == _statusFilter).toList();
  }
  
  List<OrderModel> get allOrders => _visibleOrders;

  Future<void> loadOrders({String? customerId}) async {
    _isLoading = true;
    notifyListeners();
    _sub?.cancel();
    
    Query query = _db.collection('orders').orderBy('createdAt', descending: true);
    if (customerId != null) {
      query = query.where('customerId', isEqualTo: customerId);
    }
    
    _sub = query.snapshots().listen((snap) {
      _orders = snap.docs.map((doc) => OrderModel.fromFirestore(doc)).toList();
      _isLoading = false;
      notifyListeners();
    });
  }

  void setStatusFilter(String status) {
    _statusFilter = status;
    notifyListeners();
  }

  Future<OrderModel?> placeOrder(OrderModel order) async {
    // 1. Validate stock availability before proceeding
    for (final item in order.items) {
      final pDoc = await _db.collection('products').doc(item.productId).get();
      if (!pDoc.exists) throw Exception('Product ${item.productName} no longer exists.');
      final pData = pDoc.data()!;
      final currentStock = (pData['stockQuantity'] ?? 0) as int;
      final status = pData['status'] as String? ?? 'Active';
      if (status == 'Inactive') {
        throw Exception('Product ${item.productName} is currently unavailable.');
      }
      if (currentStock < item.quantity.toInt()) {
        throw Exception('Insufficient stock for ${item.productName}. Only $currentStock available.');
      }
    }

    final Map<String, dynamic> data = order.toJson();
    data['createdAt'] = FieldValue.serverTimestamp();
    final docRef = await _db.collection('orders').add(data);
    
    // 2. Decrement stock
    final batch = _db.batch();
    for (final item in order.items) {
      final pRef = _db.collection('products').doc(item.productId);
      batch.update(pRef, {
        'stockQuantity': FieldValue.increment(-item.quantity.toInt()),
      });
    }
    await batch.commit();

    return OrderModel(
      id: docRef.id,
      orderId: order.orderId,
      customerId: order.customerId,
      customerName: order.customerName,
      orderDate: order.orderDate,
      deliveryDate: order.deliveryDate,
      subtotal: order.subtotal,
      deliveryFee: order.deliveryFee,
      totalAmount: order.totalAmount,
      paymentMethod: order.paymentMethod,
      paymentStatus: order.paymentStatus,
      orderStatus: order.orderStatus,
      items: order.items,
    );
  }

  Future<void> updateStatus(String orderId, String status) async {
    await _db.collection('orders').doc(orderId).update({'orderStatus': status});
  }

  Future<void> updatePaymentStatus(String orderId, String status) async {
    await _db.collection('orders').doc(orderId).update({'paymentStatus': status});
  }

  Future<void> cancelOrder(String orderId, String reason) async {
    await _db.collection('orders').doc(orderId).update({
      'orderStatus': 'Cancelled',
      'cancellationReason': reason,
      'cancelledAt': FieldValue.serverTimestamp(),
    });
  }
  
  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

// CUSTOMER PROVIDER
class CustomerProvider extends ChangeNotifier {
  final FirebaseFirestore _db;
  CustomerProvider({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;
  List<CustomerModel> _customers = [];
  bool _isLoading = false;
  String _searchQuery = '';
  StreamSubscription? _sub;

  List<CustomerModel> get customers => _filtered;
  bool get isLoading => _isLoading;

  List<CustomerModel> get _filtered {
    if (_searchQuery.isEmpty) return _customers;
    return _customers.where((c) =>
      c.companyName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
      c.customerCode.toLowerCase().contains(_searchQuery.toLowerCase()) ||
      c.contactPerson.toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();
  }

  Future<void> loadCustomers() async {
    _isLoading = true;
    notifyListeners();
    _sub?.cancel();
    _sub = _db.collection('customers').snapshots().listen((snap) {
      _customers = snap.docs.map((doc) => CustomerModel.fromFirestore(doc)).toList();
      _isLoading = false;
      notifyListeners();
    });
  }

  void setSearch(String q) {
    _searchQuery = q;
    notifyListeners();
  }

  Future<void> updateCustomerProfile({
    required String uid,
    required String companyName,
    required String contactPerson,
    required String phone,
    required String address,
  }) async {
    await Future.wait([
      _db.collection('users').doc(uid).update({'name': contactPerson}),
      _db.collection('customers').doc(uid).update({
        'companyName': companyName,
        'contactPerson': contactPerson,
        'phoneNumber': phone,
        'address': address,
      }),
    ]);
  }

  Future<void> addCustomer(CustomerModel customer) async {
    final docRef = _db.collection('customers').doc();
    await docRef.set({
      'customerCode': customer.customerCode,
      'companyName': customer.companyName,
      'contactPerson': customer.contactPerson,
      'phoneNumber': customer.phoneNumber,
      'email': customer.email,
      'businessRegistrationNo': customer.businessRegistrationNo,
      'address': customer.address,
      'creditLimit': customer.creditLimit,
      'creditTerm': customer.creditTerm,
      'status': customer.status,
      'outstandingBalance': customer.outstandingBalance,
      'creditScore': customer.creditScore,
      'creditHistory': customer.creditHistory,
    });
  }
  
  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

// INVENTORY PROVIDER
class InventoryProvider extends ChangeNotifier {
  final FirebaseFirestore _db;
  InventoryProvider({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;
  List<InventoryModel> _inventory = [];
  bool _isLoading = false;
  StreamSubscription? _sub;

  List<InventoryModel> get inventory => _inventory;
  bool get isLoading => _isLoading;
  List<InventoryModel> get lowStock => _inventory.where((i) => i.isLowStock).toList();
  List<InventoryModel> get outOfStock => _inventory.where((i) => i.isOutOfStock).toList();

  Future<void> loadInventory() async {
    _isLoading = true;
    notifyListeners();
    _sub?.cancel();
    // Maps products to InventoryModel for compatibility
    _sub = _db.collection('products').snapshots().listen((snap) {
      _inventory = snap.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return InventoryModel(
          id: doc.id,
          productId: doc.id,
          productName: data['name'] ?? '',
          productCode: data['itemCode'] ?? '',
          currentStock: data['stockQuantity'] ?? 0,
          reservedStock: 0,
          reorderLevel: data['lowStockLevel'] ?? 10,
          lastUpdated: DateTime.now(),
        );
      }).toList();
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<void> updateStock(String id, int newStock) async {
    await _db.collection('products').doc(id).update({'stockQuantity': newStock});
  }
  
  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

// DELIVERY PROVIDER
class DeliveryProvider extends ChangeNotifier {
  final FirebaseFirestore _db;
  DeliveryProvider({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;
  List<OrderModel> _deliveries = [];
  bool _isLoading = false;
  StreamSubscription? _sub;

  List<OrderModel> get deliveries => _deliveries;
  bool get isLoading => _isLoading;

  Future<void> loadDeliveries() async {
    _isLoading = true;
    notifyListeners();
    _sub?.cancel();
    _sub = _db.collection('orders')
        .where('orderStatus', whereIn: ['Pending', 'Confirmed', 'Packed', 'Out For Delivery', 'Delivered'])
        .snapshots().listen((snap) {
      _deliveries = snap.docs
          .where((doc) => ((doc.data())['deliveryFee'] ?? 0) > 0)
          .map((doc) => OrderModel.fromFirestore(doc))
          .toList();
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<void> updateStatus(String id, String status) async {
    try {
      await _db.collection('orders').doc(id).update({'orderStatus': status});
    } catch (e) {
      debugPrint('Error updating delivery status: $e');
    }
  }
  
  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

// DASHBOARD PROVIDER
class DashboardProvider extends ChangeNotifier {
  final FirebaseFirestore _db;
  DashboardProvider({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;
  DashboardStats? _stats;
  bool _isLoading = false;

  DashboardStats? get stats => _stats;
  bool get isLoading => _isLoading;

  Future<void> loadStats() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
      
      // Get today's orders
      final todayOrdersSnap = await _db.collection('orders')
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .get();
      
      int todayOrdersCount = 0;
      double todayRevenue = 0;
      for (var doc in todayOrdersSnap.docs) {
        final data = doc.data() as Map<String, dynamic>? ?? {};
        if (data['orderStatus'] == 'Cancelled') continue;
        todayOrdersCount++;
        todayRevenue += (data['totalAmount'] ?? 0).toDouble();
      }

      // Get pending orders
      final pendingOrdersSnap = await _db.collection('orders')
          .where('orderStatus', isEqualTo: 'Pending')
          .get();
      int pendingOrdersCount = pendingOrdersSnap.docs.length;

      // Get pending deliveries
      final pendingDeliveriesSnap = await _db.collection('orders')
          .where('orderStatus', isEqualTo: 'Out For Delivery')
          .get();
      int pendingDeliveriesCount = pendingDeliveriesSnap.docs.length;

      // Low stock products - compare stockQuantity < lowStockLevel per product
      final allProductsSnap = await _db.collection('products').get();
      int lowStockCount = allProductsSnap.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final stock = (data['stockQuantity'] ?? 0) as int;
        final lowLevel = (data['lowStockLevel'] ?? 10) as int;
        return stock > 0 && stock <= lowLevel;
      }).length;

      // Outstanding debts (from instalments)
      final instalmentsSnap = await _db.collection('instalments')
          .where('status', isEqualTo: 'Active')
          .get();
      double outstandingDebts = 0;
      for (var doc in instalmentsSnap.docs) {
        final plan = InstalmentPlanModel.fromFirestore(doc);
        outstandingDebts += plan.totalRemaining;
      }

      // 7-day revenue trend (cutoff each day is 23:59:59)
      final List<RevenuePoint> revenueData = [];
      for (int i = 6; i >= 0; i--) {
        final day = now.subtract(Duration(days: i));
        final dayStart = DateTime(day.year, day.month, day.day);
        final dayEnd = DateTime(day.year, day.month, day.day, 23, 59, 59);
        final snap = await _db.collection('orders')
            .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(dayStart))
            .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(dayEnd))
            .get();
        double dayRevenue = 0;
        for (var doc in snap.docs) {
          final data = doc.data() as Map<String, dynamic>? ?? {};
          if (data['orderStatus'] == 'Cancelled') continue;
          dayRevenue += (data['totalAmount'] ?? 0).toDouble();
        }
        revenueData.add(RevenuePoint(
          label: DateFormat('E').format(day),
          amount: dayRevenue,
        ));
      }

      // Top products by quantity sold in orders
      final Map<String, String> productNames = {};
      for (var doc in allProductsSnap.docs) {
        productNames[doc.id] = (doc.data() as Map<String, dynamic>)['name'] ?? 'Unknown';
      }

      final allOrdersSnap = await _db.collection('orders').get();
      final Map<String, _ProductStat> productStats = {};
      for (var doc in allOrdersSnap.docs) {
        final data = doc.data() as Map<String, dynamic>? ?? {};
        if (data['orderStatus'] == 'Cancelled') continue;
        final items = data['items'] as List<dynamic>? ?? [];
        for (var item in items) {
          final productId = item['productId'] as String?;
          final name = (item['productName'] as String?) ?? (productId != null ? productNames[productId] : null) ?? 'Unknown';
          final qty = (item['quantity'] ?? 0) as int;
          final rev = ((item['subtotal'] ?? item['price'] ?? 0) as num).toDouble();
          productStats[name] = _ProductStat(
            name: name,
            quantity: (productStats[name]?.quantity ?? 0) + qty,
            revenue: (productStats[name]?.revenue ?? 0) + rev,
          );
        }
      }
      final sortedProducts = productStats.values.toList()
        ..sort((a, b) => b.quantity.compareTo(a.quantity));

      // Top customers
      final Map<String, _CustomerStat> customerStats = {};
      for (var doc in allOrdersSnap.docs) {
        final data = doc.data() as Map<String, dynamic>? ?? {};
        if (data['orderStatus'] == 'Cancelled') continue;
        final name = data['customerName'] ?? 'Unknown';
        final amount = (data['totalAmount'] ?? 0).toDouble();
        customerStats[name] = _CustomerStat(
          name: name,
          orders: (customerStats[name]?.orders ?? 0) + 1,
          totalSpent: (customerStats[name]?.totalSpent ?? 0) + amount,
        );
      }
      final sortedCustomers = customerStats.values.toList()
        ..sort((a, b) => b.totalSpent.compareTo(a.totalSpent));

      _stats = DashboardStats(
        todayOrders: todayOrdersCount,
        todayRevenue: todayRevenue,
        pendingOrders: pendingOrdersCount,
        pendingDeliveries: pendingDeliveriesCount,
        lowStockProducts: lowStockCount,
        outstandingDebts: outstandingDebts,
        revenueData: revenueData,
        topProducts: sortedProducts.take(5).map<TopProduct>((p) => TopProduct(name: p.name, quantity: p.quantity, revenue: p.revenue)).toList(),
        topCustomers: sortedCustomers.take(5).map<TopCustomer>((c) => TopCustomer(name: c.name, orders: c.orders, totalSpent: c.totalSpent)).toList(),
      );
    } catch(e) {
      debugPrint("Error loading real stats: $e");
    }
    
    _isLoading = false;
    notifyListeners();
  }
}

class _ProductStat {
  final String name;
  final int quantity;
  final double revenue;
  _ProductStat({required this.name, required this.quantity, required this.revenue});
}

class _CustomerStat {
  final String name;
  final int orders;
  final double totalSpent;
  _CustomerStat({required this.name, required this.orders, required this.totalSpent});
}

// INSTALMENT PROVIDER
class InstalmentProvider extends ChangeNotifier {
  final FirebaseFirestore _db;
  InstalmentProvider({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;
  List<InstalmentPlanModel> _plans = [];
  bool _isLoading = false;
  StreamSubscription? _sub;

  List<InstalmentPlanModel> get plans => _plans;
  bool get isLoading => _isLoading;

  Future<void> loadCustomerPlans(String customerId) async {
    _isLoading = true;
    notifyListeners();
    _sub?.cancel();
    _sub = _db.collection('instalments')
        .where('customerId', isEqualTo: customerId)
        .snapshots()
        .listen((snap) {
      _plans = snap.docs.map((d) => InstalmentPlanModel.fromFirestore(d)).toList();
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<void> loadAllPlans() async {
    _isLoading = true;
    notifyListeners();
    _sub?.cancel();
    _sub = _db.collection('instalments').snapshots().listen((snap) {
      _plans = snap.docs.map((d) => InstalmentPlanModel.fromFirestore(d)).toList();
      _isLoading = false;
      notifyListeners();
    });
  }

  InstalmentPlanModel? planForOrder(String orderId) {
    try {
      return _plans.firstWhere((p) => p.orderId == orderId);
    } catch (_) {
      return null;
    }
  }

  Future<String> createPlan(InstalmentPlanModel plan) async {
    final data = plan.toJson();
    data['createdAt'] = FieldValue.serverTimestamp();
    final ref = await _db.collection('instalments').add(data);
    return ref.id;
  }
  Future<void> submitPhasePayment({
    required String planId,
    required int entryIndex,
    required String paymentMethod,
    String? paymentProofUrl,
  }) async {
    final doc = await _db.collection('instalments').doc(planId).get();
    final plan = InstalmentPlanModel.fromFirestore(doc);
    final entries = List<InstalmentEntry>.from(plan.entries);
    final entry = entries[entryIndex];

    entries[entryIndex] = entry.copyWith(
      status: 'Under Review',
      paymentMethod: paymentMethod,
      paymentProofUrl: paymentProofUrl,
    );

    await _db.collection('instalments').doc(planId).update({
      'entries': entries.map((e) => e.toJson()).toList(),
    });
  }

  Future<void> rejectPhasePayment(String planId, int entryIndex) async {
    final doc = await _db.collection('instalments').doc(planId).get();
    final plan = InstalmentPlanModel.fromFirestore(doc);
    final entries = List<InstalmentEntry>.from(plan.entries);
    final entry = entries[entryIndex];

    entries[entryIndex] = entry.copyWith(
      status: 'Pending',
      paymentMethod: null,
      paymentProofUrl: null,
    );

    await _db.collection('instalments').doc(planId).update({
      'entries': entries.map((e) => e.toJson()).toList(),
    });
  }

  /// Admin: update a single period's amount (total must not exceed original debt)
  Future<void> updateEntryAmount(String planId, int entryIndex, double newAmount) async {
    final doc = await _db.collection('instalments').doc(planId).get();
    final plan = InstalmentPlanModel.fromFirestore(doc);
    final entries = List<InstalmentEntry>.from(plan.entries);
    final entry = entries[entryIndex];
    if (entry.isPaid) return;

    double otherTotal = 0;
    for (int i = 0; i < entries.length; i++) {
      if (i != entryIndex) otherTotal += entries[i].amountDue;
    }
    final maxAllowed = plan.totalAmount - otherTotal;
    if (newAmount <= 0 || newAmount > maxAllowed) return;

    entries[entryIndex] = entry.copyWith(amountDue: newAmount);
    await _db.collection('instalments').doc(planId).update({
      'entries': entries.map((e) => e.toJson()).toList(),
    });
  }

  /// Admin: mark a period paid/late and adjust credit score
  Future<void> markPeriodPaid({
    required String planId,
    required String customerId,
    required int entryIndex,
    required bool isLate,
    String? adminNote,
  }) async {
    final doc = await _db.collection('instalments').doc(planId).get();
    final plan = InstalmentPlanModel.fromFirestore(doc);
    final entries = List<InstalmentEntry>.from(plan.entries);
    final entry = entries[entryIndex];
    if (entry.isPaid || entry.isLate) return;

    entries[entryIndex] = entry.copyWith(
      status: isLate ? 'Late' : 'Paid',
      paidAt: DateTime.now(),
      markedByAdmin: true,
      adminNote: adminNote,
    );

    final allDone = entries.every((e) => e.isPaid || e.isLate);
    await _db.collection('instalments').doc(planId).update({
      'entries': entries.map((e) => e.toJson()).toList(),
      'status': allDone ? 'Completed' : 'Active',
    });

    if (allDone) {
      await _db.collection('orders').doc(plan.orderId).update({
        'paymentStatus': 'Paid',
      });
    }

    await _updateCreditScore(
      customerId: customerId,
      isLate: isLate,
      adminNote: adminNote,
      periodNumber: entry.periodNumber,
      orderId: plan.orderId,
    );
  }

  Future<void> _updateCreditScore({
    required String customerId,
    required bool isLate,
    String? adminNote,
    required int periodNumber,
    required String orderId,
  }) async {
    final custDoc = await _db.collection('customers').doc(customerId).get();
    if (!custDoc.exists) return;
    final data = custDoc.data() as Map<String, dynamic>? ?? {};
    double current = (data['creditScore'] ?? 100.0).toDouble();
    double delta = isLate ? -10.0 : 5.0;
    double newScore = (current + delta).clamp(0.0, 100.0);

    final entry = {
      'date': DateTime.now().toIso8601String(),
      'delta': delta,
      'scoreBefore': current,
      'scoreAfter': newScore,
      'reason': isLate
          ? 'Late payment (Period $periodNumber, Order $orderId)'
          : 'On-time payment (Period $periodNumber, Order $orderId)',
      if (adminNote != null && adminNote.isNotEmpty) 'note': adminNote,
    };

    final List history = List.from(data['creditHistory'] ?? []);
    history.add(entry);

    await _db.collection('customers').doc(customerId).update({
      'creditScore': newScore,
      'creditHistory': history,
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
