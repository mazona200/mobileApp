import 'package:flutter/material.dart';
import 'gov_reports_page.dart';
import '../components/shared_app_bar.dart';
import '../components/role_protected_page.dart';
import '../services/user_service.dart';
import '../common/role_selection_page.dart';

class GovDashboardPage extends StatelessWidget {
  const GovDashboardPage({super.key});

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
        await UserService.logoutFromAllRoles();

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
    return RoleProtectedPage(
      requiredRole: 'government',
      child: Scaffold(
        appBar: const SharedAppBar(title: "Government Dashboard"),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 30),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  backgroundColor: Colors.blueAccent,
                ),
                icon: const Icon(Icons.report, color: Colors.white),
                label: const Text(
                  "View Reports",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const GovReportsPage()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}