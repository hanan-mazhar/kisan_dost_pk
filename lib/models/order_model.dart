class OrderModel {
  final String id;
  final String productId;
  final String productName;
  final String productImageUrl;
  final String farmerId;
  final String farmerName;
  final String farmerPhone;
  final String buyerId;
  final String buyerName;
  final String buyerPhone;
  final double pricePerUnit;
  final String unit;
  final int quantity;
  final double totalAmount;
  final String status;
  final String paymentMethod;
  final String paymentStatus;
  // Local path instead of Firebase Storage URL
  final String? paymentProofPath;
  final String deliveryAddress;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isRated;

  OrderModel({
    required this.id,
    required this.productId,
    required this.productName,
    this.productImageUrl = '',
    required this.farmerId,
    required this.farmerName,
    required this.farmerPhone,
    required this.buyerId,
    required this.buyerName,
    required this.buyerPhone,
    required this.pricePerUnit,
    required this.unit,
    required this.quantity,
    required this.totalAmount,
    required this.status,
    required this.paymentMethod,
    this.paymentStatus = 'Pending',
    this.paymentProofPath,
    required this.deliveryAddress,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.isRated = false,
  });

  factory OrderModel.fromMap(Map<String, dynamic> map, String id) {
    return OrderModel(
      id: id,
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      productImageUrl: map['productImageUrl'] ?? '',
      farmerId: map['farmerId'] ?? '',
      farmerName: map['farmerName'] ?? '',
      farmerPhone: map['farmerPhone'] ?? '',
      buyerId: map['buyerId'] ?? '',
      buyerName: map['buyerName'] ?? '',
      buyerPhone: map['buyerPhone'] ?? '',
      pricePerUnit: (map['pricePerUnit'] ?? 0.0).toDouble(),
      unit: map['unit'] ?? 'kg',
      quantity: map['quantity'] ?? 0,
      totalAmount: (map['totalAmount'] ?? 0.0).toDouble(),
      status: map['status'] ?? 'Pending',
      paymentMethod: map['paymentMethod'] ?? 'Cash on Delivery',
      paymentStatus: map['paymentStatus'] ?? 'Pending',
      paymentProofPath:
          map['paymentProofPath'] ?? map['paymentScreenshotUrl'],
      deliveryAddress: map['deliveryAddress'] ?? '',
      notes: map['notes'],
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as dynamic).toDate()
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as dynamic).toDate()
          : DateTime.now(),
      isRated: map['isRated'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'productImageUrl': productImageUrl,
      'farmerId': farmerId,
      'farmerName': farmerName,
      'farmerPhone': farmerPhone,
      'buyerId': buyerId,
      'buyerName': buyerName,
      'buyerPhone': buyerPhone,
      'pricePerUnit': pricePerUnit,
      'unit': unit,
      'quantity': quantity,
      'totalAmount': totalAmount,
      'status': status,
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
      'paymentProofPath': paymentProofPath,
      'deliveryAddress': deliveryAddress,
      'notes': notes,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'isRated': isRated,
    };
  }

  OrderModel copyWith({
    String? status,
    String? paymentStatus,
    String? paymentProofPath,
    bool? isRated,
  }) {
    return OrderModel(
      id: id,
      productId: productId,
      productName: productName,
      productImageUrl: productImageUrl,
      farmerId: farmerId,
      farmerName: farmerName,
      farmerPhone: farmerPhone,
      buyerId: buyerId,
      buyerName: buyerName,
      buyerPhone: buyerPhone,
      pricePerUnit: pricePerUnit,
      unit: unit,
      quantity: quantity,
      totalAmount: totalAmount,
      status: status ?? this.status,
      paymentMethod: paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentProofPath: paymentProofPath ?? this.paymentProofPath,
      deliveryAddress: deliveryAddress,
      notes: notes,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      isRated: isRated ?? this.isRated,
    );
  }
}
