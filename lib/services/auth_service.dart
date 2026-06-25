import 'dart:async';

class MockUser {
  final String uid;
  final String email;

  MockUser({required this.uid, required this.email});
}

class AuthService {
  final StreamController<MockUser?> _authStateController = StreamController<MockUser?>.broadcast();
  MockUser? _currentUser;

  AuthService() {
    _authStateController.add(null);
  }

  /// Stream of user authentication state changes
  Stream<MockUser?> get authStateChanges => _authStateController.stream;

  /// Gets the currently authenticated user
  MockUser? get currentUser => _currentUser;

  /// Signs in the user with email and password
  Future<MockUser> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));
    if (email == "test@test.com" && password == "password") {
      _currentUser = MockUser(uid: "mock-uid-123", email: email);
      _authStateController.add(_currentUser);
      return _currentUser!;
    } else {
      throw Exception("Incorrect email or password.");
    }
  }

  /// Registers a new user with email and password
  Future<MockUser> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));
    _currentUser = MockUser(
      uid: "mock-uid-${DateTime.now().millisecondsSinceEpoch}",
      email: email,
    );
    _authStateController.add(_currentUser);
    return _currentUser!;
  }

  /// Sends a password recovery link to the user's email
  Future<void> sendPasswordResetEmail({required String email}) async {
    await Future.delayed(const Duration(milliseconds: 400));
  }

  /// Logs the current user out of the application
  Future<void> signOut() async {
    _currentUser = null;
    _authStateController.add(null);
  }
}
