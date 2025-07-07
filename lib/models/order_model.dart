class OrderModel {
  final String orderId;
  final String customerId;
  final String sellerId;
  final String? productId;
  final String productName;
  final String sellerName;
  final int quantity;
  final double totalPrice;
  final String? deliveryLocation;
  final String status; // "Pending" or "Delivered"
  final DateTime createdAt;

  OrderModel({
    required this.orderId,
    required this.customerId,
    required this.sellerId,
    this.productId,
    required this.productName,
    required this.sellerName,
    required this.quantity,
    required this.totalPrice,
    this.deliveryLocation,
    required this.status,
    required this.createdAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      orderId: json['order_id'],
      customerId: json['customer_id'],
      sellerId: json['seller_id'],
      productId: json['product_id'],
      productName: json['product_name'] ?? '',
      sellerName: json['seller_name'] ?? '',
      quantity: json['quantity'] ?? 0,
      totalPrice: json['total_price']?.toDouble() ?? 0.0,
      deliveryLocation: json['delivery_location'],
      status: json['status'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'order_id': orderId,
      'customer_id': customerId,
      'seller_id': sellerId,
      'product_id': productId,
      'product_name': productName,
      'seller_name': sellerName,
      'quantity': quantity,
      'total_price': totalPrice,
      'delivery_location': deliveryLocation,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'customer_id': customerId,
      'seller_id': sellerId,
      'product_id': productId,
      'product_name': productName,
      'seller_name': sellerName,
      'quantity': quantity,
      'total_price': totalPrice,
      'delivery_location': deliveryLocation,
      'status': status,
    };
  }

  OrderModel copyWith({
    String? orderId,
    String? customerId,
    String? sellerId,
    String? productId,
    String? productName,
    String? sellerName,
    int? quantity,
    double? totalPrice,
    String? deliveryLocation,
    String? status,
    DateTime? createdAt,
  }) {
    return OrderModel(
      orderId: orderId ?? this.orderId,
      customerId: customerId ?? this.customerId,
      sellerId: sellerId ?? this.sellerId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      sellerName: sellerName ?? this.sellerName,
      quantity: quantity ?? this.quantity,
      totalPrice: totalPrice ?? this.totalPrice,
      deliveryLocation: deliveryLocation ?? this.deliveryLocation,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  double get totalAmount => totalPrice;

  bool get isPending => status == 'Pending';
  bool get isDelivered => status == 'Delivered';
}
