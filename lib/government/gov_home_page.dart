import 'package:flutter/material.dart';
import 'gov_announcements_page.dart';
import 'gov_dashboard_page.dart';
import '../common/polls_page.dart';
import 'create_poll_page.dart';
import 'inbox_page.dart';
import 'manage_ads_page.dart'; // ✅ Import Manage Ads Page
import '../services/user_service.dart';
import '../common/role_selection_page.dart';
import '../components/shared_app_bar.dart';
import '../components/role_protected_page.dart';
import '../services/theme_service.dart';

class GovernmentHomePage extends StatelessWidget {
  const GovernmentHomePage({super.key});

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
    if (value == 'logout') {
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
        appBar: const SharedAppBar(title: "Government Dashboard", isHomePage: true),
        body: FutureBuilder<Map<String, dynamic>?>(
          future: UserService.getCurrentUserData(),
          builder: (context, snapshot) {
            String userName = 'Administrator';
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasData && snapshot.data != null) {
              userName = snapshot.data!['name'] ?? 'Administrator';
            }

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                        Text('Welcome, $userName', style: ThemeService.headingStyle),
                        const SizedBox(height: 8),
                        const Text('Government Administration Panel', style: TextStyle(fontSize: 16)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text('Administration Tools', style: ThemeService.subheadingStyle),
                  ),
                  const SizedBox(height: 10),
                  GridView.count(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.1,
                    children: [
                      buildDashboardCard(
                        context: context,
                        icon: Icons.home,
                        title: "Home",
                        color: Colors.blue,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const GovDashboardPage()),
                        ),
                      ),
                      buildDashboardCard(
                        context: context,
                        icon: Icons.announcement_outlined,
                        title: "New Announcement",
                        color: Colors.green,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const GovAnnouncementsPage()),
                        ),
                      ),
                      buildDashboardCard(
                        context: context,
                        icon: Icons.how_to_vote_outlined,
                        title: "Polls",
                        color: Colors.orange,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const PollsPage()),
                        ),
                      ),
                      buildDashboardCard(
                        context: context,
                        icon: Icons.add_chart_outlined,
                        title: "Create Poll",
                        color: Colors.purple,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const CreatePollPage()),
                        ),
                      ),
                      buildDashboardCard(
                        context: context,
                        icon: Icons.chat_bubble_outline,
                        title: "Inbox",
                        color: Colors.teal,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const InboxPage()),
                        ),
                      ),
                      buildDashboardCard(
                        context: context,
                        icon: Icons.campaign_outlined,
                        title: "Manage Ads",
                        color: Colors.red,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ManageAdsPage()),
                        ),
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

  Widget buildDashboardCard({
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