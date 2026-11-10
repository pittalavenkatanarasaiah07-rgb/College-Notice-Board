
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  // Email validation
  bool isValidEmail(String email) {
    return RegExp(
      r'^[\w\.-]+@[\w\.-]+\.\w+$',
    ).hasMatch(email.trim());
  }

  // Strong password validation
  bool isStrongPassword(String password) {
    return password.length >= 8 &&
        RegExp(r'[A-Z]').hasMatch(password) &&
        RegExp(r'[a-z]').hasMatch(password) &&
        RegExp(r'[0-9]').hasMatch(password) &&
        RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password);
  }

  // Student registration
  Future<String?> registerStudent({
    required String name,
    required String rollNumber,
    required String email,
    required String password,
  }) async {
    try {
      if (!isValidEmail(email)) {
        return 'Please enter a valid email';
      }

      if (!isStrongPassword(password)) {
        return 'Password must contain at least 8 characters, uppercase, lowercase, number and special character';
      }

      final result = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = result.user;

      if (user == null) {
        return 'Registration failed. Please try again';
      }

      await _firestore.collection('users').doc(user.uid).set({
        'name': name.trim(),
        'rollNumber': rollNumber.trim(),
        'email': email.trim(),
        'role': 'student',
        'createdAt': FieldValue.serverTimestamp(),
      });

      await user.sendEmailVerification();

      await _auth.signOut();

      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        return 'This email is already registered';
      }
      if (e.code == 'weak-password') {
        return 'Please choose a stronger password';
      }
      if (e.code == 'invalid-email') {
        return 'Invalid email address';
      }
      return e.message ?? 'Registration failed';
    } catch (e) {
      return 'Something went wrong: $e';
    }
  }

  // Login for Student and Admin
  Future<String?> login({
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      if (!isValidEmail(email)) {
        return 'Please enter a valid email';
      }

      final result = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = result.user;

      if (user == null) {
        await _auth.signOut();
        return 'User not found';
      }

      await user.reload();

      final refreshedUser = _auth.currentUser;

      if (refreshedUser == null) {
        await _auth.signOut();
        return 'Please login again';
      }

      // Send verification email if not verified
      if (!refreshedUser.emailVerified) {
        try {
          await refreshedUser.sendEmailVerification();

          await _auth.signOut();

          return 'Verification email sent. Please check your inbox and spam folder';
        } on FirebaseAuthException catch (e) {
          await _auth.signOut();
          return e.message ?? 'Could not send verification email';
        }
      }

      // Check user role in Firestore
      final userDoc = await _firestore
          .collection('users')
          .doc(refreshedUser.uid)
          .get();

      if (!userDoc.exists ||
          userDoc.data()?['role'] != role.toLowerCase()) {
        await _auth.signOut();
        return 'Invalid account or role';
      }

      return null;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          return 'Incorrect email or password';

        case 'invalid-email':
          return 'Invalid email address';

        case 'user-disabled':
          return 'This account has been disabled';

        case 'too-many-requests':
          return 'Too many attempts. Please try again later';

        default:
          return e.message ?? 'Login failed';
      }
    } catch (e) {
      await _auth.signOut();
      return 'Something went wrong: $e';
    }
  }

  // Resend verification email for currently signed-in user
  Future<String?> resendVerificationEmail() async {
    try {
      final user = _auth.currentUser;

      if (user == null) {
        return 'Please login again to request verification email';
      }

      await user.reload();

      final refreshedUser = _auth.currentUser;

      if (refreshedUser == null) {
        return 'Please login again';
      }

      if (refreshedUser.emailVerified) {
        return 'Your email is already verified';
      }

      await refreshedUser.sendEmailVerification();

      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'Could not send verification email';
    } catch (e) {
      return 'Something went wrong: $e';
    }
  }

  // Logout
  Future<void> logout() async {
    await _auth.signOut();
  }
}
