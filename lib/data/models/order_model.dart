import 'product_model.dart';

class OrderItemModel {
  final String id;
  final String orderId;
  final String productId;
  final ProductModel? product;
  final int quantity;
  final double price;
  final double subtotal;

  const OrderItemModel({
    required this.id,
    required this.orderId,
    required this.productId,
    this.product,
    required this.quantity,
    required this.price,
    required this.subtotal,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) => OrderItemModel(
        id: json['id'] ?? '',
        orderId: json['orderId'] ?? '',
        productId: json['productId'] ?? '',
        product: json['product'] != null ? ProductModel.fromJson(json['product']) : null,
        quantity: json['quantity'] ?? 0,
        price: (json['price'] ?? 0).toDouble(),
        subtotal: (json['subtotal'] ?? 0).toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'orderId': orderId,
        'productId': productId,
        'quantity': quantity,
        'price': price,
        'subtotal': subtotal,
      };
}

class OrderModel {
  final String id;
  final String orderId;
  final String customerId;
  final String? customerName;
  final DateTime orderDate;
  final DateTime deliveryDate;
  final double subtotal;
  final double deliveryFee;
  final double totalAmount;
  final String paymentMethod;
  final String paymentStatus;
  final String orderStatus;
  final List<OrderItemModel> items;
  final DateTime createdAt;

  const OrderModel({
    required this.id,
    required this.orderId,
    required this.customerId,
    this.customerName,
    required this.orderDate,
    required this.deliveryDate,
    required this.subtotal,
    required this.deliveryFee,
    required this.totalAmount,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.orderStatus,
    required this.items,
    required this.createdAt,
  });

  bool get isPending => orderStatus == 'Pending';
  bool get isCancelled => orderStatus == 'Cancelled';
  bool get isDelivered => orderStatus == 'Delivered';
  bool get isOutstanding => paymentStatus == 'Pending' || paymentStatus == 'Overdue';

  factory OrderModel.fromJson(Map<String, dynamic> json) => OrderModel(
        id: json['id'] ?? '',
        orderId: json['orderId'] ?? '',
        customerId: json['customerId'] ?? '',
        customerName: json['customerName'],
        orderDate: DateTime.tryParse(json['orderDate'] ?? '') ?? DateTime.now(),
        deliveryDate: DateTime.tryParse(json['deliveryDate'] ?? '') ?? DateTime.now().add(const Duration(days: 1)),
        subtotal: (json['subtotal'] ?? 0).toDouble(),
        deliveryFee: (json['deliveryFee'] ?? 0).toDouble(),
        totalAmount: (json['totalAmount'] ?? 0).toDouble(),
        paymentMethod: json['paymentMethod'] ?? 'Cash',
        paymentStatus: json['paymentStatus'] ?? 'Pending',
        orderStatus: json['orderStatus'] ?? 'Pending',
        items: (json['items'] as List<dynamic>? ?? [])
            .map((e) => OrderItemModel.fromJson(e))
            .toList(),
        createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'orderId': orderId,
        'customerId': customerId,
        'customerName': customerName,
        'orderDate': orderDate.toIso8601String(),
        'deliveryDate': deliveryDate.toIso8601String(),
        'subtotal': subtotal,
        'deliveryFee': deliveryFee,
        'totalAmount': totalAmount,
        'paymentMethod': paymentMethod,
        'paymentStatus': paymentStatus,
        'orderStatus': orderStatus,
        'items': items.map((e) => e.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
      };
}
