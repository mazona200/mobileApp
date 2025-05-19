import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditAnnouncementPage extends StatefulWidget {
  final DocumentSnapshot doc;

  const EditAnnouncementPage({super.key, required this.doc});

  @override
  State<EditAnnouncementPage> createState() => _EditAnnouncementPageState();
}

class _EditAnnouncementPageState extends State<EditAnnouncementPage> {
  late TextEditingController titleController;
  late TextEditingController contentController;
  late TextEditingController categoryController;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.doc['title']);
    contentController = TextEditingController(text: widget.doc['content']);
    categoryController = TextEditingController(text: widget.doc['category']);
  }

  void updateAnnouncement() async {
    try {
      await widget.doc.reference.update({
        'title': titleController.text.trim(),
        'content': contentController.text.trim(),
        'category': categoryController.text.trim(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Announcement updated!')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Announcement")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(controller: titleController, decoration: const InputDecoration(labelText: "Title")),
            const SizedBox(height: 10),
            TextField(controller: contentController, decoration: const InputDecoration(labelText: "Content"), maxLines: 5),
            const SizedBox(height: 10),
            TextField(controller: categoryController, decoration: const InputDecoration(labelText: "Category")),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: updateAnnouncement,
              child: const Text("Save Changes"),
            ),
          ],
        ),
      ),
    );
  }
}
