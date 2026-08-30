import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../services/firebase_storage_service.dart';

class StorageProvider extends ChangeNotifier {
  final FirebaseStorageService _storageService = FirebaseStorageService();

  bool _isLoading = false;
  String? _errorMessage;
  Map<String, String> _photoUrls = {}; // Cache for download URLs

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<String, String> get photoUrls => _photoUrls;

  /// Upload a product photo
  /// [fileOrBytes] can be File (mobile) or Uint8List (web)
  /// [productId] is the product identifier
  /// [photoIndex] is the index of the photo (0, 1, 2, etc.)
  Future<String?> uploadProductPhoto({
    required dynamic fileOrBytes,
    required String productId,
    required int photoIndex,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final downloadUrl = await _storageService.uploadItemPhoto(
        fileOrBytes,
        '$productId-photo-$photoIndex',
      );

      _photoUrls['$productId-$photoIndex'] = downloadUrl;
      _isLoading = false;
      notifyListeners();
      return downloadUrl;
    } catch (e) {
      _errorMessage = 'Failed to upload photo: $e';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Get download URL for a product photo
  Future<String?> getProductPhotoUrl({
    required String productId,
    required int photoIndex,
  }) async {
    final cacheKey = '$productId-$photoIndex';
    
    // Return from cache if available
    if (_photoUrls.containsKey(cacheKey)) {
      return _photoUrls[cacheKey];
    }

    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('item_photos')
          .child('$productId-photo-$photoIndex.jpg');
      
      final downloadUrl = await ref.getDownloadURL();
      _photoUrls[cacheKey] = downloadUrl;
      notifyListeners();
      return downloadUrl;
    } catch (e) {
      // Photo doesn't exist
      return null;
    }
  }

  /// Delete a product photo
  Future<bool> deleteProductPhoto({
    required String productId,
    required int photoIndex,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('item_photos')
          .child('$productId-photo-$photoIndex.jpg');
      
      await ref.delete();
      
      final cacheKey = '$productId-$photoIndex';
      _photoUrls.remove(cacheKey);
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to delete photo: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Get all photos for a product
  Future<List<String>> getProductPhotos({required String productId}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('item_photos');
      
      final listResult = await ref.list();
      
      // Filter photos for this product
      final productPhotos = <String>[];
      for (var item in listResult.items) {
        if (item.name.startsWith('$productId-photo-')) {
          try {
            final url = await item.getDownloadURL();
            productPhotos.add(url);
          } catch (_) {
            // Skip if URL retrieval fails
          }
        }
      }

      _isLoading = false;
      notifyListeners();
      return productPhotos;
    } catch (e) {
      _errorMessage = 'Failed to fetch product photos: $e';
      _isLoading = false;
      notifyListeners();
      return [];
    }
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Clear all cached URLs (useful for logout)
  void clearCache() {
    _photoUrls.clear();
    notifyListeners();
  }
}
