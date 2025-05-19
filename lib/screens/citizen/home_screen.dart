import 'package:flutter/material.dart';

class CitizenHomeScreen extends StatelessWidget {
  const CitizenHomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Citizen Dashboard'),
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
            // Announcements Section
            const Text(
              'Latest Announcements',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Card(
              child: ListTile(
                leading: const Icon(Icons.announcement),
                title: const Text('Community Meeting'),
                subtitle: const Text('Join us for the monthly community meeting'),
                onTap: () {
                  // TODO: Navigate to announcement details
                },
              ),
            ),
            const SizedBox(height: 20),

            // Active Polls Section
            const Text(
              'Active Polls',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Card(
              child: ListTile(
                leading: const Icon(Icons.poll),
                title: const Text('Community Survey'),
                subtitle: const Text('Share your thoughts on local improvements'),
                onTap: () {
                  // TODO: Navigate to poll details
                },
              ),
            ),
            const SizedBox(height: 20),

            // Local Services Section
            const Text(
              'Local Services',
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
                _buildServiceCard(
                  context,
                  'Report Issue',
                  Icons.report_problem,
                  () {
                    // TODO: Navigate to report issue
                  },
                ),
                _buildServiceCard(
                  context,
                  'Local Events',
                  Icons.event,
                  () {
                    // TODO: Navigate to events
                  },
                ),
                _buildServiceCard(
                  context,
                  'Community Chat',
                  Icons.chat,
                  () {
                    // TODO: Navigate to chat
                  },
                ),
                _buildServiceCard(
                  context,
                  'Directory',
                  Icons.people,
                  () {
                    // TODO: Navigate to directory
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCard(
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