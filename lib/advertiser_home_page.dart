import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'components/role_protected_page.dart';
import 'components/shared_app_bar.dart';

class AdvertiserHomePage extends StatelessWidget {
  const AdvertiserHomePage({super.key});

  void _showNotifications(BuildContext context) {
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

  void _handleMenuSelection(BuildContext context, String value) {
    if (value == 'settings') {
      // TODO: Navigate to SettingsPage()
    } else if (value == 'logout') {
      FirebaseAuth.instance.signOut();
      Navigator.popUntil(context, (route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RoleProtectedPage(
      requiredRole: 'advertiser',
      child: Scaffold(
        appBar: const SharedAppBar(title: "AdvertiserHub"),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            children: [
              _buildButton(context, Icons.add_circle_outline, "Create Advertisement", () {
                // TODO: Navigate to ad creation page
              }),
              _buildButton(context, Icons.campaign_outlined, "My Advertisements", () {
                // TODO: Navigate to advertiser's ads list
              }),
              _buildButton(context, Icons.pending_actions_outlined, "Pending Approvals", () {
                // TODO: Navigate to pending approval ads
              }),
              _buildButton(context, Icons.chat_bubble_outline, "Contact Government", () {
                // TODO: Navigate to messaging page
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildButton(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48),
          const SizedBox(height: 10),
          Text(label, textAlign: TextAlign.center),
        ],
      ),
    );
  }
} 