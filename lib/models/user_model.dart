/// Payment info for a single wallet method (JazzCash or Easypaisa).
class WalletInfo {
  final String accountName;
  final String accountNumber;

  const WalletInfo({
    required this.accountName,
    required this.accountNumber,
  });

  factory WalletInfo.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const WalletInfo(accountName: '', accountNumber: '');
    return WalletInfo(
      accountName: map['accountName'] ?? '',
      accountNumber: map['accountNumber'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'accountName': accountName,
        'accountNumber': accountNumber,
      };

  bool get isEmpty => accountName.isEmpty && accountNumber.isEmpty;
  bool get isValid => accountName.isNotEmpty && accountNumber.isNotEmpty;
}

/// Holds farmer's payment methods (JazzCash and/or Easypaisa).
class FarmerPaymentInfo {
  final WalletInfo jazzCash;
  final WalletInfo easypaisa;

  const FarmerPaymentInfo({
    required this.jazzCash,
    required this.easypaisa,
  });

  const FarmerPaymentInfo.empty()
      : jazzCash = const WalletInfo(accountName: '', accountNumber: ''),
        easypaisa = const WalletInfo(accountName: '', accountNumber: '');

  factory FarmerPaymentInfo.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const FarmerPaymentInfo.empty();
    return FarmerPaymentInfo(
      jazzCash: WalletInfo.fromMap(map['jazzCash'] as Map<String, dynamic>?),
      easypaisa: WalletInfo.fromMap(map['easypaisa'] as Map<String, dynamic>?),
    );
  }

  Map<String, dynamic> toMap() => {
        'jazzCash': jazzCash.toMap(),
        'easypaisa': easypaisa.toMap(),
      };

  bool get hasAny => jazzCash.isValid || easypaisa.isValid;

  FarmerPaymentInfo copyWith({
    WalletInfo? jazzCash,
    WalletInfo? easypaisa,
  }) {
    return FarmerPaymentInfo(
      jazzCash: jazzCash ?? this.jazzCash,
      easypaisa: easypaisa ?? this.easypaisa,
    );
  }
}

class UserModel {
  final String id;
  final String fullName;
  final String phoneNumber;
  final String email;
  final String role; // farmer, buyer, transporter
  final String? profileImageUrl;
  final String city;

  /// Old single-field wallet (kept for backward compat).
  final String? walletNumber;

  /// New structured payment info — only relevant for farmers.
  final FarmerPaymentInfo paymentInfo;

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
    FarmerPaymentInfo? paymentInfo,
    this.rating = 0.0,
    this.totalRatings = 0,
    this.isBanned = false,
    required this.createdAt,
  }) : paymentInfo = paymentInfo ?? const FarmerPaymentInfo.empty();

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
      paymentInfo: FarmerPaymentInfo.fromMap(
          map['paymentInfo'] as Map<String, dynamic>?),
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
      'paymentInfo': paymentInfo.toMap(),
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
    FarmerPaymentInfo? paymentInfo,
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
      paymentInfo: paymentInfo ?? this.paymentInfo,
      rating: rating ?? this.rating,
      totalRatings: totalRatings ?? this.totalRatings,
      createdAt: createdAt,
    );
  }
}
