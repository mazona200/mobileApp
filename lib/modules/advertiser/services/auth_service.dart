import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/advertiser.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Check if user is verified
      final advertiserDoc = await _firestore
          .collection('advertisers')
          .doc(userCredential.user!.uid)
          .get();

      if (!advertiserDoc.exists) {
        throw Exception('User not found in advertisers collection');
      }

      final advertiser = Advertiser.fromFirestore(advertiserDoc);
      if (!advertiser.isVerified) {
        await _auth.signOut();
        throw Exception('Your account is not verified yet');
      }

      return userCredential;
    } catch (e) {
      throw Exception('Failed to sign in: ${e.toString()}');
    }
  }

  // Register with email and password
  Future<UserCredential> registerWithEmailAndPassword(
      String email, String password, String businessName) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create advertiser document
      final advertiser = Advertiser(
        id: userCredential.user!.uid,
        email: email,
        businessName: businessName,
        isVerified: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection('advertisers')
          .doc(userCredential.user!.uid)
          .set(advertiser.toMap());

      return userCredential;
    } catch (e) {
      throw Exception('Failed to register: ${e.toString()}');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw Exception('Failed to sign out: ${e.toString()}');
    }
  }

  // Get current advertiser
  Future<Advertiser?> getCurrentAdvertiser() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final doc = await _firestore.collection('advertisers').doc(user.uid).get();
      if (!doc.exists) return null;

      return Advertiser.fromFirestore(doc);
    } catch (e) {
      throw Exception('Failed to get current advertiser: ${e.toString()}');
    }
  }

  // Update advertiser profile
  Future<void> updateAdvertiserProfile({
    String? businessName,
    String? phoneNumber,
    String? businessAddress,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No user logged in');

      final updates = <String, dynamic>{
        'updatedAt': Timestamp.now(),
      };

      if (businessName != null) updates['businessName'] = businessName;
      if (phoneNumber != null) updates['phoneNumber'] = phoneNumber;
      if (businessAddress != null) updates['businessAddress'] = businessAddress;

      await _firestore.collection('advertisers').doc(user.uid).update(updates);
    } catch (e) {
      throw Exception('Failed to update profile: ${e.toString()}');
    }
  }
} 