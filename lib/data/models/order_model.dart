import 'package:cloud_firestore/cloud_firestore.dart';
import 'product_model.dart';

class OrderItemModel {
  final String productId;
  final String productName;
  final String itemCode;
  final String packType;
  final ProductModel? product;
  final double quantity;
  final double price;
  final double subtotal;
  final String? remarks;

  const OrderItemModel({
    required this.productId,
    this.productName = 'Unknown',
    this.itemCode = '',
    this.packType = 'kg',
    this.product,
    required this.quantity,
    required this.price,
    required this.subtotal,
    this.remarks,
  });

  factory OrderItemModel.fromMap(Map<String, dynamic> json) => OrderItemModel(
        productId: json['productId'] ?? '',
        productName: json['productName'] ?? 'Unknown',
        itemCode: json['itemCode'] ?? '',
        packType: json['packType'] ?? 'kg',
        product: json['product'] != null ? ProductModel.fromFirestore(json['product'] as DocumentSnapshot) : null,
        quantity: (json['quantity'] ?? 0).toDouble(),
        price: (json['price'] ?? 0).toDouble(),
        subtotal: (json['subtotal'] ?? 0).toDouble(),
        remarks: json['remarks'],
      );

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'productName': productName,
        'itemCode': itemCode,
        'packType': packType,
        'quantity': quantity,
        'price': price,
        'subtotal': subtotal,
        if (remarks != null && remarks!.isNotEmpty) 'remarks': remarks,
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
  final String? deliveryAddress;
  final List<OrderItemModel> items;
  final String? cancellationReason;
  final String? customerComment;
  final String? instalmentPlanId;

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
    this.deliveryAddress,
    required this.items,
    this.cancellationReason,
    this.customerComment,
    this.instalmentPlanId,
  });

  bool get isPending => orderStatus == 'Pending';
  bool get isCancelled => orderStatus == 'Cancelled';
  bool get isDelivered => orderStatus == 'Delivered';
  bool get isOutstanding => paymentStatus == 'Pending' || paymentStatus == 'Overdue';

  factory OrderModel.fromFirestore(DocumentSnapshot doc) {
    final json = doc.data() as Map<String, dynamic>? ?? {};
    
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return OrderModel(
      id: doc.id,
      orderId: json['orderId'] ?? '',
      customerId: json['customerId'] ?? '',
      customerName: json['customerName'],
      orderDate: parseDate(json['orderDate']),
      deliveryDate: parseDate(json['deliveryDate']),
      subtotal: (json['subtotal'] ?? 0).toDouble(),
      deliveryFee: (json['deliveryFee'] ?? 0).toDouble(),
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      paymentMethod: json['paymentMethod'] ?? 'Cash',
      paymentStatus: json['paymentStatus'] ?? 'Pending',
      orderStatus: json['orderStatus'] ?? 'Pending',
      deliveryAddress: json['deliveryAddress'],
      cancellationReason: json['cancellationReason'],
      customerComment: json['customerComment'],
      instalmentPlanId: json['instalmentPlanId'],
      items: (json['items'] as List<dynamic>? ?? [])
          .map((e) => OrderItemModel.fromMap(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
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
        if (deliveryAddress != null && deliveryAddress!.isNotEmpty) 'deliveryAddress': deliveryAddress,
        'items': items.map((e) => e.toJson()).toList(),
        if (cancellationReason != null) 'cancellationReason': cancellationReason,
        if (customerComment != null && customerComment!.isNotEmpty) 'customerComment': customerComment,
        if (instalmentPlanId != null) 'instalmentPlanId': instalmentPlanId,
      };
}
