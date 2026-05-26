import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

/// Wraps Firebase Authentication for email / password sign-in.
class AuthService {
  AuthService._();
  static final instance = AuthService._();

  final _auth = FirebaseAuth.instance;

  /// Stream of auth-state changes (null = signed-out).
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Currently signed-in Firebase user, or null.
  User? get currentUser => _auth.currentUser;

  /// Sign in with email + password.
  /// Returns the [UserCredential] on success.
  /// Throws [FirebaseAuthException] on failure.
  Future<UserCredential> signIn(String email, String password) {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Create a new user with email + password without signing out the current admin.
  Future<UserCredential> registerNewUserByAdmin(
      String email, String password) async {
    const secondaryAppName = 'SecondaryRegistration';
    FirebaseApp? secondaryApp;
    try {
      try {
        await Firebase.app(secondaryAppName).delete();
      } on FirebaseException {
        // No stale secondary app exists.
      }

      secondaryApp = await Firebase.initializeApp(
        name: secondaryAppName,
        options: Firebase.app().options,
      );

      return FirebaseAuth.instanceFor(app: secondaryApp)
          .createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } finally {
      await secondaryApp?.delete();
    }
  }

  /// Create a new user with email + password (standard).
  Future<UserCredential> createUser(String email, String password) {
    return _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Sign out.
  Future<void> signOut() => _auth.signOut();
}
