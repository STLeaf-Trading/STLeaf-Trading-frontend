import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/models/product_model.dart';
import '../data/models/customer_model.dart';
import '../data/models/order_model.dart';
import 'dart:typed_data';
import '../data/models/inventory_model.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../core/constants/app_constants.dart';

// PRODUCT PROVIDER
class ProductProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
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
  int quantity;
  CartItem({required this.product, required this.quantity});
  double get subtotal => product.effectivePrice * quantity;
}

class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => _items;
  int get itemCount => _items.fold(0, (sum, i) => sum + i.quantity);
  double get subtotal => _items.fold(0, (sum, i) => sum + i.subtotal);
  double get deliveryFee => _items.isEmpty ? 0 : 15.00;
  double get total => subtotal + deliveryFee;
  bool get isEmpty => _items.isEmpty;

  void addToCart(ProductModel product, {int quantity = 1}) {
    final idx = _items.indexWhere((i) => i.product.id == product.id);
    if (idx != -1) {
      _items[idx].quantity += quantity;
    } else {
      _items.add(CartItem(product: product, quantity: quantity));
    }
    notifyListeners();
  }

  void updateQuantity(String productId, int qty) {
    final idx = _items.indexWhere((i) => i.product.id == productId);
    if (idx != -1) {
      if (qty <= 0) {
        _items.removeAt(idx);
      } else {
        _items[idx].quantity = qty;
      }
      notifyListeners();
    }
  }

  void removeItem(String productId) {
    _items.removeWhere((i) => i.product.id == productId);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}

// ORDER PROVIDER
class OrderProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  List<OrderModel> _orders = [];
  bool _isLoading = false;
  String _statusFilter = 'All';
  StreamSubscription? _sub;

  List<OrderModel> get orders => _filtered;
  List<OrderModel> get allOrders => _orders;
  bool get isLoading => _isLoading;
  String get statusFilter => _statusFilter;

  List<OrderModel> get _filtered {
    if (_statusFilter == 'All') return _orders;
    return _orders.where((o) => o.orderStatus == _statusFilter).toList();
  }

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
    final docRef = await _db.collection('orders').add(order.toJson());
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
  
  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

// CUSTOMER PROVIDER
class CustomerProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
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
  
  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

// INVENTORY PROVIDER
class InventoryProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
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
          reorderLevel: 10,
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
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  List<DeliveryModel> _deliveries = [];
  bool _isLoading = false;
  StreamSubscription? _sub;

  List<DeliveryModel> get deliveries => _deliveries;
  bool get isLoading => _isLoading;

  Future<void> loadDeliveries() async {
    _isLoading = true;
    notifyListeners();
    _sub?.cancel();
    _sub = _db.collection('orders').where('orderStatus', isNotEqualTo: 'Delivered').snapshots().listen((snap) {
      _deliveries = snap.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return DeliveryModel(
          id: doc.id,
          orderId: data['orderId'] ?? '',
          customerName: data['customerName'] ?? '',
          deliveryDate: DateTime.tryParse(data['deliveryDate']?.toString() ?? '') ?? DateTime.now(),
          status: 'Pending',
          driverName: '',
          vehicleNumber: '',
        );
      }).toList();
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<void> updateStatus(String id, String status) async {
    // Delivery update logic
  }
  
  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

// DASHBOARD PROVIDER
class DashboardProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  DashboardStats? _stats;
  bool _isLoading = false;

  DashboardStats? get stats => _stats;
  bool get isLoading => _isLoading;

  Future<void> loadStats() async {
    _isLoading = true;
    notifyListeners();
    
    // Simple mock calculation for now since real calculation requires multiple reads
    _stats = DashboardStats(
      todayOrders: 12,
      todayRevenue: 15400.0,
      pendingOrders: 5,
      pendingDeliveries: 3,
      lowStockProducts: 3,
      outstandingDebts: 4500.0,
      revenueData: [],
      topProducts: [],
      topCustomers: [],
    );
    
    _isLoading = false;
    notifyListeners();
  }
}
