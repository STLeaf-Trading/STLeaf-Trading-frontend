import 'package:flutter/foundation.dart';
import '../data/models/product_model.dart';
import '../data/models/inventory_model.dart';
import '../data/models/customer_model.dart';
import '../data/models/order_model.dart';
import '../data/models/inventory_model.dart' show DeliveryModel, PaymentModel, DashboardStats;
import '../data/mock/mock_data.dart';

// ─────────────────────────────────────────────────────
// PRODUCT PROVIDER
// ─────────────────────────────────────────────────────
class ProductProvider extends ChangeNotifier {
  List<ProductModel> _products = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String _selectedCategory = 'All';

  List<ProductModel> get products => _filtered;
  List<ProductModel> get allProducts => _products;
  bool get isLoading => _isLoading;
  String get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;

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
    await Future.delayed(const Duration(milliseconds: 500));
    _products = List.from(MockData.products);
    _isLoading = false;
    notifyListeners();
  }

  void setSearch(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void addProduct(ProductModel product) {
    _products.insert(0, product);
    notifyListeners();
  }

  void updateProduct(ProductModel updated) {
    final idx = _products.indexWhere((p) => p.id == updated.id);
    if (idx != -1) {
      _products[idx] = updated;
      notifyListeners();
    }
  }

  void deleteProduct(String id) {
    _products.removeWhere((p) => p.id == id);
    notifyListeners();
  }

  List<ProductModel> get lowStockProducts =>
      _products.where((p) => p.isLowStock).toList();
}

// ─────────────────────────────────────────────────────
// CART PROVIDER
// ─────────────────────────────────────────────────────
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

// ─────────────────────────────────────────────────────
// ORDER PROVIDER
// ─────────────────────────────────────────────────────
class OrderProvider extends ChangeNotifier {
  List<OrderModel> _orders = [];
  bool _isLoading = false;
  String _statusFilter = 'All';

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
    await Future.delayed(const Duration(milliseconds: 500));
    _orders = customerId == null
        ? List.from(MockData.orders)
        : MockData.orders.where((o) => o.customerId == customerId).toList();
    _isLoading = false;
    notifyListeners();
  }

  void setStatusFilter(String status) {
    _statusFilter = status;
    notifyListeners();
  }

  Future<OrderModel?> placeOrder(OrderModel order) async {
    await Future.delayed(const Duration(milliseconds: 800));
    _orders.insert(0, order);
    notifyListeners();
    return order;
  }

  void updateStatus(String orderId, String status) {
    final idx = _orders.indexWhere((o) => o.id == orderId);
    if (idx != -1) notifyListeners();
  }
}

// ─────────────────────────────────────────────────────
// CUSTOMER PROVIDER
// ─────────────────────────────────────────────────────
class CustomerProvider extends ChangeNotifier {
  List<CustomerModel> _customers = [];
  bool _isLoading = false;
  String _searchQuery = '';

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
    await Future.delayed(const Duration(milliseconds: 400));
    _customers = List.from(MockData.customers);
    _isLoading = false;
    notifyListeners();
  }

  void setSearch(String q) {
    _searchQuery = q;
    notifyListeners();
  }
}

// ─────────────────────────────────────────────────────
// INVENTORY PROVIDER
// ─────────────────────────────────────────────────────
class InventoryProvider extends ChangeNotifier {
  List<InventoryModel> _inventory = [];
  bool _isLoading = false;

  List<InventoryModel> get inventory => _inventory;
  bool get isLoading => _isLoading;
  List<InventoryModel> get lowStock => _inventory.where((i) => i.isLowStock).toList();
  List<InventoryModel> get outOfStock => _inventory.where((i) => i.isOutOfStock).toList();

  Future<void> loadInventory() async {
    _isLoading = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 400));
    _inventory = List.from(MockData.inventory);
    _isLoading = false;
    notifyListeners();
  }

  void updateStock(String id, int newStock) {
    final idx = _inventory.indexWhere((i) => i.id == id);
    if (idx != -1) {
      _inventory[idx] = InventoryModel(
        id: _inventory[idx].id, productId: _inventory[idx].productId,
        productName: _inventory[idx].productName, productCode: _inventory[idx].productCode,
        currentStock: newStock, reservedStock: _inventory[idx].reservedStock,
        reorderLevel: _inventory[idx].reorderLevel, lastUpdated: DateTime.now(),
      );
      notifyListeners();
    }
  }
}

// ─────────────────────────────────────────────────────
// DELIVERY PROVIDER
// ─────────────────────────────────────────────────────
class DeliveryProvider extends ChangeNotifier {
  List<DeliveryModel> _deliveries = [];
  bool _isLoading = false;

  List<DeliveryModel> get deliveries => _deliveries;
  bool get isLoading => _isLoading;

  Future<void> loadDeliveries() async {
    _isLoading = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 400));
    _deliveries = List.from(MockData.deliveries);
    _isLoading = false;
    notifyListeners();
  }

  void updateStatus(String id, String status) {
    final idx = _deliveries.indexWhere((d) => d.id == id);
    if (idx != -1) notifyListeners();
  }
}

// ─────────────────────────────────────────────────────
// DASHBOARD PROVIDER
// ─────────────────────────────────────────────────────
class DashboardProvider extends ChangeNotifier {
  DashboardStats? _stats;
  bool _isLoading = false;

  DashboardStats? get stats => _stats;
  bool get isLoading => _isLoading;

  Future<void> loadStats() async {
    _isLoading = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 600));
    _stats = MockData.dashboardStats;
    _isLoading = false;
    notifyListeners();
  }
}
