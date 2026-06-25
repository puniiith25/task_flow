import '../services/auth_service.dart';

abstract class AuthRepository {
  Stream<MockUser?> get authStateChanges;
  MockUser? get currentUser;
  Future<MockUser?> signIn(String email, String password);
  Future<MockUser?> signUp(String email, String password);
  Future<void> sendPasswordReset(String email);
  Future<void> signOut();
}

class AuthRepositoryImpl implements AuthRepository {
  final AuthService _authService;

  AuthRepositoryImpl(this._authService);

  @override
  Stream<MockUser?> get authStateChanges => _authService.authStateChanges;

  @override
  MockUser? get currentUser => _authService.currentUser;

  @override
  Future<MockUser?> signIn(String email, String password) async {
    try {
      return await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      throw AuthException(e.toString().replaceAll("Exception: ", ""));
    }
  }

  @override
  Future<MockUser?> signUp(String email, String password) async {
    try {
      return await _authService.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      throw AuthException('Failed to create account. Please try again.');
    }
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    try {
      await _authService.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw const AuthException('An unexpected error occurred during password reset.');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _authService.signOut();
    } catch (e) {
      throw const AuthException('Failed to log out.');
    }
  }
}

class AuthException implements Exception {
  final String message;
  const AuthException(this.message);

  @override
  String toString() => message;
}
