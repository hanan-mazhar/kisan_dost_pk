class MandiRate {
  final String id;
  final String cropName;
  final String city;
  final double pricePerUnit;
  final String unit;
  final double changeAmount;
  final double changePercent;
  final bool isTrendUp;
  final DateTime date;
  final List<double> last7Days;

  MandiRate({
    required this.id,
    required this.cropName,
    required this.city,
    required this.pricePerUnit,
    required this.unit,
    required this.changeAmount,
    required this.changePercent,
    required this.isTrendUp,
    required this.date,
    required this.last7Days,
  });

  factory MandiRate.fromMap(Map<String, dynamic> map, String id) {
    return MandiRate(
      id: id,
      cropName: map['cropName'] ?? '',
      city: map['city'] ?? '',
      pricePerUnit: (map['pricePerUnit'] ?? 0.0).toDouble(),
      unit: map['unit'] ?? '40kg',
      changeAmount: (map['changeAmount'] ?? 0.0).toDouble(),
      changePercent: (map['changePercent'] ?? 0.0).toDouble(),
      isTrendUp: map['isTrendUp'] ?? true,
      date: map['date'] != null
          ? (map['date'] as dynamic).toDate()
          : DateTime.now(),
      last7Days: List<double>.from(
          (map['last7Days'] ?? []).map((e) => (e as num).toDouble())),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'cropName': cropName,
      'city': city,
      'pricePerUnit': pricePerUnit,
      'unit': unit,
      'changeAmount': changeAmount,
      'changePercent': changePercent,
      'isTrendUp': isTrendUp,
      'date': date,
      'last7Days': last7Days,
    };
  }
}

class TransportRoute {
  final String id;
  final String transporterId;
  final String transporterName;
  final String transporterPhone;
  final String fromCity;
  final String toCity;
  final DateTime departureDate;
  final double availableSpaceKg;
  final double pricePerKg;
  final String vehicleType;
  final bool isAvailable;

  TransportRoute({
    required this.id,
    required this.transporterId,
    required this.transporterName,
    required this.transporterPhone,
    required this.fromCity,
    required this.toCity,
    required this.departureDate,
    required this.availableSpaceKg,
    required this.pricePerKg,
    required this.vehicleType,
    this.isAvailable = true,
  });

  factory TransportRoute.fromMap(Map<String, dynamic> map, String id) {
    return TransportRoute(
      id: id,
      transporterId: map['transporterId'] ?? '',
      transporterName: map['transporterName'] ?? '',
      transporterPhone: map['transporterPhone'] ?? '',
      fromCity: map['fromCity'] ?? '',
      toCity: map['toCity'] ?? '',
      departureDate: map['departureDate'] != null
          ? (map['departureDate'] as dynamic).toDate()
          : DateTime.now(),
      availableSpaceKg: (map['availableSpaceKg'] ?? 0.0).toDouble(),
      pricePerKg: (map['pricePerKg'] ?? 0.0).toDouble(),
      vehicleType: map['vehicleType'] ?? 'Truck',
      isAvailable: map['isAvailable'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'transporterId': transporterId,
      'transporterName': transporterName,
      'transporterPhone': transporterPhone,
      'fromCity': fromCity,
      'toCity': toCity,
      'departureDate': departureDate,
      'availableSpaceKg': availableSpaceKg,
      'pricePerKg': pricePerKg,
      'vehicleType': vehicleType,
      'isAvailable': isAvailable,
    };
  }
}

class RatingModel {
  final String id;
  final String orderId;
  final String farmerId;
  final String buyerId;
  final String buyerName;
  final double rating;
  final String review;
  final DateTime createdAt;

  RatingModel({
    required this.id,
    required this.orderId,
    required this.farmerId,
    required this.buyerId,
    required this.buyerName,
    required this.rating,
    required this.review,
    required this.createdAt,
  });

  factory RatingModel.fromMap(Map<String, dynamic> map, String id) {
    return RatingModel(
      id: id,
      orderId: map['orderId'] ?? '',
      farmerId: map['farmerId'] ?? '',
      buyerId: map['buyerId'] ?? '',
      buyerName: map['buyerName'] ?? '',
      rating: (map['rating'] ?? 0.0).toDouble(),
      review: map['review'] ?? '',
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as dynamic).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'orderId': orderId,
      'farmerId': farmerId,
      'buyerId': buyerId,
      'buyerName': buyerName,
      'rating': rating,
      'review': review,
      'createdAt': createdAt,
    };
  }
}
