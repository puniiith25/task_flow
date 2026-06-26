import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  
  String? _userId;
  String? _userEmail;
  bool _isLoading = false;
  String? _errorMessage;
  
  StreamSubscription<User?>? _firebaseAuthSubscription;

  // Getters
  bool get isAuthenticated => _userId != null;
  String? get userId => _userId;
  String? get userEmail => _userEmail;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  AuthProvider() {
    _initializeAuth();
  }

  @override
  void dispose() {
    _firebaseAuthSubscription?.cancel();
    super.dispose();
  }

  /// Initialize Auth state, listening to Firebase Auth changes
  Future<void> _initializeAuth() async {
    try {
      _isLoading = true;
      // Listen to real Firebase Auth changes
      _firebaseAuthSubscription = _authService.authStateChanges.listen((User? user) {
        if (user != null) {
          _userId = user.uid;
          _userEmail = user.email;
        } else {
          _userId = null;
          _userEmail = null;
        }
        _isLoading = false;
        notifyListeners();
      });
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      debugPrint('Firebase Auth initialization error: $e');
      notifyListeners();
    }
  }

  /// Sign in with Email and Password
  Future<bool> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      await _authService.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      // State is updated automatically by authStateChanges subscription
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = e.message ?? 'An error occurred during authentication.';
      _setLoading(false);
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      return false;
    }
  }

  /// Register/Create a new user with Email and Password
  Future<bool> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      await _authService.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      // State is updated automatically by authStateChanges subscription
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = e.message ?? 'An error occurred during registration.';
      _setLoading(false);
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      return false;
    }
  }

  /// Send Password Reset Link
  Future<bool> sendPasswordResetEmail({required String email}) async {
    _setLoading(true);
    _clearError();

    try {
      await _authService.sendPasswordResetEmail(email: email.trim());
      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = e.message ?? 'An error occurred while resetting password.';
      _setLoading(false);
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      return false;
    }
  }

  /// Sign Out
  Future<void> signOut() async {
    _setLoading(true);
    try {
      await _authService.signOut();
      _userId = null;
      _userEmail = null;
      notifyListeners();
    } catch (e) {
      debugPrint('Error signing out: $e');
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }
}
