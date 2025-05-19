import 'package:flutter/material.dart';
import '../services/user_service.dart';
import '../services/theme_service.dart';
import '../services/theme_provider.dart';
import '../common/role_selection_page.dart';
import '../citizen/citizen_home_page.dart';
import '../government/gov_home_page.dart';
import '../advertiser/advertiser_home_page.dart';

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
  List<String> loggedInRoles = [];

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    try {
      final userData = await UserService.getCurrentUserData();
      final roles = await UserService.getLoggedInRoles();
      
      if (mounted) {
        setState(() {
          userRole = userData?['role'];
          userName = userData?['name'];
          loggedInRoles = roles;
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
    // Determine if user is logged into multiple roles
    final loggedInRoles = await UserService.getLoggedInRoles();
    
    if (loggedInRoles.length <= 1) {
      // Simple logout if only one role is active
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
    } else {
      // Multi-role logout options
      final String? currentRole = await UserService.getCurrentUserRole();
      if (currentRole == null) return;
      
      final action = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Logout Options'),
          content: const Text('You are logged into multiple roles. What would you like to do?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop('cancel'),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop('current'),
              child: Text('Logout from ${currentRole.capitalize()}'),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () => Navigator.of(context).pop('all'),
              child: const Text('Logout from All Roles'),
            ),
          ],
        ),
      );
      
      if (action == 'current') {
        // Logout from current role only
        await UserService.clearLoginState(currentRole);
        
        // Check if there are other roles still logged in
        final remainingRoles = await UserService.getLoggedInRoles();
        
        if (!context.mounted) return;
        
        if (remainingRoles.isNotEmpty) {
          // Switch to another role's home page
          _navigateToRoleHome(context, remainingRoles.first);
        } else {
          // No more roles, go to selection page
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const RoleSelectionPage()),
            (route) => false,
          );
        }
      } else if (action == 'all') {
        // Logout from all roles
        await UserService.logoutFromAllRoles();
        if (!context.mounted) return;
        
        // Navigate to role selection page
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const RoleSelectionPage()),
          (route) => false,
        );
      }
    }
  }
  
  void _navigateToRoleHome(BuildContext context, String role) {
    Widget homePage;
    
    switch (role.toLowerCase()) {
      case 'citizen':
        homePage = const CitizenHomePage();
        break;
      case 'government':
        homePage = const GovernmentHomePage();
        break;
      case 'advertiser':
        homePage = const AdvertiserHomePage();
        break;
      default:
        homePage = const RoleSelectionPage();
    }
    
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => homePage),
      (route) => false,
    );
  }

  void _showRoleSwitchMenu(BuildContext context) async {
    // Get updated list of roles
    final availableRoles = await UserService.getLoggedInRoles();
    
    if (!context.mounted) return;
    
    if (availableRoles.isEmpty) {
      // No roles available, redirect to login
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const RoleSelectionPage()),
        (route) => false,
      );
      return;
    }
    
    if (availableRoles.length == 1) {
      // Only one role, show a message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You are only logged in as ${availableRoles.first.capitalize()}')),
      );
      return;
    }
    
    // Show role switching menu
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay = Navigator.of(context).overlay!.context.findRenderObject() as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(button.size.bottomRight(Offset.zero), ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );
    
    final selectedRole = await showMenu<String>(
      context: context,
      position: position,
      items: [
        for (final role in availableRoles)
          PopupMenuItem(
            value: role,
            child: Row(
              children: [
                Icon(
                  _getRoleIcon(role),
                  color: ThemeService.getRoleColor(role),
                ),
                const SizedBox(width: 8),
                Text(
                  role.capitalize(),
                  style: TextStyle(
                    fontWeight: role == userRole ? FontWeight.bold : FontWeight.normal,
                    color: role == userRole ? ThemeService.getRoleColor(role) : null,
                  ),
                ),
                if (role == userRole)
                  const Padding(
                    padding: EdgeInsets.only(left: 8.0),
                    child: Icon(Icons.check, size: 16),
                  ),
              ],
            ),
          ),
      ],
    );
    
    if (selectedRole != null && selectedRole != userRole && context.mounted) {
      _navigateToRoleHome(context, selectedRole);
    }
  }
  
  IconData _getRoleIcon(String role) {
    switch (role.toLowerCase()) {
      case 'citizen':
        return Icons.person;
      case 'government':
        return Icons.account_balance;
      case 'advertiser':
        return Icons.campaign;
      default:
        return Icons.person;
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
        
        // User role badge - clickable if multiple roles are available
        if (userRole != null && !isLoading) 
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Center(
              child: InkWell(
                onTap: () => _showRoleSwitchMenu(context),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getRoleIcon(userRole!),
                        size: 16,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        userRole!.capitalize(),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      if (loggedInRoles.length > 1)
                        const Padding(
                          padding: EdgeInsets.only(left: 4.0),
                          child: Icon(
                            Icons.arrow_drop_down,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
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
