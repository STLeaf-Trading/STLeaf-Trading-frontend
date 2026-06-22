import 'package:cloud_firestore/cloud_firestore.dart';

class ProductModel {
  final String id;
  final String itemCode;
  final String name;
  final String category;
  final String description;
  final String precaution;
  final int freshnessLevel;
  final String packType;
  final double weightKg;
  final double price;
  final double? promotionPrice;
  final int stockQuantity;
  final int lowStockLevel;
  final String? imageUrl;
  final String status;
  final String? disabledReason;

  const ProductModel({
    required this.id,
    required this.itemCode,
    required this.name,
    required this.category,
    required this.description,
    required this.precaution,
    required this.freshnessLevel,
    required this.packType,
    required this.weightKg,
    required this.price,
    this.promotionPrice,
    required this.stockQuantity,
    this.lowStockLevel = 10,
    this.imageUrl,
    required this.status,
    this.disabledReason,
  });

  double get effectivePrice => promotionPrice ?? price;
  bool get hasPromotion => promotionPrice != null && promotionPrice! < price;
  bool get isLowStock => stockQuantity <= lowStockLevel;
  bool get isOutOfStock => stockQuantity <= 0;
  bool get isActive => status != 'Inactive';

  factory ProductModel.fromFirestore(DocumentSnapshot doc) {
    final json = doc.data() as Map<String, dynamic>? ?? {};
    return ProductModel(
      id: doc.id,
      itemCode: json['itemCode'] ?? '',
      name: json['name'] ?? '',
      category: json['category'] ?? '',
      description: json['description'] ?? '',
      precaution: json['precaution'] ?? '',
      freshnessLevel: (json['freshnessLevel'] is num) 
          ? (json['freshnessLevel'] as num).toInt() 
          : 10, // Fallback for old string records
      packType: json['packType'] ?? '',
      weightKg: (json['weightKg'] ?? 0).toDouble(),
      price: (json['price'] ?? 0).toDouble(),
      promotionPrice: json['promotionPrice']?.toDouble(),
      stockQuantity: json['stockQuantity'] ?? 0,
      lowStockLevel: json['lowStockLevel'] ?? 10,
      imageUrl: json['imageUrl'],
      status: json['status'] ?? 'Active',
      disabledReason: json['disabledReason'],
    );
  }

  Map<String, dynamic> toJson() => {
        'itemCode': itemCode,
        'name': name,
        'category': category,
        'description': description,
        'precaution': precaution,
        'freshnessLevel': freshnessLevel,
        'packType': packType,
        'weightKg': weightKg,
        'price': price,
        'promotionPrice': promotionPrice,
        'stockQuantity': stockQuantity,
        'lowStockLevel': lowStockLevel,
        'imageUrl': imageUrl,
        'status': status,
        if (disabledReason != null) 'disabledReason': disabledReason,
      };
}
