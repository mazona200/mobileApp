import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/user_service.dart';
import '../services/theme_provider.dart';
import '../common/login_page.dart';

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
      final user = FirebaseAuth.instance.currentUser;
      
      if (user == null) {
        // User is not logged in, redirect to login
        _redirectToLogin();
        return;
      }
      
      // Check if user has the required role
      final hasRole = await UserService.hasRole(widget.requiredRole);
      
      if (!hasRole) {
        // User doesn't have the required role, show error and redirect
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Unauthorized: You do not have ${widget.requiredRole} access')),
          );
          _redirectToLogin();
        }
        return;
      }
      
      // User is authorized
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
  
  void _redirectToLogin() {
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => LoginPage(role: widget.requiredRole)),
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
              const Text('Unauthorized access. Redirecting...'),
              const SizedBox(height: 20),
              TextButton(
                onPressed: _redirectToLogin,
                child: const Text('Return to Login'),
              ),
            ],
          ),
        ),
      );
    }
    
    return buildThemedChild();
  }
} 