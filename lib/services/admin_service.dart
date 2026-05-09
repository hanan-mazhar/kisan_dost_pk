import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/product_model.dart';
import '../models/order_model.dart';
import '../models/other_models.dart';
import '../utils/constants.dart';

class AdminService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── USERS ─────────────────────────────────────────────────────────────────

  Stream<List<UserModel>> watchAllUsers() {
    return _db.collection(AppConstants.usersCol).snapshots().map((s) {
      final users = s.docs.map((d) => UserModel.fromMap(d.data(), d.id)).toList();
      users.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return users;
    });
  }

  Future<void> changeUserRole(String userId, String newRole) =>
      _db.collection(AppConstants.usersCol).doc(userId).update({'role': newRole});

  Future<void> setBanStatus(String userId, bool banned) =>
      _db.collection(AppConstants.usersCol).doc(userId).update({'isBanned': banned});

  Future<void> deleteUser(String userId) =>
      _db.collection(AppConstants.usersCol).doc(userId).delete();

  // ── PRODUCTS ──────────────────────────────────────────────────────────────

  Stream<List<ProductModel>> watchAllProducts() {
    return _db.collection(AppConstants.productsCol).snapshots().map((s) {
      final products = s.docs
          .map((d) => ProductModel.fromMap(d.data(), d.id))
          .toList();
      products.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return products;
    });
  }

  Future<void> deleteProduct(String productId) =>
      _db.collection(AppConstants.productsCol).doc(productId).delete();

  Future<void> toggleProductAvailability(String productId, bool isAvailable) =>
      _db.collection(AppConstants.productsCol).doc(productId).update({'isAvailable': isAvailable});

  // ── ORDERS ────────────────────────────────────────────────────────────────

  Stream<List<OrderModel>> watchAllOrders() {
    return _db.collection(AppConstants.ordersCol).snapshots().map((s) {
      final orders = s.docs
          .map((d) => OrderModel.fromMap(d.data(), d.id))
          .toList();
      orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return orders;
    });
  }

  Future<void> deleteOrder(String orderId) =>
      _db.collection(AppConstants.ordersCol).doc(orderId).delete();

  Future<void> updateOrderStatus(String orderId, String status) =>
      _db.collection(AppConstants.ordersCol).doc(orderId).update({'status': status});

  // ── STATS ─────────────────────────────────────────────────────────────────

  Future<Map<String, int>> getStats() async {
    final results = await Future.wait([
      _db.collection(AppConstants.usersCol).get(),
      _db.collection(AppConstants.productsCol).get(),
      _db.collection(AppConstants.ordersCol).get(),
      _db.collection(AppConstants.mandiRatesCol).get(),
    ]);
    final users = results[0].docs;
    final orders = results[2].docs;
    return {
      'total_users': users.length,
      'farmers': users.where((d) => d.data()['role'] == AppConstants.roleFarmer).length,
      'buyers': users.where((d) => d.data()['role'] == AppConstants.roleBuyer).length,
      'transporters': users.where((d) => d.data()['role'] == AppConstants.roleTransporter).length,
      'banned': users.where((d) => d.data()['isBanned'] == true).length,
      'products': results[1].docs.length,
      'orders': orders.length,
      'pending_orders': orders.where((d) => d.data()['status'] == AppConstants.statusPending).length,
      'mandi_rates': results[3].docs.length,
    };
  }

  // ── MANDI RATES ───────────────────────────────────────────────────────────

  Stream<List<MandiRate>> watchAllMandiRates() {
    return _db.collection(AppConstants.mandiRatesCol).snapshots().map((s) {
      final rates = s.docs
          .map((d) => MandiRate.fromMap(d.data(), d.id))
          .toList();
      rates.sort((a, b) {
        final c = a.cropName.compareTo(b.cropName);
        return c != 0 ? c : a.city.compareTo(b.city);
      });
      return rates;
    });
  }

  Future<void> updateMandiRate(String rateId, {
    required double newPrice,
    required double previousPrice,
  }) async {
    final change = newPrice - previousPrice;
    final changePct = previousPrice > 0 ? (change / previousPrice) * 100 : 0.0;
    final doc = await _db.collection(AppConstants.mandiRatesCol).doc(rateId).get();
    List<dynamic> last7 = (doc.data()?['last7Days'] as List<dynamic>?) ?? [];
    last7.add(newPrice);
    if (last7.length > 7) last7 = last7.sublist(last7.length - 7);
    await _db.collection(AppConstants.mandiRatesCol).doc(rateId).update({
      'pricePerUnit': newPrice,
      'changeAmount': change,
      'changePercent': changePct,
      'isTrendUp': change >= 0,
      'date': Timestamp.now(),
      'last7Days': last7,
    });
  }

  Future<void> addMandiRate({
    required String cropName,
    required String city,
    required double price,
    required String unit,
  }) async {
    await _db.collection(AppConstants.mandiRatesCol).add({
      'cropName': cropName, 'city': city,
      'pricePerUnit': price, 'unit': unit,
      'changeAmount': 0.0, 'changePercent': 0.0,
      'isTrendUp': true, 'date': Timestamp.now(),
      'last7Days': [price],
    });
  }

  Future<void> deleteMandiRate(String rateId) =>
      _db.collection(AppConstants.mandiRatesCol).doc(rateId).delete();

  Future<void> reseedMandiData() async {
    final existing = await _db.collection(AppConstants.mandiRatesCol).get();
    final b1 = _db.batch();
    for (var d in existing.docs) {
      b1.delete(d.reference);
    }
    await b1.commit();

    final crops = ['Wheat', 'Rice', 'Maize', 'Tomato', 'Onion', 'Potato', 'Sugarcane', 'Cotton', 'Mango'];
    final cities = ['Lahore', 'Multan', 'Faisalabad', 'Karachi', 'Rawalpindi', 'Peshawar', 'Quetta', 'Hyderabad'];
    final base = {'Wheat': 2600.0, 'Rice': 3200.0, 'Maize': 2100.0, 'Tomato': 120.0,
      'Onion': 80.0, 'Potato': 60.0, 'Sugarcane': 450.0, 'Cotton': 8500.0, 'Mango': 200.0};
    final units = {'Wheat': '40kg', 'Rice': '40kg', 'Maize': '40kg', 'Tomato': 'kg',
      'Onion': 'kg', 'Potato': 'kg', 'Sugarcane': '40kg', 'Cotton': '40kg', 'Mango': 'kg'};

    final b2 = _db.batch();
    for (var crop in crops) {
      for (var city in cities) {
        double p = base[crop]!;
        final last7 = <double>[];
        for (int i = 6; i >= 0; i--) {
          p += p * 0.02 * (i % 2 == 0 ? 1 : -1);
          last7.add(double.parse(p.toStringAsFixed(0)));
        }
        final cur = last7.last;
        final prev = last7[last7.length - 2];
        final chg = cur - prev;
        b2.set(_db.collection(AppConstants.mandiRatesCol).doc(), {
          'cropName': crop, 'city': city, 'pricePerUnit': cur,
          'unit': units[crop] ?? 'kg', 'changeAmount': chg,
          'changePercent': (chg / prev) * 100, 'isTrendUp': chg > 0,
          'date': Timestamp.now(), 'last7Days': last7,
        });
      }
    }
    await b2.commit();
  }
}
