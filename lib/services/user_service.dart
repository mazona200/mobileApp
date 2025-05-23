import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class UserService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  static const String _usersCollection = 'users';

  // Creates or updates user document in Firestore with role info and caches role
  static Future<void> createUser({
    required String uid,
    required String email,
    required String role,
    String? name,
    String? phone,
    String? nationalId,
    String? dateOfBirth,
    String? profession,
    String? gender,
    String? hometown,
  }) async {
    await _firestore.collection(_usersCollection).doc(uid).set({
      'email': email,
      'role': role,
      'name': name ?? '',
      'phone': phone ?? '',
      'nationalId': nationalId ?? '',
      'dateOfBirth': dateOfBirth ?? '',
      'profession': profession ?? '',
      'gender': gender ?? '',
      'hometown': hometown ?? '',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Cache role locally
    await _secureStorage.write(key: 'user_role', value: role);
    await _secureStorage.write(key: 'current_role', value: role);
  }

  // Gets user role from Firestore
  static Future<String?> getUserRole(String uid) async {
    try {
      final doc = await _firestore.collection(_usersCollection).doc(uid).get();
      if (doc.exists) {
        return doc.get('role') as String?;
      }
      return null;
    } catch (e) {
      print('Error getting user role: $e');
      return null;
    }
  }

  // Gets current user's role (refreshes FirebaseAuth and checks Firestore)
  static Future<String?> getCurrentUserRole() async {
    try {
      await _auth.currentUser?.reload();
    } catch (_) {}

    final user = _auth.currentUser;
    if (user == null) return null;

    final role = await getUserRole(user.uid);
    if (role != null) {
      await _secureStorage.write(key: 'user_role', value: role);
      await _secureStorage.write(key: 'current_role', value: role);
    }
    return role;
  }

  // Get current logged-in role from secure storage
  static Future<String?> getCurrentLoggedInRole() async {
    return await _secureStorage.read(key: 'current_role');
  }

  // Check if any user is currently logged in
  static Future<bool> isAnyUserLoggedIn() async {
    final currentRole = await _secureStorage.read(key: 'current_role');
    return currentRole != null && currentRole.isNotEmpty;
  }

  // Save login state (clears previous login states)
  static Future<void> saveLoginState(String role, String uid, String email) async {
    await logoutFromAllRoles();

    await _secureStorage.write(key: 'user_role', value: role);
    await _secureStorage.write(key: 'current_role', value: role);
    await _secureStorage.write(key: 'current_uid', value: uid);
    await _secureStorage.write(key: 'current_email', value: email);
  }

  // Clear all login states and sign out
  static Future<void> logoutFromAllRoles() async {
    await _auth.signOut();
    await _secureStorage.delete(key: 'user_role');
    await _secureStorage.delete(key: 'current_role');
    await _secureStorage.delete(key: 'current_uid');
    await _secureStorage.delete(key: 'current_email');
  }

  // Get current user data from Firestore
  static Future<Map<String, dynamic>?> getCurrentUserData() async {
    final user = _auth.currentUser;
    if (user != null) {
      final doc = await _firestore.collection(_usersCollection).doc(user.uid).get();
      if (doc.exists) return doc.data() as Map<String, dynamic>?;
    }
    return null;
  }

  // Get all logged-in roles (only one role due to your app logic)
  static Future<List<String>> getLoggedInRoles() async {
    final currentRole = await _secureStorage.read(key: 'current_role');
    if (currentRole != null && currentRole.isNotEmpty) {
      return [currentRole];
    }
    return [];
  }
}