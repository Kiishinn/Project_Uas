import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Sign up with email & password
  Future<User?> signUpWithEmailPassword(
    String email,
    String password,
    String name,
    String username,
    String phone,
  ) async {
    try {
      // Create user with email and password
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);
      User? user = userCredential.user;

      if (user != null) {
        // Save additional user data to Firestore
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': email,
          'name': name,
          'username': username,
          'phone': phone,
          'createdAt': Timestamp.now(), // Optionally: add timestamp
        });
        return user;
      }
      return null; // Return null if user is null
    } on FirebaseAuthException catch (e) {
      print("Error during sign up: ${e.message}");
      throw e; // Rethrow error to be handled in the UI
    } catch (e) {
      print("Error during sign up: $e");
      throw e; // Rethrow generic error
    }
  }

  // Sign in with email & password
  Future<User?> signInWithEmailPassword(String email, String password) async {
    try {
      // Sign in with email and password
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      print("Error during sign in: ${e.message}");
      // Handle specific error codes and throw appropriate messages
      if (e.code == 'user-not-found') {
        throw Exception("Email not found.");
      } else if (e.code == 'wrong-password') {
        throw Exception("Incorrect password.");
      }
      throw e; // Rethrow error to be handled in the UI
    } catch (e) {
      print("Error during sign in: $e");
      throw e; // Rethrow generic error
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Get the current user
  Future<User?> getCurrentUser() async {
    try {
      return _auth.currentUser;
    } catch (e) {
      print("Error getting current user: $e");
      return null;
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      print("Error during password reset: ${e.message}");
      throw e; // Rethrow error to be handled in the UI
    }
  }
}
