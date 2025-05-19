import 'package:flutter/material.dart';
import 'gov_announcements_page.dart';
import 'gov_dashboard_page.dart';
import '../common/polls_page.dart';
import 'create_poll_page.dart';
import 'inbox_page.dart';
import '../services/user_service.dart';
import '../common/role_selection_page.dart';

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

  Future<void> _handleMenuSelection(BuildContext context, String value) async {
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
            _buildButton(context, Icons.add_chart_outlined, "Create Poll", () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreatePollPage()),
              );
            }),
            _buildButton(context, Icons.chat_bubble_outline, "Inbox", () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const InboxPage()),
              );
            }),
            _buildButton(context, Icons.campaign_outlined, "Manage Ads", () {}),
          ],
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
