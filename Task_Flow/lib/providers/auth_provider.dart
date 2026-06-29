import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../services/email_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  String? _userId;
  String? _userEmail;
  bool _isLoading = false;
  String? _errorMessage;

  // Verification states
  bool _isEmailOtpVerified = false;
  String _profileImageUrl = "";
  bool _isInitializing = true;

  StreamSubscription<User?>? _firebaseAuthSubscription;

  // Getters
  bool get isAuthenticated => _userId != null;
  String? get userId => _userId;
  String? get userEmail => _userEmail;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool get isEmailOtpVerified => _isEmailOtpVerified;
  String get profileImageUrl => _profileImageUrl;
  bool get isInitializing => _isInitializing;

  /// Check if the user was registered within the last 10 minutes (new user)
  bool get isNewUser {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.metadata.creationTime == null) return false;
    final difference = DateTime.now().difference(user.metadata.creationTime!);
    return difference.inMinutes <= 10;
  }

  AuthProvider() {
    _initializeAuth();
  }

  @override
  void dispose() {
    _firebaseAuthSubscription?.cancel();
    super.dispose();
  }

  /// Listens to real-time changes in Firebase Auth State
  void _initializeAuth() {
    try {
      _firebaseAuthSubscription = _authService.authStateChanges.listen((
        User? user,
      ) async {
        if (user != null) {
          _userId = user.uid;
          _userEmail = user.email?.toLowerCase();

          // Load OTP and avatar states from Firestore
          await _loadUserProfile(user.uid);
        } else {
          _userId = null;
          _userEmail = null;
          _isEmailOtpVerified = false;
          _profileImageUrl = "";
        }
        _isInitializing = false;
        _isLoading = false;
        notifyListeners();
      });
    } catch (e) {
      _isInitializing = false;
      _isLoading = false;
      _errorMessage = e.toString();
      debugPrint('Firebase Auth initialization error: $e');
      notifyListeners();
    }
  }

  /// Load user details from Firestore profile document
  /// Load user details from Firestore profile document
  Future<void> _loadUserProfile(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (!doc.exists) {
        debugPrint("User document does not exist.");

        _profileImageUrl = "";
        _isEmailOtpVerified = false;

        notifyListeners();
        return;
      }

      final data = doc.data();

      if (data == null) {
        debugPrint("User data is null.");

        _profileImageUrl = "";
        _isEmailOtpVerified = false;

        notifyListeners();
        return;
      }

      debugPrint("========== USER PROFILE ==========");
      debugPrint(data.toString());

      _profileImageUrl = data["profileImageUrl"] ?? "";
      _isEmailOtpVerified = data["emailOtpVerified"] ?? false;

      debugPrint("Profile Image URL:");
      debugPrint(_profileImageUrl);

      notifyListeners();
    } catch (e) {
      debugPrint("Load User Profile Error:");
      debugPrint(e.toString());

      _profileImageUrl = "";
      _isEmailOtpVerified = false;

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

    final normalizedEmail = email.trim().toLowerCase();

    try {
      final userCredential = await _authService
          .signInWithEmailAndPassword(
            email: normalizedEmail,
            password: password,
          )
          .timeout(const Duration(seconds: 15));

      final user = userCredential.user;
      if (user != null) {
        _userId = user.uid;
        _userEmail = user.email?.toLowerCase();
        await _loadUserProfile(user.uid);
      }
      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        _errorMessage = 'User not found. Please register first.';
      } else if (e.code == 'wrong-password') {
        _errorMessage = 'Incorrect password. Please try again.';
      } else if (e.code == 'invalid-credential') {
        _errorMessage = 'Incorrect password or user not found.';
      } else {
        _errorMessage = e.message ?? 'An error occurred during authentication.';
      }
      _setLoading(false);
      return false;
    } on TimeoutException {
      _errorMessage =
          'Login timed out. Please check your internet connection and try again.';
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

    final normalizedEmail = email.trim().toLowerCase();

    try {
      // 1. Create the user credential in Firebase Auth.
      // If the email is already in use, Firebase Auth throws email-already-in-use,
      // which prevents the OTP email from being sent.
      final userCredential = await _authService
          .createUserWithEmailAndPassword(
            email: normalizedEmail,
            password: password,
          )
          .timeout(const Duration(seconds: 15));

      final user = userCredential.user;
      if (user != null) {
        _userId = user.uid;
        _userEmail = user.email?.toLowerCase();
        _isEmailOtpVerified = false;
        _profileImageUrl = "";
        // Generate and store Email verification OTP in Firestore
        await sendEmailOtp(user.uid, user.email!);
      }
      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        _errorMessage = 'Email is already registered. Please login.';
      } else {
        _errorMessage = e.message ?? 'An error occurred during registration.';
      }
      _setLoading(false);
      return false;
    } on TimeoutException {
      _errorMessage =
          'Registration timed out. Please check your internet connection and try again.';
      _setLoading(false);
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      return false;
    }
  }

  /// Generate and store Email verification OTP in Firestore
  Future<void> sendEmailOtp(String uid, String email) async {
    final random = Random();
    final otp = (100000 + random.nextInt(900000)).toString();

    // Store OTP in Firestore under the user's document
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('verification')
        .doc('email_otp')
        .set({
          'code': otp,
          'createdAt': DateTime.now().toUtc().toIso8601String(),
          'expiresAt': DateTime.now()
              .add(const Duration(minutes: 10))
              .toUtc()
              .toIso8601String(),
        });
    debugPrint("Generated Firestore OTP: $otp for $email");

    // Send the actual verification email via EmailService
    await EmailService().sendOtpEmail(toEmail: email.toLowerCase(), otp: otp);
  }

  /// Verify entered 6-digit Email OTP
  Future<bool> verifyEmailOtp(String enteredCode) async {
    if (_userId == null) {
      _errorMessage = "No active user session found.";
      _setLoading(false);
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .collection('verification')
          .doc('email_otp')
          .get();

      if (!doc.exists) {
        _errorMessage = "No verification code sent. Please try resending.";
        _setLoading(false);
        return false;
      }

      final data = doc.data();
      if (data == null) {
        _errorMessage = "Invalid verification data.";
        _setLoading(false);
        return false;
      }

      final code = data['code'];
      final expiresAt = DateTime.parse(data['expiresAt']);

      if (DateTime.now().toUtc().isAfter(expiresAt)) {
        _errorMessage =
            "Verification code has expired. Please request a new one.";
        _setLoading(false);
        return false;
      }

      if (code == enteredCode) {
        _isEmailOtpVerified = true;

        // Save the full user profile document in Firestore now that verification is complete
        await FirebaseFirestore.instance.collection('users').doc(_userId).set({
          'uid': _userId,
          'email': _userEmail ?? "",
          'emailOtpVerified': true,
          'profileImageUrl': _profileImageUrl,
          'createdAt': DateTime.now().toUtc().toIso8601String(),
        }, SetOptions(merge: true));

        _setLoading(false);
        notifyListeners();
        return true;
      } else {
        _errorMessage = "Incorrect OTP code. Please check and try again.";
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      return false;
    }
  }

  /// Update Profile Image URL/Name in local state and Firestore
  Future<bool> updateProfileImage(String imagePath) async {
    if (_userId == null) return false;

    _setLoading(true);
    _clearError();

    try {
      // Preset avatar
      if (imagePath.startsWith("avatar_")) {
        _profileImageUrl = imagePath;

        await FirebaseFirestore.instance.collection("users").doc(_userId).set({
          "profileImageUrl": imagePath,
        }, SetOptions(merge: true));

        _setLoading(false);
        notifyListeners();
        return true;
      }

      _setLoading(false);
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  Future<bool> sendPasswordResetEmail({required String email}) async {
    _setLoading(true);
    _clearError();

    final normalizedEmail = email.trim().toLowerCase();

    try {
      debugPrint("========== FORGOT PASSWORD ==========");
      debugPrint("Sending reset email to: $normalizedEmail");

      // Send Firebase password reset email directly
      await _authService
          .sendPasswordResetEmail(email: normalizedEmail)
          .timeout(const Duration(seconds: 15));

      debugPrint("Password reset email sent successfully.");

      return true;
    } on FirebaseAuthException catch (e) {
      debugPrint("FirebaseAuthException");
      debugPrint("Code: ${e.code}");
      debugPrint("Message: ${e.message}");

      switch (e.code) {
        case 'invalid-email':
          _errorMessage = "Invalid email address.";
          break;

        case 'too-many-requests':
          _errorMessage = "Too many requests. Please try again later.";
          break;

        case 'network-request-failed':
          _errorMessage = "No internet connection. Please check your network.";
          break;

        default:
          _errorMessage = e.message ?? "Failed to send password reset email.";
      }

      return false;
    } on TimeoutException {
      _errorMessage =
          "Request timed out. Please check your internet connection.";
      return false;
    } catch (e) {
      debugPrint("Forgot Password Error: $e");

      _errorMessage = "Something went wrong. Please try again.";
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Sign Out
  Future<void> signOut() async {
    _setLoading(true);
    try {
      await _authService.signOut();
      _userId = null;
      _userEmail = null;
      _isEmailOtpVerified = false;
      _profileImageUrl = "";
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
