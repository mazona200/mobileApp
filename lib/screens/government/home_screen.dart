import 'package:flutter/material.dart';

class GovernmentHomeScreen extends StatelessWidget {
  const GovernmentHomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Government Dashboard'),
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
            // Quick Stats Section
            const Text(
              'Quick Stats',
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
                  'Active Issues',
                  '12',
                  Icons.warning,
                  Colors.orange,
                ),
                _buildStatCard(
                  'Pending Requests',
                  '5',
                  Icons.pending_actions,
                  Colors.blue,
                ),
                _buildStatCard(
                  'Active Polls',
                  '3',
                  Icons.poll,
                  Colors.green,
                ),
                _buildStatCard(
                  'Announcements',
                  '8',
                  Icons.announcement,
                  Colors.purple,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Recent Issues Section
            const Text(
              'Recent Issues',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Card(
              child: ListTile(
                leading: const Icon(Icons.warning, color: Colors.orange),
                title: const Text('Road Maintenance Required'),
                subtitle: const Text('Main Street needs repair'),
                trailing: const Text('2 days ago'),
                onTap: () {
                  // TODO: Navigate to issue details
                },
              ),
            ),
            const SizedBox(height: 20),

            // Management Tools Section
            const Text(
              'Management Tools',
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
                  'Create Announcement',
                  Icons.announcement,
                  () {
                    // TODO: Navigate to create announcement
                  },
                ),
                _buildToolCard(
                  context,
                  'Manage Polls',
                  Icons.poll,
                  () {
                    // TODO: Navigate to manage polls
                  },
                ),
                _buildToolCard(
                  context,
                  'Issue Management',
                  Icons.assignment,
                  () {
                    // TODO: Navigate to issue management
                  },
                ),
                _buildToolCard(
                  context,
                  'User Management',
                  Icons.people,
                  () {
                    // TODO: Navigate to user management
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