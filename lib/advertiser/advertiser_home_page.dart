import 'package:flutter/material.dart';
import '../components/role_protected_page.dart';
import '../components/shared_app_bar.dart';
<<<<<<< Updated upstream
=======
import '../services/user_service.dart';
import '../common/role_selection_page.dart';
import '../services/theme_service.dart';
import '../advertiser/create_advertisement_page.dart';
import '../advertiser/manage_ads_page.dart';
import '../government/review_advertisements_page.dart';
>>>>>>> Stashed changes

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
<<<<<<< Updated upstream
        appBar: const SharedAppBar(title: "AdvertiserHub"),
        body: Padding(
=======
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
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const CreateAdvertisementPage(),
                            ),
                          );
                        },
                      ),
                      _buildDashboardCard(
                        context: context,
                        icon: Icons.campaign_outlined,
                        title: "My Advertisements",
                        color: Colors.green,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ManageAdsPage(),
                            ),
                          );
                        },
                      ),
                    
                      _buildDashboardCard(
                        context: context,
                        icon: Icons.chat_bubble_outline,
                        title: "Contact Government",
                        color: Colors.purple,
                        onTap: () {
                          // Navigate to a placeholder or messaging page
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text("Contact Government"),
                              content: const Text("This feature is under development."),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text("OK"),
                                ),
                              ],
                            ),
                          );
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
>>>>>>> Stashed changes
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
<<<<<<< Updated upstream

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
=======
}
>>>>>>> Stashed changes
