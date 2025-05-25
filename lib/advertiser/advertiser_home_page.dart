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
import '../services/auth_service.dart';
import '../services/theme_service.dart';

class AdvertiserHomePage extends StatelessWidget {
  const AdvertiserHomePage({super.key});

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
        appBar: const SharedAppBar(
          title: "Advertiser Dashboard",
          isHomePage: true,
        ),
        body: FutureBuilder<Map<String, dynamic>?>(
          future: AuthService.getCurrentUserData(),
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
                  // Welcome Section
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: ThemeService.dashboardCardDecoration(Colors.orange.shade600),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome back,',
                          style: ThemeService.bodyStyle.copyWith(color: Colors.white70),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          userName,
                          style: ThemeService.headingStyle.copyWith(color: Colors.white),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Create and manage advertising campaigns',
                          style: ThemeService.bodyStyle.copyWith(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Quick Actions
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Quick Actions',
                          style: ThemeService.subheadingStyle,
                        ),
                        const SizedBox(height: 16),
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 1.2,
                          children: [
                            _buildActionCard(
                              context,
                              'Create Ad',
                              Icons.add_circle_outline,
                              Colors.green.shade600,
                              () {
                                // TODO: Navigate to create ad page
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Create Ad feature coming soon!')),
                                );
                              },
                            ),
                            _buildActionCard(
                              context,
                              'Manage Ads',
                              Icons.campaign,
                              Colors.blue.shade600,
                              () {
                                Navigator.pushNamed(context, '/manage_ads');
                              },
                            ),
                            _buildActionCard(
                              context,
                              'Analytics',
                              Icons.analytics,
                              Colors.purple.shade600,
                              () {
                                // TODO: Navigate to analytics page
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Analytics feature coming soon!')),
                                );
                              },
                            ),
                            _buildActionCard(
                              context,
                              'Settings',
                              Icons.settings,
                              Colors.grey.shade600,
                              () {
                                // TODO: Navigate to settings page
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Settings feature coming soon!')),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Recent Activity Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Recent Activity',
                          style: ThemeService.subheadingStyle,
                        ),
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: ThemeService.cardDecoration(),
                          child: Column(
                            children: [
                              Icon(
                                Icons.inbox_outlined,
                                size: 48,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No recent activity',
                                style: ThemeService.bodyStyle.copyWith(
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Your advertising activities will appear here',
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
<<<<<<< Updated upstream

  Widget _buildActionCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: ThemeService.cardDecoration(),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 32,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: ThemeService.bodyStyle.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
} 
=======
}
>>>>>>> Stashed changes
