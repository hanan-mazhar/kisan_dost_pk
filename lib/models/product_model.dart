import 'dart:convert';

class ProductModel {
  final String id;
  final String farmerId;
  final String farmerName;
  final String farmerPhone;
  final String farmerCity;
  final double farmerRating;
  final String name;
  final String category;
  final double pricePerUnit;
  final String unit;
  final int quantityAvailable;
  final String location;
  final double? latitude;
  final double? longitude;
  // Local file paths (no Firebase Storage needed)
  final List<String> imagePaths;
  // Keep imageUrls for backward compat (empty in new version)
  final List<String> imageUrls;
  final String description;
  final bool isAvailable;
  final DateTime createdAt;
  final DateTime updatedAt;
  final double? distanceKm;

  ProductModel({
    required this.id,
    required this.farmerId,
    required this.farmerName,
    required this.farmerPhone,
    required this.farmerCity,
    this.farmerRating = 0.0,
    required this.name,
    required this.category,
    required this.pricePerUnit,
    required this.unit,
    required this.quantityAvailable,
    required this.location,
    this.latitude,
    this.longitude,
    this.imagePaths = const [],
    this.imageUrls = const [],
    required this.description,
    this.isAvailable = true,
    required this.createdAt,
    required this.updatedAt,
    this.distanceKm,
  });

  /// Returns the first available image path (local or url)
  String? get firstImage {
    if (imagePaths.isNotEmpty) return imagePaths.first;
    if (imageUrls.isNotEmpty) return imageUrls.first;
    return null;
  }

  bool get hasImages => imagePaths.isNotEmpty || imageUrls.isNotEmpty;

  factory ProductModel.fromMap(Map<String, dynamic> map, String id) {
    return ProductModel(
      id: id,
      farmerId: map['farmerId'] ?? '',
      farmerName: map['farmerName'] ?? '',
      farmerPhone: map['farmerPhone'] ?? '',
      farmerCity: map['farmerCity'] ?? '',
      farmerRating: (map['farmerRating'] ?? 0.0).toDouble(),
      name: map['name'] ?? '',
      category: map['category'] ?? '',
      pricePerUnit: (map['pricePerUnit'] ?? 0.0).toDouble(),
      unit: map['unit'] ?? 'kg',
      quantityAvailable: map['quantityAvailable'] ?? 0,
      location: map['location'] ?? '',
      latitude: map['latitude']?.toDouble(),
      longitude: map['longitude']?.toDouble(),
      imagePaths: List<String>.from(map['imagePaths'] ?? []),
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
      description: map['description'] ?? '',
      isAvailable: map['isAvailable'] ?? true,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as dynamic).toDate()
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as dynamic).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'farmerId': farmerId,
      'farmerName': farmerName,
      'farmerPhone': farmerPhone,
      'farmerCity': farmerCity,
      'farmerRating': farmerRating,
      'name': name,
      'category': category,
      'pricePerUnit': pricePerUnit,
      'unit': unit,
      'quantityAvailable': quantityAvailable,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'imagePaths': imagePaths,
      'imageUrls': imageUrls,
      'description': description,
      'isAvailable': isAvailable,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  // For local cache serialization
  String toJsonString() => jsonEncode({
        ...toMap(),
        'id': id,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      });

  factory ProductModel.fromJsonString(String json) {
    final map = jsonDecode(json) as Map<String, dynamic>;
    return ProductModel(
      id: map['id'] ?? '',
      farmerId: map['farmerId'] ?? '',
      farmerName: map['farmerName'] ?? '',
      farmerPhone: map['farmerPhone'] ?? '',
      farmerCity: map['farmerCity'] ?? '',
      farmerRating: (map['farmerRating'] ?? 0.0).toDouble(),
      name: map['name'] ?? '',
      category: map['category'] ?? '',
      pricePerUnit: (map['pricePerUnit'] ?? 0.0).toDouble(),
      unit: map['unit'] ?? 'kg',
      quantityAvailable: map['quantityAvailable'] ?? 0,
      location: map['location'] ?? '',
      imagePaths: List<String>.from(map['imagePaths'] ?? []),
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
      description: map['description'] ?? '',
      isAvailable: map['isAvailable'] ?? true,
      createdAt: DateTime.parse(
          map['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(
          map['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  ProductModel copyWith({
    String? name,
    String? category,
    double? pricePerUnit,
    String? unit,
    int? quantityAvailable,
    String? description,
    String? location,
    bool? isAvailable,
    List<String>? imagePaths,
    List<String>? imageUrls,
    double? distanceKm,
    double? farmerRating,
  }) {
    return ProductModel(
      id: id,
      farmerId: farmerId,
      farmerName: farmerName,
      farmerPhone: farmerPhone,
      farmerCity: farmerCity,
      farmerRating: farmerRating ?? this.farmerRating,
      name: name ?? this.name,
      category: category ?? this.category,
      pricePerUnit: pricePerUnit ?? this.pricePerUnit,
      unit: unit ?? this.unit,
      quantityAvailable: quantityAvailable ?? this.quantityAvailable,
      location: location ?? this.location,
      latitude: latitude,
      longitude: longitude,
      imagePaths: imagePaths ?? this.imagePaths,
      imageUrls: imageUrls ?? this.imageUrls,
      description: description ?? this.description,
      isAvailable: isAvailable ?? this.isAvailable,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      distanceKm: distanceKm ?? this.distanceKm,
    );
  }
}
