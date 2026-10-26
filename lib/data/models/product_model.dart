import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stleaf_trading/core/constants/product_assets.dart';

class ProductSizeModel {
  final String unit; // 'Gram', 'Kg', 'Pack', 'Box'
  final double price;
  final double? promotionPrice;

  const ProductSizeModel({
    required this.unit,
    required this.price,
    this.promotionPrice,
  });

  double get effectivePrice => promotionPrice ?? price;
  bool get hasPromotion => promotionPrice != null && promotionPrice! < price;

  factory ProductSizeModel.fromMap(Map<String, dynamic> json) => ProductSizeModel(
        unit: json['unit'] ?? '',
        price: (json['price'] ?? 0).toDouble(),
        promotionPrice: json['promotionPrice']?.toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'unit': unit,
        'price': price,
        if (promotionPrice != null) 'promotionPrice': promotionPrice,
      };
}

class ProductModel {
  final String id;
  final String itemCode;
  final String name;
  final String category;
  final String description;
  final String precaution;
  final int freshnessLevel;
  final List<ProductSizeModel> sizes;
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
    required this.sizes,
    required this.stockQuantity,
    this.lowStockLevel = 10,
    this.imageUrl,
    required this.status,
    this.disabledReason,
  });

  // Helper to get the default size or first size available
  ProductSizeModel? get defaultSize => sizes.isNotEmpty ? sizes.first : null;

  // These getters provide fallback behavior for legacy code or when no specific size is selected
  double get effectivePrice => defaultSize?.effectivePrice ?? 0.0;
  bool get hasPromotion => defaultSize?.hasPromotion ?? false;
  String get packType => defaultSize?.unit ?? '';
  
  bool get isLowStock => stockQuantity <= lowStockLevel;
  bool get isOutOfStock => stockQuantity <= 0;
  bool get isActive => status != 'Inactive';

  /// Path to bundled local asset if this product has a local image backup.
  String? get localAssetPath => ProductAssets.getAssetPath(itemCode);

  factory ProductModel.fromFirestore(DocumentSnapshot doc) {
    final json = doc.data() as Map<String, dynamic>? ?? {};
    
    // Migration logic for old data format
    List<ProductSizeModel> parsedSizes = [];
    if (json['sizes'] != null) {
      parsedSizes = (json['sizes'] as List<dynamic>)
          .map((e) => ProductSizeModel.fromMap(e as Map<String, dynamic>))
          .toList();
    } else if (json['price'] != null) {
      // Legacy fallback
      parsedSizes = [
        ProductSizeModel(
          unit: json['packType'] ?? 'Unknown',
          price: (json['price'] ?? 0).toDouble(),
          promotionPrice: json['promotionPrice']?.toDouble(),
        )
      ];
    }

    return ProductModel(
      id: doc.id,
      itemCode: json['itemCode'] ?? '',
      name: json['name'] ?? '',
      category: json['category'] ?? '',
      description: json['description'] ?? '',
      precaution: json['precaution'] ?? '',
      freshnessLevel: (json['freshnessLevel'] is num) 
          ? (json['freshnessLevel'] as num).toInt() 
          : 10,
      sizes: parsedSizes,
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
        'sizes': sizes.map((s) => s.toJson()).toList(),
        'stockQuantity': stockQuantity,
        'lowStockLevel': lowStockLevel,
        'imageUrl': imageUrl,
        'status': status,
        if (disabledReason != null) 'disabledReason': disabledReason,
      };
}
