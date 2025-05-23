import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Check if user is authenticated and has the correct role
  static Future<bool> verifyRole(String requiredRole) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final doc = await _firestore.collection('users').doc(user.uid).get();
      final userRole = doc.data()?['role'] as String?;
      
      return userRole == requiredRole;
    } catch (e) {
      print('Error verifying role: $e');
      return false;
    }
  }

  // Stream of authentication state changes
  static Stream<User?> get authStateChanges => _auth.authStateChanges();
}