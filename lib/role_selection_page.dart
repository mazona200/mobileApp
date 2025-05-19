import 'package:flutter/material.dart';
import 'login_page.dart';

class RoleSelectionPage extends StatelessWidget {
  const RoleSelectionPage({super.key});

  void navigateToLogin(BuildContext context, String role) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => LoginPage(role: role)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Select Role")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.person),
              label: const Text("Citizen"),
              onPressed: () => navigateToLogin(context, "citizen"),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.account_balance),
              label: const Text("Government"),
              onPressed: () => navigateToLogin(context, "government"),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.campaign),
              label: const Text("Advertiser"),
              onPressed: () => navigateToLogin(context, "advertiser"),
            ),
          ],
        ),
      ),
    );
  }
}
