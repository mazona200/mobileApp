import 'package:flutter/material.dart';
import 'theme_service.dart';
import 'auth_service.dart';

/// Provides role-specific theming throughout the app
class ThemeProvider extends InheritedWidget {
  final String currentRole;
  final ThemeData theme;
  
  ThemeProvider({
    super.key,
    required this.currentRole,
    required super.child,
  }) : theme = ThemeService.getRoleTheme(currentRole);
  
  ThemeData get actualTheme => theme;
  
  // Get the theme provider from the context
  static ThemeProvider of(BuildContext context) {
    final ThemeProvider? result = context.dependOnInheritedWidgetOfExactType<ThemeProvider>();
    assert(result != null, 'No ThemeProvider found in context');
    return result!;
  }
  
  // Check if we need to rebuild when the provider updates
  @override
  bool updateShouldNotify(ThemeProvider oldWidget) {
    return currentRole != oldWidget.currentRole;
  }
}

/// Dynamic theme provider that automatically detects the current user's role
class DynamicThemeProvider extends StatefulWidget {
  final Widget child;
  final String? initialRole;
  
  const DynamicThemeProvider({
    super.key,
    required this.child,
    this.initialRole,
  });
  
  @override
  State<DynamicThemeProvider> createState() => _DynamicThemeProviderState();
}

class _DynamicThemeProviderState extends State<DynamicThemeProvider> {
  String _currentRole = 'default';
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadCurrentRole();
  }
  
  Future<void> _loadCurrentRole() async {
    if (widget.initialRole != null) {
      // Use the provided initial role if available
      setState(() {
        _currentRole = widget.initialRole!;
        _isLoading = false;
      });
    } else {
      // Try to get current role from auth service
      try {
        final currentRole = await AuthService.getCachedCurrentRole();
        if (currentRole != null && mounted) {
          setState(() {
            _currentRole = currentRole;
            _isLoading = false;
          });
        } else {
          // No logged in role
          if (mounted) {
            setState(() {
              _currentRole = 'default';
              _isLoading = false;
            });
          }
        }
      } catch (e) {
        debugPrint('Error loading user role: $e');
        if (mounted) {
          setState(() {
            _currentRole = 'default';
            _isLoading = false;
          });
        }
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return MaterialApp(
        theme: ThemeService.getAppTheme(),
        home: const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    
    return ThemeProvider(
      currentRole: _currentRole,
      child: widget.child,
    );
  }
}

// Extension method to quickly access the current role and theme
extension ThemeProviderExtension on BuildContext {
  ThemeProvider get themeProvider => ThemeProvider.of(this);
  ThemeData get theme => ThemeProvider.of(this).actualTheme;
  String get currentRole => ThemeProvider.of(this).currentRole;
} 