import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

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

  /// Signs in the user with Google
  Future<UserCredential> signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      throw FirebaseAuthException(
        code: 'ERROR_ABORTED_BY_USER',
        message: 'Sign in aborted by user',
      );
    }
    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    final AuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    return await _auth.signInWithCredential(credential);
  }

  /// Signs in the user with Facebook
  Future<UserCredential> signInWithFacebook() async {
    final LoginResult result = await FacebookAuth.instance.login();
    if (result.status == LoginStatus.success) {
      final OAuthCredential credential = FacebookAuthProvider.credential(
        result.accessToken!.token,
      );
      return await _auth.signInWithCredential(credential);
    } else if (result.status == LoginStatus.cancelled) {
      throw FirebaseAuthException(
        code: 'ERROR_ABORTED_BY_USER',
        message: 'Sign in aborted by user',
      );
    } else {
      throw FirebaseAuthException(
        code: 'ERROR_FACEBOOK_LOGIN_FAILED',
        message: result.message ?? 'Facebook sign in failed',
      );
    }
  }

  /// Exposes phone number verification
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required PhoneVerificationCompleted verificationCompleted,
    required PhoneVerificationFailed verificationFailed,
    required PhoneCodeSent codeSent,
    required PhoneCodeAutoRetrievalTimeout codeAutoRetrievalTimeout,
    int? forceResendingToken,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: verificationCompleted,
      verificationFailed: verificationFailed,
      codeSent: codeSent,
      codeAutoRetrievalTimeout: codeAutoRetrievalTimeout,
      forceResendingToken: forceResendingToken,
    );
  }

  /// Links a phone credential to the current logged in user
  Future<UserCredential> linkPhoneCredential(AuthCredential credential) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'No authenticated user found to link.',
      );
    }
    return await user.linkWithCredential(credential);
  }

  /// Sends a password recovery link to the user's email
  Future<void> sendPasswordResetEmail({required String email}) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  /// Logs the current user out of the application
  Future<void> signOut() async {
    await _googleSignIn.signOut().catchError((_) => null);
    await FacebookAuth.instance.logOut().catchError((_) => null);
    await _auth.signOut();
  }
}
