import 'package:flutter/material.dart';
import 'theme_service.dart';
import 'user_service.dart';

class ThemeProvider extends InheritedWidget {
  final String currentRole;
  final ThemeData theme;
  
  // Constructor takes a role, generates the appropriate theme 
  ThemeProvider({
    super.key,
    required this.currentRole,
    required Widget child,
  }) : 
    theme = ThemeService.getRoleTheme(currentRole),
    super(child: child);
  
  // Get the theme provider from the context
  static ThemeProvider of(BuildContext context) {
    final ThemeProvider? provider = context.dependOnInheritedWidgetOfExactType<ThemeProvider>();
    assert(provider != null, 'No ThemeProvider found in context');
    return provider!;
  }
  
  // Check if we need to rebuild when the provider updates
  @override
  bool updateShouldNotify(ThemeProvider oldWidget) {
    return currentRole != oldWidget.currentRole;
  }
}

class DynamicThemeProvider extends StatefulWidget {
  final Widget child;
  final String? initialRole;
  
  const DynamicThemeProvider({
    Key? key,
    required this.child,
    this.initialRole,
  }) : super(key: key);
  
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
      // Try to get current role from user service
      try {
        final loggedInRoles = await UserService.getLoggedInRoles();
        if (loggedInRoles.isNotEmpty) {
          if (mounted) {
            setState(() {
              _currentRole = loggedInRoles.first;
              _isLoading = false;
            });
          }
        } else {
          // No logged in roles
          if (mounted) {
            setState(() {
              _currentRole = 'default';
              _isLoading = false;
            });
          }
        }
      } catch (e) {
        print('Error loading user roles: $e');
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
  ThemeData get theme => ThemeProvider.of(this).theme;
  String get currentRole => ThemeProvider.of(this).currentRole;
} 