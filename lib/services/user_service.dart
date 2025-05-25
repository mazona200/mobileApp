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
<<<<<<< Updated upstream
      return await getUserRole(user.uid);
=======
      final doc = await _firestore.collection(_usersCollection).doc(user.uid).get();
      if (doc.exists) return doc.data();
>>>>>>> Stashed changes
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
  
  // ------ Multi-role login persistence methods ------
  
  // Save login state for a specific role
  static Future<void> saveLoginState(String role, String uid, String email) async {
    await _secureStorage.write(key: 'login_role_$role', value: 'true');
    await _secureStorage.write(key: 'login_uid_$role', value: uid);
    await _secureStorage.write(key: 'login_email_$role', value: email);
  }
  
  // Clear login state for a specific role
  static Future<void> clearLoginState(String role) async {
    await _secureStorage.delete(key: 'login_role_$role');
    await _secureStorage.delete(key: 'login_uid_$role');
    await _secureStorage.delete(key: 'login_email_$role');
  }
  
  // Check if a specific role is logged in
  static Future<bool> isRoleLoggedIn(String role) async {
    final value = await _secureStorage.read(key: 'login_role_$role');
    return value == 'true';
  }
  
  // Get all logged-in roles
  static Future<List<String>> getLoggedInRoles() async {
    List<String> roles = [];
    
    // Check each possible role
    for (String role in ['citizen', 'government', 'advertiser']) {
      if (await isRoleLoggedIn(role)) {
        roles.add(role);
      }
    }
    
    return roles;
  }
  
  // Log out from all roles
  static Future<void> logoutFromAllRoles() async {
    await _auth.signOut();
    await clearLoginState('citizen');
    await clearLoginState('government');
    await clearLoginState('advertiser');
  }
  
  // Get auth credentials for a specific role
  static Future<Map<String, String>?> getRoleCredentials(String role) async {
    final uid = await _secureStorage.read(key: 'login_uid_$role');
    final email = await _secureStorage.read(key: 'login_email_$role');
    
    if (uid != null && email != null) {
      return {
        'uid': uid,
        'email': email,
      };
    }
    
    return null;
  }
} 