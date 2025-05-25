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
      requiredRole: 'government', // Ensure this role string matches your auth roles exactly
      child: Scaffold(
        appBar: const SharedAppBar(title: "GovCircle"),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  backgroundColor: Colors.blueAccent,
                ),
                icon: const Icon(Icons.create_outlined, color: Colors.white),
                label: const Text(
                  "Create New Announcement",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CreateAnnouncementPage()),
                  );
                },
              ),

              const SizedBox(height: 30),

              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  backgroundColor: Colors.green,
                ),
                icon: const Icon(Icons.list_alt_outlined, color: Colors.white),
                label: const Text(
                  "Announcements",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AnnouncementsListPage()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}