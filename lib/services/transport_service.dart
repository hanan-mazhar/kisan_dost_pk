import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/other_models.dart';
import '../utils/constants.dart';

class TransportService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Add route (transporter)
  Future<void> addRoute(TransportRoute route) async {
    await _db.collection(AppConstants.transportCol).add(route.toMap());
  }

  // Get transporter's routes
  Stream<List<TransportRoute>> getMyRoutes(String transporterId) {
    return _db
        .collection(AppConstants.transportCol)
        .where('transporterId', isEqualTo: transporterId)
        .snapshots()
        .map((s) {
      final routes = s.docs
          .map((d) => TransportRoute.fromMap(d.data(), d.id))
          .toList();
      routes.sort((a, b) => a.departureDate.compareTo(b.departureDate));
      return routes;
    });
  }

  // Get available routes for farmers
  // NOTE: No orderBy to avoid composite index requirement. Sort client-side.
  Future<List<TransportRoute>> getAvailableRoutes({
    String? fromCity,
    String? toCity,
  }) async {
    try {
      Query query = _db
          .collection(AppConstants.transportCol)
          .where('isAvailable', isEqualTo: true);

      if (fromCity != null && fromCity.isNotEmpty) {
        query = query.where('fromCity', isEqualTo: fromCity);
      }
      if (toCity != null && toCity.isNotEmpty) {
        query = query.where('toCity', isEqualTo: toCity);
      }

      final snapshot = await query.get();
      final routes = snapshot.docs
          .map((d) =>
              TransportRoute.fromMap(d.data() as Map<String, dynamic>, d.id))
          .toList();
      // Sort by departureDate ascending client-side
      routes.sort((a, b) => a.departureDate.compareTo(b.departureDate));
      return routes;
    } catch (e) {
      return [];
    }
  }

  // Delete route
  Future<void> deleteRoute(String routeId) async {
    await _db.collection(AppConstants.transportCol).doc(routeId).delete();
  }

  // Toggle availability
  Future<void> toggleAvailability(String routeId, bool isAvailable) async {
    await _db
        .collection(AppConstants.transportCol)
        .doc(routeId)
        .update({'isAvailable': isAvailable});
  }
}
