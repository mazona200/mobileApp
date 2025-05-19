import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'gov_announcements_page.dart';
import 'gov_dashboard_page.dart';
import '../common/polls_page.dart';
import '../components/role_protected_page.dart';
import '../components/shared_app_bar.dart';

class GovernmentHomePage extends StatelessWidget {
  const GovernmentHomePage({super.key});

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
      requiredRole: 'government',
      child: Scaffold(
        appBar: const SharedAppBar(
          title: "GovCircle",
          isHomePage: true,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            children: [
              _buildButton(context, Icons.home, "Home", () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const GovDashboardPage()),
                );
              }),
              _buildButton(context, Icons.announcement_outlined, "New Announcement", () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const GovAnnouncementsPage()),
                );
              }),
              _buildButton(context, Icons.how_to_vote_outlined, "Polls", () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PollsPage()),
                );
              }),
              _buildButton(context, Icons.chat_bubble_outline, "Inbox", () {}),
              _buildButton(context, Icons.campaign_outlined, "Manage Ads", () {}),
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
