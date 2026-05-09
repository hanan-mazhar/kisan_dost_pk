import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/other_models.dart';
import '../utils/constants.dart';

class MandiService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // NOTE: No orderBy on compound queries to avoid composite index requirement.
  // Sorting done client-side.
  Stream<List<MandiRate>> getMandiRates({String? city}) {
    Query query = _db.collection(AppConstants.mandiRatesCol);
    if (city != null && city.isNotEmpty) {
      query = query.where('city', isEqualTo: city);
    }
    return query.snapshots().map((s) {
      final rates = s.docs
          .map((d) => MandiRate.fromMap(d.data() as Map<String, dynamic>, d.id))
          .toList();
      // Sort by date descending client-side
      rates.sort((a, b) => b.date.compareTo(a.date));
      return rates;
    });
  }

  // Get price suggestion for a crop
  Future<Map<String, dynamic>> getPriceSuggestion(
      String cropName, String city) async {
    try {
      // Simple query - just filter by cropName, avoid compound index
      final snapshot = await _db
          .collection(AppConstants.mandiRatesCol)
          .where('cropName', isEqualTo: cropName)
          .get();

      if (snapshot.docs.isEmpty) {
        return {'recommendation': 'No data available for $cropName. Try seeding sample data first.', 'shouldSell': false};
      }

      // Filter by city client-side
      var rates = snapshot.docs
          .map((d) => MandiRate.fromMap(d.data(), d.id))
          .where((r) => city.isEmpty || r.city == city)
          .toList();

      if (rates.isEmpty) {
        // Fall back to all cities if no data for selected city
        rates = snapshot.docs
            .map((d) => MandiRate.fromMap(d.data(), d.id))
            .toList();
      }

      // Sort by date descending
      rates.sort((a, b) => b.date.compareTo(a.date));
      final recentRates = rates.take(7).toList();

      final currentPrice = recentRates.first.pricePerUnit;
      double avg = 0;
      for (var r in recentRates) {
        avg += r.pricePerUnit;
      }
      avg = avg / recentRates.length;

      final aboveAvg = currentPrice > avg * 1.05;
      final trend = recentRates.first.isTrendUp;

      String recommendation;
      bool shouldSell;

      if (aboveAvg && trend) {
        recommendation = '🔥 Excellent time to sell! Price is above average and trending up.';
        shouldSell = true;
      } else if (aboveAvg) {
        recommendation = '✅ Good time to sell. Current price is above 7-day average.';
        shouldSell = true;
      } else if (trend) {
        recommendation = '⏳ Price is rising. Consider waiting 1-2 days for a better price.';
        shouldSell = false;
      } else {
        recommendation = '📉 Price is low and trending down. Wait for a better opportunity.';
        shouldSell = false;
      }

      return {
        'recommendation': recommendation,
        'shouldSell': shouldSell,
        'currentPrice': currentPrice,
        'avgPrice': avg,
        '7dayPrices': recentRates.map((r) => r.pricePerUnit).toList(),
      };
    } catch (e) {
      return {'recommendation': 'Error loading data: ${e.toString()}', 'shouldSell': false};
    }
  }

  // Seed sample mandi data (call once for demo)
  Future<void> seedSampleData() async {
    final crops = ['Wheat', 'Rice', 'Maize', 'Tomato', 'Onion', 'Potato'];
    final cities = ['Lahore', 'Multan', 'Faisalabad', 'Karachi', 'Rawalpindi'];
    final basePrices = {
      'Wheat': 2600.0,
      'Rice': 3200.0,
      'Maize': 2100.0,
      'Tomato': 120.0,
      'Onion': 80.0,
      'Potato': 60.0,
    };

    // Check if data already exists
    final existing = await _db.collection(AppConstants.mandiRatesCol).limit(1).get();
    if (existing.docs.isNotEmpty) return; // Already seeded

    final batch = _db.batch();
    for (var crop in crops) {
      for (var city in cities) {
        double base = basePrices[crop]!;
        List<double> last7 = [];
        for (int i = 6; i >= 0; i--) {
          base += (base * 0.02 * (i % 2 == 0 ? 1 : -1));
          last7.add(double.parse(base.toStringAsFixed(0)));
        }
        final current = last7.last;
        final prev = last7[last7.length - 2];
        final change = current - prev;

        final ref = _db.collection(AppConstants.mandiRatesCol).doc();
        batch.set(ref, {
          'cropName': crop,
          'city': city,
          'pricePerUnit': current,
          'unit': crop == 'Tomato' || crop == 'Onion' || crop == 'Potato' ? 'kg' : '40kg',
          'changeAmount': change,
          'changePercent': (change / prev) * 100,
          'isTrendUp': change > 0,
          'date': Timestamp.now(),
          'last7Days': last7,
        });
      }
    }
    await batch.commit();
  }
}
