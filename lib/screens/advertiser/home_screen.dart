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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Welcome to Advertiser Dashboard',
              style: TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 20),
            // Add more advertiser-specific features here
          ],
        ),
      ),
    );
  }
} 