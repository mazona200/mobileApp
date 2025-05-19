import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'gov_reports_page.dart';

class GovDashboardPage extends StatelessWidget {
  const GovDashboardPage({super.key});

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
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            CircleAvatar(
              backgroundImage: AssetImage('assets/logo.png'),
              radius: 18,
            ),
            SizedBox(width: 10),
            Text("GovCircle"),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () => _showNotifications(context),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) => _handleMenuSelection(context, value),
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'settings', child: Text('Settings')),
              PopupMenuItem(value: 'logout', child: Text('Logout')),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Align(
              alignment: Alignment.centerRight,
              child: Icon(Icons.reply),
            ),
            const SizedBox(height: 30),
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const GovReportsPage()),
                );
              },
              child: const Text("• View reports", style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}
