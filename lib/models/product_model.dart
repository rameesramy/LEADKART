class ProductModel {
  final String productId;
  final String sellerId;
  final String name;
  final String? description;
  final double price;
  final int stock;
  final String category; // "Food" or "Other"
  final String? imageUrl;
  final DateTime createdAt;
  final String? sellerPhone; // Add seller phone for WhatsApp orders

  ProductModel({
    required this.productId,
    required this.sellerId,
    required this.name,
    this.description,
    required this.price,
    required this.stock,
    required this.category,
    this.imageUrl,
    required this.createdAt,
    this.sellerPhone,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      productId: json['product_id'],
      sellerId: json['seller_id'],
      name: json['name'],
      description: json['description'],
      price: json['price']?.toDouble() ?? 0.0,
      stock: json['stock'] ?? 0,
      category: json['category'],
      imageUrl: json['image_url'],
      createdAt: DateTime.parse(json['created_at']),
      sellerPhone: json['seller_phone'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'seller_id': sellerId,
      'name': name,
      'description': description,
      'price': price,
      'stock': stock,
      'category': category,
      'image_url': imageUrl,
      'created_at': createdAt.toIso8601String(),
      'seller_phone': sellerPhone,
    };
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'seller_id': sellerId,
      'name': name,
      'description': description,
      'price': price,
      'stock': stock,
      'category': category,
      'image_url': imageUrl,
      'seller_phone': sellerPhone,
    };
  }

  ProductModel copyWith({
    String? productId,
    String? sellerId,
    String? name,
    String? description,
    double? price,
    int? stock,
    String? category,
    String? imageUrl,
    DateTime? createdAt,
    String? sellerPhone,
  }) {
    return ProductModel(
      productId: productId ?? this.productId,
      sellerId: sellerId ?? this.sellerId,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      sellerPhone: sellerPhone ?? this.sellerPhone,
    );
  }

  bool get isInStock => stock > 0;
}
