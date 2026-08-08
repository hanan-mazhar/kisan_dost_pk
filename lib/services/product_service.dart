import 'dart:io';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product_model.dart';
import '../utils/constants.dart';

class ProductService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── CLOUDINARY CONFIG ─────────────────────────────────────────────────────
  static const String _cloudName = 'dafmwwruo';
  static const String _uploadPreset = 'kisan_products';
  static const String _uploadUrl =
      'https://api.cloudinary.com/v1_1/dafmwwruo/image/upload';

  // ── UPLOAD IMAGE TO CLOUDINARY ────────────────────────────────────────────
  /// Single image upload — returns public URL
  Future<String?> _uploadToCloudinary(File image) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse(_uploadUrl));
      request.fields['upload_preset'] = _uploadPreset;
      request.files.add(await http.MultipartFile.fromPath('file', image.path));

      final response = await request.send();
      final body = await response.stream.bytesToString();
      final json = jsonDecode(body);

      if (response.statusCode == 200) {
        return json['secure_url'] as String?;
      } else {
        return null;
      }
    } catch (_) {
      return null;
    }
  }

  /// Upload multiple images — returns list of URLs
  Future<List<String>> uploadImages(List<File> images) async {
    final List<String> urls = [];
    for (final img in images) {
      final url = await _uploadToCloudinary(img);
      if (url != null) urls.add(url);
    }
    return urls;
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
  Future<String> addProduct(
    ProductModel product, {
    List<File>? localImages,
    void Function(int current, int total)? onProgress,
  }) async {
    // Keep existing URLs, upload new images to Cloudinary
    List<String> existingUrls = List.from(product.imageUrls);

    if (localImages != null && localImages.isNotEmpty) {
      for (int i = 0; i < localImages.length; i++) {
        onProgress?.call(i, localImages.length);
        final url = await _uploadToCloudinary(localImages[i]);
        if (url != null) existingUrls.add(url);
      }
      onProgress?.call(localImages.length, localImages.length);
    }

    final productWithImages = product.copyWith(imageUrls: existingUrls, imagePaths: []);
    final doc = await _db
        .collection(AppConstants.productsCol)
        .add(productWithImages.toMap());

    return doc.id;
  }

  Future<void> updateProduct(
    ProductModel product, {
    List<File>? newImages,
    void Function(int current, int total)? onProgress,
  }) async {
    List<String> existingUrls = List.from(product.imageUrls);

    if (newImages != null && newImages.isNotEmpty) {
      for (int i = 0; i < newImages.length; i++) {
        onProgress?.call(i, newImages.length);
        final url = await _uploadToCloudinary(newImages[i]);
        if (url != null) existingUrls.add(url);
      }
      onProgress?.call(newImages.length, newImages.length);
    }

    final updated = product.copyWith(imageUrls: existingUrls, imagePaths: []);
    await _db
        .collection(AppConstants.productsCol)
        .doc(product.id)
        .update(updated.toMap());
  }

  Future<void> deleteProduct(String productId) async {
    await _db
        .collection(AppConstants.productsCol)
        .doc(productId)
        .delete();
    // Note: Cloudinary free plan does not require deletion via API
  }

  Stream<List<ProductModel>> getFarmerProducts(String farmerId) {
    return _db
        .collection(AppConstants.productsCol)
        .where('farmerId', isEqualTo: farmerId)
        .snapshots()
        .map((s) {
      final products =
          s.docs.map((d) => ProductModel.fromMap(d.data(), d.id)).toList();
      products.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return products;
    });
  }

  Future<List<ProductModel>> getProducts({
    String? category,
    String? city,
    double? maxPrice,
    String? search,
    bool fromCache = false,
  }) async {
    try {
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

      products.sort((a, b) => b.createdAt.compareTo(a.createdAt));

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

      await _cacheProducts(products);
      return products;
    } catch (e) {
      final cached = await _getCachedProducts();
      if (cached.isNotEmpty) return cached;
      return [];
    }
  }

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
      final sorted = Map.fromEntries(
          counts.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value)));
      return sorted;
    } catch (_) {
      return {};
    }
  }
}
