import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/user_service.dart';
import '../services/theme_service.dart';
import '../services/theme_provider.dart';
import '../common/role_selection_page.dart';

class SharedAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? additionalActions;
  final bool isHomePage;

  const SharedAppBar({
    super.key,
    required this.title,
    this.additionalActions,
    this.isHomePage = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  State<SharedAppBar> createState() => _SharedAppBarState();
}

class _SharedAppBarState extends State<SharedAppBar> {
  String? userRole;
  String? userName;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    try {
      final userData = await UserService.getCurrentUserData();
      final currentRole = await UserService.getCurrentLoggedInRole();
      
      if (mounted) {
        setState(() {
          userRole = currentRole;
          userName = userData?['name'];
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading user info: $e');
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void _logout(BuildContext context) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      // Clear all login states
      await UserService.logoutFromAllRoles();
      if (!context.mounted) return;
      
      // Navigate to role selection page
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const RoleSelectionPage()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get current role from context if possible, otherwise use the one from user data
    final currentRole = context.currentRole != 'default' ? context.currentRole : userRole ?? 'default';
    final Color roleColor = ThemeService.getRoleColor(currentRole);
    
    return AppBar(
      title: Text(widget.title),
      backgroundColor: roleColor,
      automaticallyImplyLeading: !widget.isHomePage,
      actions: [
        if (widget.additionalActions != null) ...widget.additionalActions!,
          
        // Show logout button only on homepages
        if (widget.isHomePage)
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () => _logout(context),
          ),
        const SizedBox(width: 8),
      ],
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
