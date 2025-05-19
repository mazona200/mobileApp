import 'package:flutter/material.dart';
import 'user_service.dart';
import '../common/login_page.dart';

class AuthMiddleware {
  // Checks if user is authenticated and has the correct role
  // Returns true if access is allowed, false otherwise
  static Future<bool> hasAccess(BuildContext context, String requiredRole) async {
    String? userRole = await UserService.getCurrentUserRole();
    
    if (userRole == null) {
      // User is not authenticated or role is not set
      _redirectToLogin(context, requiredRole);
      return false;
    }
    
    if (userRole != requiredRole) {
      // User is authenticated but has the wrong role
      _showUnauthorizedMessage(context, userRole, requiredRole);
      return false;
    }
    
    return true;
  }
  
  // Redirects to login page
  static void _redirectToLogin(BuildContext context, String role) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => LoginPage(role: role)),
    );
  }
  
  // Shows unauthorized access message
  static void _showUnauthorizedMessage(BuildContext context, String userRole, String requiredRole) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Unauthorized: You are logged in as $userRole but this page requires $requiredRole access'),
        duration: const Duration(seconds: 5),
      ),
    );
    
    // Navigate back to previous page
    Navigator.of(context).pop();
  }
  
  // Widget wrapper for role-based access
  static Widget protectedRoute({
    required BuildContext context,
    required String requiredRole,
    required Widget child,
    Widget? loadingWidget,
    Widget? fallback,
    Widget? errorWidget,
  }) {
    return FutureBuilder<bool>(
      future: hasAccess(context, requiredRole),
      builder: (context, snapshot) {
        // Show loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return loadingWidget ?? const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Verifying access...'),
                ],
              ),
            ),
          );
        }
        
        // Show error state
        if (snapshot.hasError) {
          return errorWidget ?? Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: Colors.red, size: 48),
                  SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                  SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => _redirectToLogin(context, requiredRole),
                    child: const Text('Return to Login'),
                  ),
                ],
              ),
            ),
          );
        }
        
        // Show authorized content
        if (snapshot.data == true) {
          return child;
        }
        
        // Show unauthorized fallback
        return fallback ?? const Scaffold(
          body: Center(child: Text('Unauthorized access')),
        );
      },
    );
  }
} 