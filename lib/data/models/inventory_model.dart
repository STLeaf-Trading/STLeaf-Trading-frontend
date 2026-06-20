class InventoryModel {
  final String id;
  final String productId;
  final String? productName;
  final String? productCode;
  final int currentStock;
  final int reservedStock;
  final int reorderLevel;
  final DateTime lastUpdated;

  const InventoryModel({
    required this.id,
    required this.productId,
    this.productName,
    this.productCode,
    required this.currentStock,
    required this.reservedStock,
    required this.reorderLevel,
    required this.lastUpdated,
  });

  int get availableStock => currentStock - reservedStock;
  bool get isLowStock => availableStock <= reorderLevel;
  bool get isOutOfStock => availableStock <= 0;

  String get stockStatus {
    if (isOutOfStock) return 'Out of Stock';
    if (isLowStock) return 'Low Stock';
    return 'In Stock';
  }

  factory InventoryModel.fromJson(Map<String, dynamic> json) => InventoryModel(
        id: json['id'] ?? '',
        productId: json['productId'] ?? '',
        productName: json['productName'],
        productCode: json['productCode'],
        currentStock: json['currentStock'] ?? 0,
        reservedStock: json['reservedStock'] ?? 0,
        reorderLevel: json['lowStockLevel'] ?? 10,
        lastUpdated: DateTime.tryParse(json['lastUpdated'] ?? '') ?? DateTime.now(),
      );
}

class DeliveryModel {
  final String id;
  final String orderId;
  final String? orderCode;
  final String? customerName;
  final DateTime deliveryDate;
  final String driverName;
  final String vehicleNumber;
  final String status;
  final String? remarks;

  const DeliveryModel({
    required this.id,
    required this.orderId,
    this.orderCode,
    this.customerName,
    required this.deliveryDate,
    required this.driverName,
    required this.vehicleNumber,
    required this.status,
    this.remarks,
  });

  factory DeliveryModel.fromJson(Map<String, dynamic> json) => DeliveryModel(
        id: json['id'] ?? '',
        orderId: json['orderId'] ?? '',
        orderCode: json['orderCode'],
        customerName: json['customerName'],
        deliveryDate: DateTime.tryParse(json['deliveryDate'] ?? '') ?? DateTime.now(),
        driverName: json['driverName'] ?? '',
        vehicleNumber: json['vehicleNumber'] ?? '',
        status: json['status'] ?? 'Scheduled',
        remarks: json['remarks'],
      );
}

class PaymentModel {
  final String id;
  final String orderId;
  final String? orderCode;
  final String paymentMethod;
  final double amount;
  final DateTime paymentDate;
  final String? referenceNo;
  final String status;

  const PaymentModel({
    required this.id,
    required this.orderId,
    this.orderCode,
    required this.paymentMethod,
    required this.amount,
    required this.paymentDate,
    this.referenceNo,
    required this.status,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) => PaymentModel(
        id: json['id'] ?? '',
        orderId: json['orderId'] ?? '',
        orderCode: json['orderCode'],
        paymentMethod: json['paymentMethod'] ?? 'Cash',
        amount: (json['amount'] ?? 0).toDouble(),
        paymentDate: DateTime.tryParse(json['paymentDate'] ?? '') ?? DateTime.now(),
        referenceNo: json['referenceNo'],
        status: json['status'] ?? 'Pending',
      );
}

class DashboardStats {
  final int todayOrders;
  final double todayRevenue;
  final int pendingOrders;
  final int pendingDeliveries;
  final int lowStockProducts;
  final double outstandingDebts;
  final List<RevenuePoint> revenueData;
  final List<TopProduct> topProducts;
  final List<TopCustomer> topCustomers;

  const DashboardStats({
    required this.todayOrders,
    required this.todayRevenue,
    required this.pendingOrders,
    required this.pendingDeliveries,
    required this.lowStockProducts,
    required this.outstandingDebts,
    required this.revenueData,
    required this.topProducts,
    required this.topCustomers,
  });
}

class RevenuePoint {
  final String label;
  final double amount;
  const RevenuePoint({required this.label, required this.amount});
}

class TopProduct {
  final String name;
  final int quantity;
  final double revenue;
  const TopProduct({required this.name, required this.quantity, required this.revenue});
}

class TopCustomer {
  final String name;
  final int orders;
  final double totalSpent;
  const TopCustomer({required this.name, required this.orders, required this.totalSpent});
}
