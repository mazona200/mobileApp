import 'package:flutter/material.dart';

class AdvertiserHomeScreen extends StatelessWidget {
  const AdvertiserHomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Advertiser Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              // TODO: Implement logout
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Campaign Stats Section
            const Text(
              'Campaign Performance',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              children: [
                _buildStatCard(
                  'Active Campaigns',
                  '3',
                  Icons.campaign,
                  Colors.blue,
                ),
                _buildStatCard(
                  'Total Views',
                  '1.2K',
                  Icons.visibility,
                  Colors.green,
                ),
                _buildStatCard(
                  'Engagement Rate',
                  '4.5%',
                  Icons.trending_up,
                  Colors.orange,
                ),
                _buildStatCard(
                  'Budget Used',
                  '65%',
                  Icons.account_balance_wallet,
                  Colors.purple,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Active Campaigns Section
            const Text(
              'Active Campaigns',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Card(
              child: ListTile(
                leading: const Icon(Icons.campaign, color: Colors.blue),
                title: const Text('Summer Promotion'),
                subtitle: const Text('Ends in 5 days'),
                trailing: const Text('1.2K views'),
                onTap: () {
                  // TODO: Navigate to campaign details
                },
              ),
            ),
            const SizedBox(height: 20),

            // Campaign Management Section
            const Text(
              'Campaign Management',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              children: [
                _buildToolCard(
                  context,
                  'Create Campaign',
                  Icons.add_circle,
                  () {
                    // TODO: Navigate to create campaign
                  },
                ),
                _buildToolCard(
                  context,
                  'Analytics',
                  Icons.analytics,
                  () {
                    // TODO: Navigate to analytics
                  },
                ),
                _buildToolCard(
                  context,
                  'Budget',
                  Icons.account_balance_wallet,
                  () {
                    // TODO: Navigate to budget management
                  },
                ),
                _buildToolCard(
                  context,
                  'Targeting',
                  Icons.people,
                  () {
                    // TODO: Navigate to targeting settings
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolCard(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
} 