import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../components/shared_app_bar.dart';
import '../components/role_protected_page.dart';
import '../services/theme_service.dart';

class CreateAnnouncementPage extends StatelessWidget {
  const CreateAnnouncementPage({super.key});

  @override
  Widget build(BuildContext context) {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController contentController = TextEditingController();
    final TextEditingController categoryController = TextEditingController();

    return RoleProtectedPage(
      requiredRole: 'government',
      child: Scaffold(
        appBar: const SharedAppBar(title: "Create Announcement"),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              TextField(
                controller: titleController,
                decoration: ThemeService.inputDecoration("Title"),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: contentController,
                decoration: ThemeService.inputDecoration("Content"),
                maxLines: 5,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: categoryController,
                decoration: ThemeService.inputDecoration("Category (optional)"),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  final title = titleController.text.trim();
                  final content = contentController.text.trim();
                  final category = categoryController.text.trim();

                  if (title.isEmpty || content.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Title and content are required")),
                    );
                    return;
                  }

                  await FirebaseFirestore.instance.collection('announcements').add({
                    'title': title,
                    'content': content,
                    'category': category,
                    'createdAt': Timestamp.now(),
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Announcement created!")),
                  );

                  Navigator.pop(context);
                },
                child: const Text("Publish"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
