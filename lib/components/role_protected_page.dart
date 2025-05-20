import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/user_service.dart';
import '../services/theme_provider.dart';
import '../common/role_selection_page.dart';

class RoleProtectedPage extends StatefulWidget {
  final String requiredRole;
  final Widget child;
  final Widget? loadingWidget;
  final Widget? unauthorizedWidget;
  
  const RoleProtectedPage({
    super.key,
    required this.requiredRole,
    required this.child,
    this.loadingWidget,
    this.unauthorizedWidget,
  });

  @override
  State<RoleProtectedPage> createState() => _RoleProtectedPageState();
}

class _RoleProtectedPageState extends State<RoleProtectedPage> {
  bool isLoading = true;
  bool isAuthorized = false;
  
  @override
  void initState() {
    super.initState();
    _checkAuthorization();
  }
  
  Future<void> _checkAuthorization() async {
    setState(() => isLoading = true);
    
    try {
      // Check if any user is logged in
      if (!await UserService.isAnyUserLoggedIn()) {
        // No user logged in, redirect to role selection
        _redirectToRoleSelection();
        return;
      }
      
      // Special case: if requiredRole is "all_roles", allow access to any logged-in user
      if (widget.requiredRole == "all_roles") {
        if (mounted) {
          setState(() {
            isAuthorized = true;
            isLoading = false;
          });
        }
        return;
      }
      
      // Check if the current role matches the required role
      final currentRole = await UserService.getCurrentLoggedInRole();
      
      if (currentRole != widget.requiredRole) {
        // Current role doesn't match required role
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Unauthorized: You are logged in as $currentRole, not as ${widget.requiredRole}')),
          );
          
          // Log out the current user and redirect to role selection
          await UserService.logoutFromAllRoles();
          _redirectToRoleSelection();
        }
        return;
      }
      
      // User is authorized with the correct role
      if (mounted) {
        setState(() {
          isAuthorized = true;
          isLoading = false;
        });
      }
    } catch (e) {
      // Error occurred during authorization check
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Authorization error: $e')),
        );
        setState(() => isLoading = false);
      }
    }
  }
  
  void _redirectToRoleSelection() {
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const RoleSelectionPage()),
        (route) => false, // Remove all previous routes
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Wrap child with ThemeProvider for role-specific theming
    Widget buildThemedChild() {
      return ThemeProvider(
        currentRole: widget.requiredRole,
        child: Builder(
          builder: (context) => widget.child,
        ),
      );
    }
    
    if (isLoading) {
      return widget.loadingWidget ?? const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    if (!isAuthorized) {
      return widget.unauthorizedWidget ?? Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Unauthorized access. Redirecting to role selection...'),
              const SizedBox(height: 20),
              TextButton(
                onPressed: _redirectToRoleSelection,
                child: const Text('Go to Role Selection'),
              ),
            ],
          ),
        ),
      );
    }
    
    return buildThemedChild();
  }
} 