import 'dart:io';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import '../models/order_model.dart';
import '../models/other_models.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';
import 'notification_service.dart';

class OrderService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final _notifSvc = NotificationService();

  // ── PLACE ORDER ───────────────────────────────────────────────────────────
  Future<String> placeOrder(OrderModel order) async {
    final doc = await _db.collection(AppConstants.ordersCol).add(order.toMap());

    // Notify the farmer about the new order
    await _notifSvc.notifyNewOrder(
      farmerId: order.farmerId,
      buyerName: order.buyerName,
      productName: order.productName,
      quantity: order.quantity,
      unit: order.unit,
      orderId: doc.id,
    );

    return doc.id;
  }

  // ── UPDATE STATUS ─────────────────────────────────────────────────────────
  Future<void> updateOrderStatus(
      String orderId, String status, {
      // Pass order info so we can notify the buyer
      String? buyerId,
      String? productName,
    }) async {
    await _db.collection(AppConstants.ordersCol).doc(orderId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Notify the buyer about the status change
    if (buyerId != null && productName != null) {
      await _notifSvc.notifyOrderStatusChange(
        buyerId: buyerId,
        status: status,
        productName: productName,
        orderId: orderId,
      );
    }
  }

  static const String _uploadUrl =
      'https://api.cloudinary.com/v1_1/dafmwwruo/image/upload';

  /// Upload payment proof to Cloudinary — returns public URL
  Future<String> savePaymentProofLocally(String orderId, File file) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse(_uploadUrl));
      request.fields['upload_preset'] = 'kisan_products';
      request.fields['public_id'] = 'payment_proofs/$orderId';
      request.files.add(await http.MultipartFile.fromPath('file', file.path));

      final response = await request.send();
      final body = await response.stream.bytesToString();
      final json = jsonDecode(body);

      if (response.statusCode == 200) {
        return json['secure_url'] as String;
      } else {
        throw Exception("Cloudinary upload failed: ${json['error']}");
      }
    } catch (e) {
      throw Exception('Payment proof upload failed: $e');
    }
  }

  Future<void> updatePayment(
      String orderId, String status, String? proofPath, {
      String? farmerId,
      String? productName,
    }) async {
    await _db.collection(AppConstants.ordersCol).doc(orderId).update({
      'paymentStatus': status,
      if (proofPath != null) 'paymentProofPath': proofPath,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (farmerId != null && productName != null && status == 'Paid') {
      await _notifSvc.sendNotification(
        toUserId: farmerId,
        title: 'Payment Received 💰',
        body: 'Buyer submitted payment proof for $productName. Please verify.',
        type: 'order',
        emoji: '💰',
        payload: {'orderId': orderId},
      );
    }
  }

  Future<void> verifyPayment(String orderId, {
    String? buyerId,
    String? productName,
  }) async {
    await _db.collection(AppConstants.ordersCol).doc(orderId).update({
      'paymentStatus': 'Verified',
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (buyerId != null && productName != null) {
      await _notifSvc.sendNotification(
        toUserId: buyerId,
        title: 'Payment Verified ✅',
        body: 'Your payment for $productName has been verified by the farmer.',
        type: 'order',
        emoji: '✅',
        payload: {'orderId': orderId},
      );
    }
  }

  Stream<List<OrderModel>> getBuyerOrders(String buyerId) {
    return _db
        .collection(AppConstants.ordersCol)
        .where('buyerId', isEqualTo: buyerId)
        .snapshots()
        .map((s) {
      final orders =
          s.docs.map((d) => OrderModel.fromMap(d.data(), d.id)).toList();
      orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return orders;
    });
  }

  Stream<List<OrderModel>> getFarmerOrders(String farmerId) {
    return _db
        .collection(AppConstants.ordersCol)
        .where('farmerId', isEqualTo: farmerId)
        .snapshots()
        .map((s) {
      final orders =
          s.docs.map((d) => OrderModel.fromMap(d.data(), d.id)).toList();
      orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return orders;
    });
  }

  Future<OrderModel?> getOrder(String orderId) async {
    final doc =
        await _db.collection(AppConstants.ordersCol).doc(orderId).get();
    if (!doc.exists) return null;
    return OrderModel.fromMap(doc.data()!, doc.id);
  }

  Future<void> submitRating(RatingModel rating) async {
    await _db.collection(AppConstants.ratingsCol).add(rating.toMap());

    await _db
        .collection(AppConstants.ordersCol)
        .doc(rating.orderId)
        .update({'isRated': true});

    final snap = await _db
        .collection(AppConstants.ratingsCol)
        .where('farmerId', isEqualTo: rating.farmerId)
        .get();

    double total = 0;
    for (var d in snap.docs) {
      total += (d.data()['rating'] ?? 0.0) as double;
    }
    final avg = snap.docs.isEmpty ? 0.0 : total / snap.docs.length;

    await _db.collection(AppConstants.usersCol).doc(rating.farmerId).update({
      'rating': avg,
      'totalRatings': snap.docs.length,
    });

    // Notify farmer about the new rating
    await _notifSvc.sendNotification(
      toUserId: rating.farmerId,
      title: 'New Rating Received ⭐',
      body:
          '${rating.buyerName} gave you ${rating.rating.toStringAsFixed(0)} stars!'
          '${rating.review.isNotEmpty ? ' "${rating.review}"' : ''}',
      type: 'rating',
      emoji: '⭐',
      payload: {'orderId': rating.orderId},
    );
  }

  // ── FARMER EARNINGS ───────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getFarmerEarnings(String farmerId) async {
    try {
      final orders = await _db
          .collection(AppConstants.ordersCol)
          .where('farmerId', isEqualTo: farmerId)
          .get(const GetOptions(source: Source.serverAndCache));

      double total = 0;
      int delivered = 0;
      for (var d in orders.docs) {
        final data = d.data();
        if (data['status'] == AppConstants.statusDelivered) {
          total += ((data['totalAmount'] ?? 0.0) as num).toDouble();
          delivered++;
        }
      }
      return {
        'totalEarnings': total,
        'totalOrders': delivered,
      };
    } catch (_) {
      return {'totalEarnings': 0.0, 'totalOrders': 0};
    }
  }

  // ── GET PAYMENT PROOF FILE ────────────────────────────────────────────────
  File? getPaymentProofFile(String proofPath) {
    if (proofPath.isEmpty) return null;
    final f = File(proofPath);
    return f.existsSync() ? f : null;
  }

  // ── GET FARMER PAYMENT INFO ───────────────────────────────────────────────
  Future<FarmerPaymentInfo> getFarmerPaymentInfo(String farmerId) async {
    try {
      final doc = await _db.collection('users').doc(farmerId).get();
      if (!doc.exists) return const FarmerPaymentInfo.empty();
      final data = doc.data();
      if (data == null) return const FarmerPaymentInfo.empty();
      return FarmerPaymentInfo.fromMap(
          data['paymentInfo'] as Map<String, dynamic>?);
    } catch (_) {
      return const FarmerPaymentInfo.empty();
    }
  }
}
