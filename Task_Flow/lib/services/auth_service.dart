import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Stream of user authentication state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Gets the currently authenticated user
  User? get currentUser => _auth.currentUser;

  /// Signs in the user with email and password
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Registers a new user with email and password
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Sends a password recovery link to the user's email
  Future<void> sendPasswordResetEmail({required String email}) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  /// Signs out from Firebase
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
