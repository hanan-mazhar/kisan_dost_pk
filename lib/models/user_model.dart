class UserModel {
  final String id;
  final String fullName;
  final String phoneNumber;
  final String email;
  final String role; // farmer, buyer, transporter
  final String? profileImageUrl;
  final String city;
  final String? walletNumber; // for Easypaisa/JazzCash
  final double rating;
  final int totalRatings;
  final bool isBanned;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.fullName,
    required this.phoneNumber,
    required this.email,
    required this.role,
    this.profileImageUrl,
    required this.city,
    this.walletNumber,
    this.rating = 0.0,
    this.totalRatings = 0,
    this.isBanned = false,
    required this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      id: id,
      fullName: map['fullName'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? '',
      profileImageUrl: map['profileImageUrl'],
      city: map['city'] ?? '',
      walletNumber: map['walletNumber'],
      rating: (map['rating'] ?? 0.0).toDouble(),
      totalRatings: map['totalRatings'] ?? 0,
      isBanned: map['isBanned'] ?? false,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as dynamic).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'email': email,
      'role': role,
      'profileImageUrl': profileImageUrl,
      'city': city,
      'walletNumber': walletNumber,
      'rating': rating,
      'totalRatings': totalRatings,
      'isBanned': isBanned,
      'createdAt': createdAt,
    };
  }

  UserModel copyWith({
    String? fullName,
    String? phoneNumber,
    String? email,
    String? profileImageUrl,
    String? city,
    String? walletNumber,
    double? rating,
    int? totalRatings,
  }) {
    return UserModel(
      id: id,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      role: role,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      city: city ?? this.city,
      walletNumber: walletNumber ?? this.walletNumber,
      rating: rating ?? this.rating,
      totalRatings: totalRatings ?? this.totalRatings,
      createdAt: createdAt,
    );
  }
}
