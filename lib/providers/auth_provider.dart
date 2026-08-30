import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthenticationService _authService = AuthenticationService();

  User? _currentFirebaseUser;
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  User? get currentFirebaseUser => _currentFirebaseUser;
  UserModel? get currentUser => _currentUser;
  bool get isSignedIn => _currentFirebaseUser != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  AuthProvider() {
    _initializeAuth();
  }

  /// Initialize authentication state listener
  void _initializeAuth() {
    _authService.authStateChanges.listen((firebaseUser) {
      _currentFirebaseUser = firebaseUser;
      if (firebaseUser != null) {
        _loadUserModel(firebaseUser.uid);
      } else {
        _currentUser = null;
      }
      notifyListeners();
    });
  }

  /// Load user model from Firestore
  Future<void> _loadUserModel(String uid) async {
    try {
      _currentUser = await _authService.getUserModel(uid);
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load user data: $e';
      notifyListeners();
    }
  }

  /// Sign up with email and password
  Future<bool> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.signUp(
        email: email,
        password: password,
        displayName: displayName,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Sign in with email and password
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.signIn(
        email: email,
        password: password,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    await _authService.signOut();
    _currentUser = null;
    notifyListeners();
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
