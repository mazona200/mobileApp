import 'package:flutter/material.dart';
import '../components/role_protected_page.dart';
import '../components/shared_app_bar.dart';
import '../services/auth_service.dart';
import '../services/theme_service.dart';
import 'gov_announcements_page.dart';
import 'create_poll_page.dart';
import 'inbox_page.dart';
import 'gov_dashboard_page.dart';
import 'manage_ads_page.dart';

class GovernmentHomePage extends StatelessWidget {
  const GovernmentHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return RoleProtectedPage(
      requiredRole: 'government',
      child: Scaffold(
        appBar: const SharedAppBar(title: "Government Dashboard", isHomePage: true),
        body: FutureBuilder<Map<String, dynamic>?>(
          future: AuthService.getCurrentUserData(),
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
                  // Welcome Section
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: ThemeService.dashboardCardDecoration(Colors.blue.shade700),
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
                          'Manage government services and citizen communications',
                          style: ThemeService.bodyStyle.copyWith(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Quick Actions Grid
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
                              'Announcements',
                              Icons.campaign,
                              Colors.blue.shade600,
                              () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const GovAnnouncementsPage()),
                              ),
                            ),
                            _buildActionCard(
                              context,
                              'Create Poll',
                              Icons.poll,
                              Colors.green.shade600,
                              () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const CreatePollPage()),
                              ),
                            ),
                            _buildActionCard(
                              context,
                              'Inbox',
                              Icons.inbox,
                              Colors.orange.shade600,
                              () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const InboxPage()),
                              ),
                            ),
                            _buildActionCard(
                              context,
                              'Dashboard',
                              Icons.dashboard,
                              Colors.purple.shade600,
                              () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const GovDashboardPage()),
                              ),
                            ),
                            _buildActionCard(
                              context,
                              'Manage Ads',
                              Icons.ad_units,
                              Colors.teal.shade600,
                              () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const ManageAdsPage()),
                              ),
                            ),
                          ],
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