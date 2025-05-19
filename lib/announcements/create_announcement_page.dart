import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CreateAnnouncementPage extends StatelessWidget {
  const CreateAnnouncementPage({super.key});

  @override
  Widget build(BuildContext context) {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController contentController = TextEditingController();
    final TextEditingController categoryController = TextEditingController();

    return Scaffold(
      appBar: AppBar(title: const Text("Create Announcement")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: "Title"),
            ),
            TextField(
              controller: contentController,
              decoration: const InputDecoration(labelText: "Content"),
              maxLines: 5,
            ),
            TextField(
              controller: categoryController,
              decoration: const InputDecoration(labelText: "Category (optional)"),
            ),
            const SizedBox(height: 20),
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
    );
  }
}
