import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/theme_provider.dart';
import '../common/role_selection_page.dart';

/// A widget that protects pages based on user roles
/// Supports single role requirements or "all_roles" for common pages
class RoleProtectedPage extends StatefulWidget {
  final String requiredRole;
  final Widget child;
  final Widget? loadingWidget;
  final Widget? unauthorizedWidget;
  final bool allowAllRoles;
  
  const RoleProtectedPage({
    super.key,
    required this.requiredRole,
    required this.child,
    this.loadingWidget,
    this.unauthorizedWidget,
    this.allowAllRoles = false,
  });
  
  /// Constructor for pages accessible by all authenticated users
  const RoleProtectedPage.forAllRoles({
    super.key,
    required Widget child,
    Widget? loadingWidget,
    Widget? unauthorizedWidget,
  }) : requiredRole = 'all_roles',
       allowAllRoles = true,
       child = child,
       loadingWidget = loadingWidget,
       unauthorizedWidget = unauthorizedWidget;

  @override
  State<RoleProtectedPage> createState() => _RoleProtectedPageState();
}

class _RoleProtectedPageState extends State<RoleProtectedPage> {
  bool _isLoading = true;
  bool _isAuthorized = false;
  String? _currentRole;
  
  @override
  void initState() {
    super.initState();
    _checkAuthorization();
  }
  
  Future<void> _checkAuthorization() async {
    setState(() => _isLoading = true);
    
    try {
      // Check if any user is logged in
      if (!await AuthService.isAnyUserLoggedIn()) {
        debugPrint('[Auth] No user logged in, redirecting to role selection');
        _redirectToRoleSelection();
        return;
      }
      
      // Get current role
      final currentRole = await AuthService.getCachedCurrentRole();
      
      if (currentRole == null) {
        debugPrint('[Auth] No cached role found, redirecting to role selection');
        await AuthService.signOut();
        _redirectToRoleSelection();
        return;
      }
      
      _currentRole = currentRole;
      
      // Check role authorization
      if (widget.allowAllRoles || widget.requiredRole == 'all_roles') {
        // Allow access for any authenticated user
        _setAuthorized(true);
        return;
      }
      
      if (currentRole == widget.requiredRole) {
        // User has the correct role
        _setAuthorized(true);
        return;
      }
      
      // User has wrong role
      debugPrint('[Auth] User role $currentRole does not match required role ${widget.requiredRole}');
      _showUnauthorizedMessage();
      
    } catch (e) {
      debugPrint('[Auth] Authorization error: $e');
      _setAuthorized(false);
      _showError('Authorization failed: ${e.toString()}');
    }
  }
  
  void _setAuthorized(bool authorized) {
    if (mounted) {
      setState(() {
        _isAuthorized = authorized;
        _isLoading = false;
      });
    }
  }
  
  void _showUnauthorizedMessage() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unauthorized: You are logged in as $_currentRole, '
            'but this page requires ${widget.requiredRole} access'
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
      _redirectToRoleSelection();
    }
  }
  
  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
      _setAuthorized(false);
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
    if (_isLoading) {
      return widget.loadingWidget ?? const Scaffold(
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
    
    if (!_isAuthorized) {
      return widget.unauthorizedWidget ?? Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.lock_outline,
                size: 64,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              Text(
                'Unauthorized Access',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              const Text('You do not have permission to view this page.'),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _redirectToRoleSelection,
                child: const Text('Go to Role Selection'),
              ),
            ],
          ),
        ),
      );
    }
    
    // Wrap with theme provider for role-specific theming
    return ThemeProvider(
      currentRole: _currentRole ?? 'default',
      child: widget.child,
    );
  }
} 