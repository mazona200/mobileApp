import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../components/role_protected_page.dart';
import '../components/shared_app_bar.dart';
import '../services/user_service.dart';
import '../common/role_selection_page.dart';
import '../services/theme_service.dart';

class AdvertiserHomePage extends StatelessWidget {
  const AdvertiserHomePage({super.key});

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
        // Proper logout that clears all login states
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

  @override
  Widget build(BuildContext context) {
    return RoleProtectedPage(
      requiredRole: 'advertiser',
      child: Scaffold(
        appBar: const SharedAppBar(
          title: "Advertiser Dashboard",
          isHomePage: true,
        ),
        body: FutureBuilder<Map<String, dynamic>?>(
          future: UserService.getCurrentUserData(),
          builder: (context, snapshot) {
            String userName = 'Advertiser';
            
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            
            if (snapshot.hasData && snapshot.data != null) {
              userName = snapshot.data!['name'] ?? 'Advertiser';
            }
            
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome, $userName',
                          style: ThemeService.headingStyle,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Manage your advertisements',
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Quick actions
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text('Quick Actions', style: ThemeService.subheadingStyle),
                  ),
                  
                  const SizedBox(height: 10),
                  
                  // Actions grid
                  GridView.count(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.1,
                    children: [
                      _buildDashboardCard(
                        context: context,
                        icon: Icons.add_circle_outline,
                        title: "Create Advertisement", 
                        color: Colors.blue,
                        onTap: () {
                          // TODO: Navigate to ad creation page
                        },
                      ),
                      _buildDashboardCard(
                        context: context,
                        icon: Icons.campaign_outlined,
                        title: "My Advertisements",
                        color: Colors.green,
                        onTap: () {
                          // TODO: Navigate to advertiser's ads list
                        },
                      ),
                      _buildDashboardCard(
                        context: context,
                        icon: Icons.pending_actions_outlined,
                        title: "Pending Approvals",
                        color: Colors.orange,
                        onTap: () {
                          // TODO: Navigate to pending approval ads
                        },
                      ),
                      _buildDashboardCard(
                        context: context,
                        icon: Icons.chat_bubble_outline,
                        title: "Contact Government",
                        color: Colors.purple,
                        onTap: () {
                          // TODO: Navigate to messaging page
                        },
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDashboardCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
} 