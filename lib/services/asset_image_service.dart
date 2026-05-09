import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages copying bundled asset product images to local device storage
/// so they are available offline without internet.
class AssetImageService {
  static const String _prefKey = 'asset_images_copied_v1';

  // Map: category → list of asset paths inside assets/images/Products/
  static const Map<String, List<String>> categoryAssets = {
    'Wheat': [
      'assets/images/Products/Wheat1.jpeg',
      'assets/images/Products/Wheat2.jpeg',
    ],
    'Rice': [
      'assets/images/Products/Rice.jpeg',
      'assets/images/Products/Rice2.jpeg',
    ],
    'Maize': [
      'assets/images/Products/Maize1.jpeg',
      'assets/images/Products/Maize2.jpeg',
    ],
    'Tomato': [
      'assets/images/Products/Tomato1.jpeg',
      'assets/images/Products/Tomato2.jpeg',
    ],
    'Onion': [
      'assets/images/Products/onion1.jpeg',
    ],
    'Potato': [
      'assets/images/Products/ptato1.jpeg',
    ],
    'Sugarcane': [
      'assets/images/Products/sugarcane.jpeg',
    ],
    'Mango': [
      'assets/images/Products/mango1.jpeg',
      'assets/images/Products/mango2.jpeg',
    ],
    'Citrus': [
      'assets/images/Products/citrus1.jpeg',
    ],
  };

  // Map: category → SVG icon asset path
  static const Map<String, String> categoryIcons = {
    'Wheat': 'assets/icons/crop_wheat.svg',
    'Rice': 'assets/icons/crop_rice.svg',
    'Maize': 'assets/icons/crop_maize.svg',
    'Tomato': 'assets/icons/crop_tomato.svg',
    'Onion': 'assets/icons/crop_onion.svg',
    'Potato': 'assets/icons/crop_potato.svg',
    'Sugarcane': 'assets/icons/crop_sugarcane.svg',
    'Cotton': 'assets/icons/crop_cotton.svg',
    'Mango': 'assets/icons/crop_mango.svg',
    'Citrus': 'assets/icons/crop_citrus.svg',
    'Vegetables': 'assets/icons/crop_vegetables.svg',
    'Pulses': 'assets/icons/crop_pulses.svg',
  };

  /// Returns the base directory where asset images are stored locally.
  static Future<Directory> _getAssetImagesDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${appDir.path}/asset_product_images');
    await dir.create(recursive: true);
    return dir;
  }

  /// Copies all bundled asset images to local storage (runs once on first launch).
  static Future<void> copyAssetsToLocal() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_prefKey) == true) return; // already done

    final dir = await _getAssetImagesDir();

    for (final entry in categoryAssets.entries) {
      final category = entry.key;
      final assets = entry.value;
      final catDir = Directory('${dir.path}/$category');
      await catDir.create(recursive: true);

      for (int i = 0; i < assets.length; i++) {
        try {
          final ByteData data = await rootBundle.load(assets[i]);
          final Uint8List bytes = data.buffer.asUint8List();
          final fileName = assets[i].split('/').last;
          final destFile = File('${catDir.path}/$fileName');
          await destFile.writeAsBytes(bytes);
        } catch (_) {
          // Skip if asset not found
        }
      }
    }

    await prefs.setBool(_prefKey, true);
  }

  /// Returns list of local File paths for a given category.
  /// These are always available offline.
  static Future<List<File>> getLocalImagesForCategory(String category) async {
    final dir = await _getAssetImagesDir();
    final catDir = Directory('${dir.path}/$category');
    if (!catDir.existsSync()) return [];

    final files = catDir
        .listSync()
        .whereType<File>()
        .where((f) =>
            f.path.endsWith('.jpeg') ||
            f.path.endsWith('.jpg') ||
            f.path.endsWith('.png'))
        .toList();

    files.sort((a, b) => a.path.compareTo(b.path));
    return files;
  }

  /// Returns all local asset images grouped by category.
  static Future<Map<String, List<File>>> getAllLocalImages() async {
    final Map<String, List<File>> result = {};
    for (final category in categoryAssets.keys) {
      final files = await getLocalImagesForCategory(category);
      if (files.isNotEmpty) result[category] = files;
    }
    return result;
  }

  /// Reset copy flag (useful for testing / re-copying after update).
  static Future<void> resetCopyFlag() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKey);
  }
}
