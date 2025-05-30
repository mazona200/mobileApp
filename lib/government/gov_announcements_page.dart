import 'package:flutter/material.dart';
import 'create_announcement_page.dart';
import 'announcements_list_page.dart';
import '../components/shared_app_bar.dart';
import '../components/role_protected_page.dart';

class GovAnnouncementsPage extends StatelessWidget {
  const GovAnnouncementsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return RoleProtectedPage(
      requiredRole: 'government',
      child: Scaffold(
        appBar: const SharedAppBar(title: "GovCircle"),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              InkWell(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateAnnouncementPage()),
                ),
                child: const Text(
                  "→ Create New Announcement",
                  style: TextStyle(fontSize: 18, color: Colors.black),
                ),
              ),
              const SizedBox(height: 30),
              InkWell(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AnnouncementsListPage()),
                ),
                child: const Text(
                  "→ Announcements",
                  style: TextStyle(fontSize: 18, color: Colors.black),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
