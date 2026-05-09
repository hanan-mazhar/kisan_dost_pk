import 'dart:io';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product_model.dart';
import '../utils/constants.dart';

class ProductService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── LOCAL IMAGE STORAGE (no Firebase Storage) ─────────────────────────────
  /// Save images locally and return their local paths
  Future<List<String>> saveImagesLocally(
      List<File> images, String productId) async {
    final dir = await getApplicationDocumentsDirectory();
    final productDir =
        Directory('${dir.path}/products/$productId');
    await productDir.create(recursive: true);

    List<String> paths = [];
    for (int i = 0; i < images.length; i++) {
      final dest =
          File('${productDir.path}/img_$i.jpg');
      await images[i].copy(dest.path);
      paths.add(dest.path);
    }
    return paths;
  }

  /// Get local image file from path
  File? getLocalImage(String path) {
    final f = File(path);
    return f.existsSync() ? f : null;
  }

  /// Delete local product images
  Future<void> deleteLocalImages(String productId) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final productDir =
          Directory('${dir.path}/products/$productId');
      if (productDir.existsSync()) {
        await productDir.delete(recursive: true);
      }
    } catch (_) {}
  }

  // ── OFFLINE CACHE ─────────────────────────────────────────────────────────
  Future<void> _cacheProducts(List<ProductModel> products) async {
    final prefs = await SharedPreferences.getInstance();
    final json = products.map((p) => p.toJsonString()).toList();
    await prefs.setString(AppConstants.hiveProducts, jsonEncode(json));
  }

  Future<List<ProductModel>> _getCachedProducts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(AppConstants.hiveProducts);
      if (raw == null) return [];
      final list = jsonDecode(raw) as List;
      return list
          .map((j) => ProductModel.fromJsonString(j as String))
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ── ADD PRODUCT ───────────────────────────────────────────────────────────
  Future<String> addProduct(ProductModel product,
      {List<File>? localImages}) async {
    // Save images locally first
    List<String> imagePaths = product.imagePaths;
    String tempId = DateTime.now().millisecondsSinceEpoch.toString();

    if (localImages != null && localImages.isNotEmpty) {
      imagePaths = await saveImagesLocally(localImages, tempId);
    }

    final productWithImages = product.copyWith(imagePaths: imagePaths);

    // Add to Firestore
    final doc = await _db
        .collection(AppConstants.productsCol)
        .add(productWithImages.toMap());

    // Rename local images folder to real doc ID
    if (imagePaths.isNotEmpty) {
      try {
        final dir = await getApplicationDocumentsDirectory();
        final oldDir = Directory('${dir.path}/products/$tempId');
        final newDir = Directory('${dir.path}/products/${doc.id}');
        if (oldDir.existsSync()) {
          await oldDir.rename(newDir.path);
          // Update paths
          final newPaths = imagePaths
              .map((p) => p.replaceAll(
                  '${dir.path}/products/$tempId',
                  '${dir.path}/products/${doc.id}'))
              .toList();
          await _db
              .collection(AppConstants.productsCol)
              .doc(doc.id)
              .update({'imagePaths': newPaths});
        }
      } catch (_) {}
    }

    return doc.id;
  }

  // ── UPDATE PRODUCT ────────────────────────────────────────────────────────
  Future<void> updateProduct(ProductModel product,
      {List<File>? newImages}) async {
    List<String> imagePaths = product.imagePaths;

    if (newImages != null && newImages.isNotEmpty) {
      imagePaths = await saveImagesLocally(newImages, product.id);
    }

    final updated = product.copyWith(imagePaths: imagePaths);
    await _db
        .collection(AppConstants.productsCol)
        .doc(product.id)
        .update(updated.toMap());
  }

  // ── DELETE PRODUCT ────────────────────────────────────────────────────────
  Future<void> deleteProduct(String productId) async {
    await _db
        .collection(AppConstants.productsCol)
        .doc(productId)
        .delete();
    await deleteLocalImages(productId);
  }

  // ── FARMER PRODUCTS stream ────────────────────────────────────────────────
  // NOTE: No orderBy here to avoid needing a composite Firestore index.
  // Sorting is done client-side instead.
  Stream<List<ProductModel>> getFarmerProducts(String farmerId) {
    return _db
        .collection(AppConstants.productsCol)
        .where('farmerId', isEqualTo: farmerId)
        .snapshots()
        .map((s) {
      final products =
          s.docs.map((d) => ProductModel.fromMap(d.data(), d.id)).toList();
      // Sort by createdAt descending (client-side, no index needed)
      products.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return products;
    });
  }

  // ── MARKETPLACE PRODUCTS ──────────────────────────────────────────────────
  Future<List<ProductModel>> getProducts({
    String? category,
    String? city,
    double? maxPrice,
    String? search,
    bool fromCache = false,
  }) async {
    // Try Firestore
    try {
      // NOTE: Removed orderBy from compound query to avoid composite index requirement.
      // We filter by isAvailable only, then sort client-side.
      Query query = _db
          .collection(AppConstants.productsCol)
          .where('isAvailable', isEqualTo: true);

      if (category != null && category != 'All') {
        query = query.where('category', isEqualTo: category);
      }

      final snapshot = await query
          .limit(100)
          .get(const GetOptions(source: Source.serverAndCache));

      List<ProductModel> products = snapshot.docs
          .map((d) =>
              ProductModel.fromMap(d.data() as Map<String, dynamic>, d.id))
          .toList();

      // Sort by createdAt descending client-side
      products.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      // Filter in memory
      if (city != null && city.isNotEmpty) {
        products = products
            .where((p) =>
                p.location.toLowerCase().contains(city.toLowerCase()) ||
                p.farmerCity.toLowerCase().contains(city.toLowerCase()))
            .toList();
      }
      if (maxPrice != null) {
        products =
            products.where((p) => p.pricePerUnit <= maxPrice).toList();
      }
      if (search != null && search.isNotEmpty) {
        final q = search.toLowerCase();
        products = products
            .where((p) =>
                p.name.toLowerCase().contains(q) ||
                p.category.toLowerCase().contains(q) ||
                p.location.toLowerCase().contains(q) ||
                p.farmerName.toLowerCase().contains(q))
            .toList();
      }

      // Cache for offline
      await _cacheProducts(products);
      return products;
    } catch (e) {
      // Return cached data if offline
      final cached = await _getCachedProducts();
      if (cached.isNotEmpty) return cached;
      return [];
    }
  }

  // ── SINGLE PRODUCT ────────────────────────────────────────────────────────
  Future<ProductModel?> getProduct(String productId) async {
    try {
      final doc = await _db
          .collection(AppConstants.productsCol)
          .doc(productId)
          .get(const GetOptions(source: Source.serverAndCache));
      if (!doc.exists) return null;
      return ProductModel.fromMap(doc.data()!, doc.id);
    } catch (_) {
      return null;
    }
  }

  // ── DEMAND INDICATOR ──────────────────────────────────────────────────────
  Future<Map<String, int>> getDemandIndicator() async {
    try {
      final snapshot = await _db
          .collection(AppConstants.ordersCol)
          .limit(200)
          .get(const GetOptions(source: Source.serverAndCache));

      Map<String, int> counts = {};
      for (var doc in snapshot.docs) {
        final name = doc.data()['productName'] ?? '';
        counts[name] = (counts[name] ?? 0) + 1;
      }
      // Sort by count descending
      final sorted = Map.fromEntries(
          counts.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value)));
      return sorted;
    } catch (_) {
      return {};
    }
  }
}
