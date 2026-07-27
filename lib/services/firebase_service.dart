import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../firebase_options.dart';
import '../models/pantry_item.dart';

class FirebaseService {
  FirebaseService();

  bool _initialized = false;
  User? _currentUser;

  bool get isSignedIn => _currentUser != null;
  String get currentUserId => _currentUser?.uid ?? 'anonymous';

  Future<void> initialize() async {
    if (_initialized) return;
    try {
      if (Firebase.apps.isEmpty) {
        if (!DefaultFirebaseOptions.isConfigured) {
          throw StateError('Firebase is not configured.');
        }
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      _initialized = true;
      _currentUser = FirebaseAuth.instance.currentUser;
    } catch (_) {
      _initialized = false;
      _currentUser = null;
      rethrow;
    }
  }

  Future<bool> signInAnonymously() async {
    if (!DefaultFirebaseOptions.isConfigured) {
      return false;
    }
    try {
      await initialize();
    } catch (_) {
      return false;
    }
    if (FirebaseAuth.instance.currentUser != null) {
      _currentUser = FirebaseAuth.instance.currentUser;
      return true;
    }
    final result = await FirebaseAuth.instance.signInAnonymously();
    _currentUser = result.user;
    return _currentUser != null;
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    _currentUser = null;
  }

  CollectionReference<Map<String, dynamic>> get _pantryCollection {
    final uid = currentUserId;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('pantryItems');
  }

  Future<void> savePantryItem(PantryItem item) async {
    final documentId = item.id;
    await _pantryCollection.doc(documentId).set(item.toFirestore());
  }

  Future<void> deletePantryItem(String itemId) async {
    await _pantryCollection.doc(itemId).delete();
  }

  Stream<List<PantryItem>> pantryItemsStream() {
    return _pantryCollection.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => PantryItem.fromFirestore(doc.data(), doc.id))
          .toList();
    });
  }
}
