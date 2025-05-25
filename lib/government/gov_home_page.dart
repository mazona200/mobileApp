import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'gov_announcements_page.dart';
import 'gov_dashboard_page.dart';
import '../common/polls_page.dart';
<<<<<<< Updated upstream
=======
import 'create_poll_page.dart';
import 'inbox_page.dart';
import 'manage_ads_page.dart'; // ✅ Import Manage Ads Page
import 'review_advertisements_page.dart'; // ✅ Import Review Advertisements Page
import '../services/user_service.dart';
import '../common/role_selection_page.dart';
import '../components/shared_app_bar.dart';
>>>>>>> Stashed changes
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
<<<<<<< Updated upstream
        appBar: const SharedAppBar(
          title: "GovCircle",
          isHomePage: true,
=======
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
                  Center(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ReviewAdvertisementsPage()),
                        );
                      },
                      child: const Text("Review Advertisements"),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
>>>>>>> Stashed changes
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
