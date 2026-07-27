import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';

class FirebaseStorageService {
  FirebaseStorageService();

  FirebaseStorage get _storage => FirebaseStorage.instance;

  /// Accepts either a dart:io File on mobile, or a Uint8List on web.
  Future<String> uploadItemPhoto(dynamic fileOrBytes, String itemId) async {
    final ref = _storage.ref().child('item_photos').child('$itemId.jpg');
    try {
      if (kIsWeb) {
        if (fileOrBytes is Uint8List) {
          final uploadTask = await ref.putData(fileOrBytes);
          return await uploadTask.ref.getDownloadURL();
        } else {
          throw StateError('On web, uploadItemPhoto expects Uint8List');
        }
      } else {
        // assume a File-like object with path; avoid importing dart:io to keep web compatibility
        // Firebase Storage supports putFile for dart:io File; if caller provides bytes use putData
        if (fileOrBytes is Uint8List) {
          final uploadTask = await ref.putData(fileOrBytes);
          return await uploadTask.ref.getDownloadURL();
        }
        // Assume fileOrBytes is a dart:io File or similar — call putFile and await the UploadTask
        final uploadTask = ref.putFile(fileOrBytes);
        final snapshot = await uploadTask;
        return await snapshot.ref.getDownloadURL();
      }
    } catch (e) {
      rethrow;
    }
  }
}
