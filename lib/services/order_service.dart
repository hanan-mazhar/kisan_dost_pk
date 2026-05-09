import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';
import '../models/order_model.dart';
import '../models/other_models.dart';
import '../utils/constants.dart';

class OrderService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── PLACE ORDER ───────────────────────────────────────────────────────────
  Future<String> placeOrder(OrderModel order) async {
    final doc =
        await _db.collection(AppConstants.ordersCol).add(order.toMap());
    return doc.id;
  }

  // ── UPDATE STATUS ─────────────────────────────────────────────────────────
  Future<void> updateOrderStatus(String orderId, String status) async {
    await _db.collection(AppConstants.ordersCol).doc(orderId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ── SAVE PAYMENT PROOF LOCALLY (no Firebase Storage) ─────────────────────
  Future<String> savePaymentProofLocally(
      String orderId, File file) async {
    final dir = await getApplicationDocumentsDirectory();
    final proofDir =
        Directory('${dir.path}/payment_proofs');
    await proofDir.create(recursive: true);

    final dest = File('${proofDir.path}/$orderId.jpg');
    await file.copy(dest.path);
    return dest.path; // local path, not URL
  }

  // ── UPDATE PAYMENT ────────────────────────────────────────────────────────
  Future<void> updatePayment(
      String orderId, String status, String? proofPath) async {
    await _db.collection(AppConstants.ordersCol).doc(orderId).update({
      'paymentStatus': status,
      if (proofPath != null) 'paymentProofPath': proofPath,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ── VERIFY PAYMENT (farmer confirms) ─────────────────────────────────────
  Future<void> verifyPayment(String orderId) async {
    await _db.collection(AppConstants.ordersCol).doc(orderId).update({
      'paymentStatus': 'Verified',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ── BUYER ORDERS stream ───────────────────────────────────────────────────
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

  // ── FARMER ORDERS stream ──────────────────────────────────────────────────
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

  // ── SINGLE ORDER ──────────────────────────────────────────────────────────
  Future<OrderModel?> getOrder(String orderId) async {
    final doc = await _db
        .collection(AppConstants.ordersCol)
        .doc(orderId)
        .get();
    if (!doc.exists) return null;
    return OrderModel.fromMap(doc.data()!, doc.id);
  }

  // ── SUBMIT RATING ─────────────────────────────────────────────────────────
  Future<void> submitRating(RatingModel rating) async {
    // Add rating doc
    await _db.collection(AppConstants.ratingsCol).add(rating.toMap());

    // Mark order as rated
    await _db
        .collection(AppConstants.ordersCol)
        .doc(rating.orderId)
        .update({'isRated': true});

    // Recalculate farmer average rating
    final snap = await _db
        .collection(AppConstants.ratingsCol)
        .where('farmerId', isEqualTo: rating.farmerId)
        .get();

    double total = 0;
    for (var d in snap.docs) {
      total += (d.data()['rating'] ?? 0.0) as double;
    }
    final avg = snap.docs.isEmpty ? 0.0 : total / snap.docs.length;

    await _db
        .collection(AppConstants.usersCol)
        .doc(rating.farmerId)
        .update({
      'rating': avg,
      'totalRatings': snap.docs.length,
    });
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
}
