import 'package:flutter/material.dart';
import '../components/role_protected_page.dart';
import '../components/shared_app_bar.dart';
import '../services/auth_service.dart';
import '../services/theme_service.dart';
import 'create_advertisment_page.dart';
import 'manage_ads_page.dart';

class AdvertiserHomePage extends StatelessWidget {
  const AdvertiserHomePage({super.key});

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
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const CreateAdvertisementPage()),
                                );
                              },
                            ),
                            _buildActionCard(
                              context,
                              'Manage Ads',
                              Icons.campaign,
                              Colors.blue.shade600,
                              () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const ManageAdsPage()),
                                );
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