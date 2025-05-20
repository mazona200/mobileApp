import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class UserService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  
  static const String _usersCollection = 'users';
  
  // Creates a new user document in Firestore with role information
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
    });
  }
  
  // Gets user role from Firestore
  static Future<String?> getUserRole(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection(_usersCollection).doc(uid).get();
      if (doc.exists) {
        return doc.get('role') as String?;
      }
      return null;
    } catch (e) {
      print('Error getting user role: $e');
      return null;
    }
  }
  
  // Gets current user's role
  static Future<String?> getCurrentUserRole() async {
    User? user = _auth.currentUser;
    if (user != null) {
      return await getUserRole(user.uid);
    }
    return null;
  }
  
  // Check if the user has a specific role
  static Future<bool> hasRole(String role) async {
    String? userRole = await getCurrentUserRole();
    return userRole == role;
  }
  
  // Get current user data
  static Future<Map<String, dynamic>?> getCurrentUserData() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot doc = await _firestore.collection(_usersCollection).doc(user.uid).get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>?;
      }
    }
    return null;
  }
  
  // ------ Single-role login persistence methods ------
  
  // Check if any user is currently logged in
  static Future<bool> isAnyUserLoggedIn() async {
    final currentRole = await _secureStorage.read(key: 'current_role');
    return currentRole != null && currentRole.isNotEmpty;
  }
  
  // Save login state for the current role (clearing any other roles first)
  static Future<void> saveLoginState(String role, String uid, String email) async {
    // Clear any existing login states first
    await logoutFromAllRoles();
    
    // Then save the new login state
    await _secureStorage.write(key: 'current_role', value: role);
    await _secureStorage.write(key: 'current_uid', value: uid);
    await _secureStorage.write(key: 'current_email', value: email);
  }
  
  // Clear all login states
  static Future<void> logoutFromAllRoles() async {
    await _auth.signOut();
    await _secureStorage.delete(key: 'current_role');
    await _secureStorage.delete(key: 'current_uid');
    await _secureStorage.delete(key: 'current_email');
  }
  
  // For backward compatibility - redirects to logoutFromAllRoles
  static Future<void> clearLoginState() async {
    await logoutFromAllRoles();
  }
  
  // Check if a specific role is logged in
  static Future<bool> isRoleLoggedIn(String role) async {
    final currentRole = await _secureStorage.read(key: 'current_role');
    return currentRole == role;
  }
  
  // Get all logged-in roles (will only ever return a list with at most one role)
  static Future<List<String>> getLoggedInRoles() async {
    List<String> roles = [];
    
    final currentRole = await _secureStorage.read(key: 'current_role');
    if (currentRole != null && currentRole.isNotEmpty) {
      roles.add(currentRole);
    }
    
    return roles;
  }
  
  // Get auth credentials for the current role
  static Future<Map<String, String>?> getRoleCredentials(String role) async {
    final currentRole = await _secureStorage.read(key: 'current_role');
    
    // Only return credentials if the requested role matches the current role
    if (currentRole == role) {
      final uid = await _secureStorage.read(key: 'current_uid');
      final email = await _secureStorage.read(key: 'current_email');
      
      if (uid != null && email != null) {
        return {
          'uid': uid,
          'email': email,
        };
      }
    }
    
    return null;
  }
  
  // Get current logged in role
  static Future<String?> getCurrentLoggedInRole() async {
    return await _secureStorage.read(key: 'current_role');
  }
} 