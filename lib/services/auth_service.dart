import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/material.dart';

/// Unified authentication service that handles all auth operations
/// Replaces the scattered auth logic across multiple files
class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  
  // Storage keys
  static const String _userRoleKey = 'user_role';
  static const String _currentRoleKey = 'current_role';
  static const String _currentUidKey = 'current_uid';
  static const String _currentEmailKey = 'current_email';
  static const String _savedEmailKey = 'saved_email';
  static const String _savedPasswordKey = 'saved_password';
  static const String _rememberMeKey = 'remember_me';
  
  // Valid roles in the system
  static const List<String> validRoles = ['citizen', 'government', 'advertiser'];
  
  /// Check if user is authenticated
  static bool get isAuthenticated => _auth.currentUser != null;
  
  /// Get current Firebase user
  static User? get currentUser => _auth.currentUser;
  
  /// Stream of authentication state changes
  static Stream<User?> get authStateChanges => _auth.authStateChanges();
  
  /// Sign in with email and password for a specific role
  static Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
    required String role,
  }) async {
    if (!validRoles.contains(role)) {
      throw Exception('Invalid role: $role');
    }
    
    final userCredential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
    
    // Verify user exists in Firestore and has correct role
    await _verifyUserRole(userCredential.user!.uid, role, email.trim());
    
    // Save login state
    await _saveLoginState(role, userCredential.user!.uid, 
        userCredential.user!.email ?? email.trim());
    
    return userCredential;
  }
  
  /// Create a new user account
  static Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
    required String role,
    Map<String, dynamic>? additionalData,
  }) async {
    if (!validRoles.contains(role)) {
      throw Exception('Invalid role: $role');
    }
    
    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
    
    // Create user document in Firestore
    await _createUserDocument(
      uid: userCredential.user!.uid,
      email: email.trim(),
      role: role,
      additionalData: additionalData,
    );
    
    // Save login state
    await _saveLoginState(role, userCredential.user!.uid, 
        userCredential.user!.email ?? email.trim());
    
    return userCredential;
  }
  
  /// Verify user role matches required role
  static Future<void> _verifyUserRole(String uid, String expectedRole, String email) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    
    if (!doc.exists) {
      // Create minimal user document if it doesn't exist
      await _firestore.collection('users').doc(uid).set({
        'email': email,
        'role': expectedRole,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } else {
      final storedRole = doc.data()?['role'] as String?;
      if (storedRole != expectedRole) {
        throw Exception('You are registered as a $storedRole, not as a $expectedRole');
      }
    }
  }
  
  /// Create user document in Firestore
  static Future<void> _createUserDocument({
    required String uid,
    required String email,
    required String role,
    Map<String, dynamic>? additionalData,
  }) async {
    final userData = {
      'email': email,
      'role': role,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      ...?additionalData,
    };
    
    await _firestore.collection('users').doc(uid).set(userData);
  }
  
  /// Save login state to secure storage (single role only)
  static Future<void> _saveLoginState(String role, String uid, String email) async {
    // Clear any existing login states first
    await _clearLoginState();
    
    // Save new login state
    await _secureStorage.write(key: _userRoleKey, value: role);
    await _secureStorage.write(key: _currentRoleKey, value: role);
    await _secureStorage.write(key: _currentUidKey, value: uid);
    await _secureStorage.write(key: _currentEmailKey, value: email);
  }
  
  /// Clear all login states and sign out
  static Future<void> signOut() async {
    await _auth.signOut();
    await _clearLoginState();
  }
  
  /// Clear stored login state
  static Future<void> _clearLoginState() async {
    await _secureStorage.delete(key: _userRoleKey);
    await _secureStorage.delete(key: _currentRoleKey);
    await _secureStorage.delete(key: _currentUidKey);
    await _secureStorage.delete(key: _currentEmailKey);
  }
  
  /// Get current user's role from Firestore (with cache update)
  static Future<String?> getCurrentUserRole() async {
    if (!isAuthenticated) return null;
    
    try {
      // Refresh current user data
      await _auth.currentUser?.reload();
      
      final doc = await _firestore.collection('users').doc(_auth.currentUser!.uid).get();
      final role = doc.data()?['role'] as String?;
      
      if (role != null) {
        // Update cache
        await _secureStorage.write(key: _userRoleKey, value: role);
        await _secureStorage.write(key: _currentRoleKey, value: role);
      }
      
      return role;
    } catch (e) {
      debugPrint('Error getting user role: $e');
      return null;
    }
  }
  
  /// Get cached current role from secure storage
  static Future<String?> getCachedCurrentRole() async {
    return await _secureStorage.read(key: _currentRoleKey);
  }
  
  /// Check if any user is currently logged in
  static Future<bool> isAnyUserLoggedIn() async {
    final currentRole = await _secureStorage.read(key: _currentRoleKey);
    return currentRole != null && currentRole.isNotEmpty && isAuthenticated;
  }
  
  /// Get current user data from Firestore
  static Future<Map<String, dynamic>?> getCurrentUserData() async {
    if (!isAuthenticated) return null;
    
    try {
      final doc = await _firestore.collection('users').doc(_auth.currentUser!.uid).get();
      return doc.exists ? doc.data() : null;
    } catch (e) {
      debugPrint('Error getting user data: $e');
      return null;
    }
  }
  
  /// Verify user has specific role
  static Future<bool> hasRole(String requiredRole) async {
    if (requiredRole == 'all_roles') return await isAnyUserLoggedIn();
    
    final currentRole = await getCurrentUserRole();
    return currentRole == requiredRole;
  }
  
  /// Save login credentials for remember me functionality
  static Future<void> saveCredentials(String email, String password, bool remember) async {
    if (remember) {
      await _secureStorage.write(key: _savedEmailKey, value: email);
      await _secureStorage.write(key: _savedPasswordKey, value: password);
      await _secureStorage.write(key: _rememberMeKey, value: 'true');
    } else {
      await _secureStorage.delete(key: _savedEmailKey);
      await _secureStorage.delete(key: _savedPasswordKey);
      await _secureStorage.write(key: _rememberMeKey, value: 'false');
    }
  }
  
  /// Load saved credentials
  static Future<Map<String, String?>> loadSavedCredentials() async {
    final savedEmail = await _secureStorage.read(key: _savedEmailKey);
    final savedPassword = await _secureStorage.read(key: _savedPasswordKey);
    final rememberMe = (await _secureStorage.read(key: _rememberMeKey)) == 'true';
    
    return {
      'email': rememberMe ? savedEmail : null,
      'password': rememberMe ? savedPassword : null,
      'remember': rememberMe.toString(),
    };
  }
  
  /// Send password reset email
  static Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }
  
  /// Initialize auth state listener for automatic role caching
  static void initializeAuthStateListener() {
    _auth.authStateChanges().listen((user) async {
      if (user == null) {
        // User signed out - clear cached roles after a short delay to avoid false signouts
        await Future.delayed(const Duration(seconds: 2));
        if (_auth.currentUser == null) {
          await _clearLoginState();
          debugPrint('[Auth] User signed out, cleared cached roles');
        }
      } else {
        // User signed in - cache their role
        final role = await getCurrentUserRole();
        if (role != null) {
          debugPrint('[Auth] User signed in: ${user.email} with role $role');
        } else {
          debugPrint('[Auth] No role found for user ${user.email}');
          await _clearLoginState();
        }
      }
    });
  }
}