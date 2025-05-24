import 'package:flutter/material.dart';
import '../services/auth_service.dart';
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
      final userData = await AuthService.getCurrentUserData();
      final currentRole = await AuthService.getCachedCurrentRole();
      
      if (mounted) {
        setState(() {
          userRole = currentRole;
          userName = userData?['name'];
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading user info: $e');
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void showNotifications(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Notifications"),
        content: const Text("You have no new notifications."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  Future<void> handleMenuSelection(BuildContext context, String value) async {
    if (value == 'settings') {
      // TODO: Navigate to SettingsPage()
    } else if (value == 'logout') {
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
        await AuthService.signOut();

        if (!context.mounted) return;

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const RoleSelectionPage()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(widget.title),
      backgroundColor: context.currentRole == 'government'
          ? Colors.blue.shade700
          : context.currentRole == 'citizen'
              ? Colors.green.shade600
              : context.currentRole == 'advertiser'
                  ? Colors.orange.shade600
                  : Colors.blue.shade700,
      foregroundColor: Colors.white,
      elevation: 2,
      actions: [
        ...?widget.additionalActions,
        IconButton(
          icon: const Icon(Icons.notifications),
          onPressed: () => showNotifications(context),
        ),
        PopupMenuButton<String>(
          onSelected: (value) => handleMenuSelection(context, value),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'settings',
              child: Row(
                children: [
                  Icon(Icons.settings),
                  SizedBox(width: 8),
                  Text('Settings'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'logout',
              child: Row(
                children: [
                  Icon(Icons.logout, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Logout', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
