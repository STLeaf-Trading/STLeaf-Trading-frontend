class ProductModel {
  final String id;
  final String itemCode;
  final String name;
  final String category;
  final String description;
  final String precaution;
  final String freshnessLevel;
  final String packType;
  final double weightKg;
  final double price;
  final double? promotionPrice;
  final int stockQuantity;
  final String? imageUrl;
  final String status;
  final DateTime createdAt;

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
    this.imageUrl,
    required this.status,
    required this.createdAt,
  });

  double get effectivePrice => promotionPrice ?? price;
  bool get hasPromotion => promotionPrice != null && promotionPrice! < price;
  bool get isLowStock => stockQuantity <= 10;
  bool get isOutOfStock => stockQuantity == 0;
  bool get isActive => status == 'Active';

  factory ProductModel.fromJson(Map<String, dynamic> json) => ProductModel(
        id: json['id'] ?? '',
        itemCode: json['itemCode'] ?? '',
        name: json['name'] ?? '',
        category: json['category'] ?? '',
        description: json['description'] ?? '',
        precaution: json['precaution'] ?? '',
        freshnessLevel: json['freshnessLevel'] ?? 'Fresh',
        packType: json['packType'] ?? '',
        weightKg: (json['weightKg'] ?? 0).toDouble(),
        price: (json['price'] ?? 0).toDouble(),
        promotionPrice: json['promotionPrice']?.toDouble(),
        stockQuantity: json['stockQuantity'] ?? 0,
        imageUrl: json['imageUrl'],
        status: json['status'] ?? 'Active',
        createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
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
        'imageUrl': imageUrl,
        'status': status,
        'createdAt': createdAt.toIso8601String(),
      };
}
