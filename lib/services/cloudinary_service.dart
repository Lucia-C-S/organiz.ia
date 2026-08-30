import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CloudinaryService {
  // These are NOT secrets — safe to be in client code for unsigned uploads
  static const String _cloudName = 'YOUR_CLOUD_NAME';
  static const String _uploadPreset = 'YOUR_PRESET_NAME';

  /// Upload an image file to Cloudinary
  /// Returns the secure URL if successful, null otherwise
  static Future<String?> uploadImage(File imageFile) async {
    try {
      final uri = Uri.parse(
        'https://api.cloudinary.com/v1_1/$_cloudName/image/upload',
      );

      final request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = _uploadPreset
        ..fields['folder'] = 'organiz-ia'
        ..files.add(
          await http.MultipartFile.fromPath('file', imageFile.path),
        );

      final response = await request.send();
      final responseData = await response.stream.toBytes();
      final decoded = json.decode(String.fromCharCodes(responseData)) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        final secureUrl = decoded['secure_url'] as String?;
        if (secureUrl != null) {
          return secureUrl;
        }
      } else {
        final error = decoded['error'] as Map<String, dynamic>?;
        throw Exception(error?['message'] ?? 'Upload failed with status ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Cloudinary upload failed: $e');
    }
    return null;
  }

  /// Delete an image from Cloudinary (requires authenticated API call)
  /// For now, deletion via client-side is not implemented
  static Future<bool> deleteImage(String secureUrl) async {
    // Cloudinary requires API key/secret for deletion
    // This should be done server-side, not client-side
    // For now, just return true (deletion can be handled separately)
    return true;
  }
}