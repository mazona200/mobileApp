import 'package:flutter/material.dart';
import '../services/advertisement_service.dart';
import '../models/advertisement.dart';

class CreateAdvertisementPage extends StatefulWidget {
  const CreateAdvertisementPage({super.key});

  @override
  State<CreateAdvertisementPage> createState() => _CreateAdvertisementPageState();
}

class _CreateAdvertisementPageState extends State<CreateAdvertisementPage> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController businessNameController = TextEditingController();
  final TextEditingController businessTypeController = TextEditingController();
  final TextEditingController imageUrlController = TextEditingController(text: "https://example.com/default-image.jpg");

  Future<void> submitAdvertisement() async {
    final title = titleController.text.trim();
    final description = descriptionController.text.trim();
    final businessName = businessNameController.text.trim();
    final businessType = businessTypeController.text.trim();
    final imageUrl = imageUrlController.text.trim();

    if (title.isEmpty || description.isEmpty || businessName.isEmpty || businessType.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("All fields are required")),
      );
      return;
    }

    final advertisement = Advertisement(
      id: '',
      title: title,
      description: description,
      businessName: businessName,
      businessType: businessType,
      imageUrls: [imageUrl],
      startDate: DateTime.now(),
      endDate: DateTime.now().add(const Duration(days: 30)),
      createdBy: 'advertiserId', // Replace with actual advertiser ID
      createdAt: DateTime.now(),
      contactInfo: {},
      location: {},
    );

    try {
      await AdvertisementService().createAdvertisement(advertisement, []);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Advertisement submitted for approval")),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Advertisement")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(controller: titleController, decoration: const InputDecoration(labelText: "Title")),
              const SizedBox(height: 10),
              TextField(controller: descriptionController, decoration: const InputDecoration(labelText: "Description"), maxLines: 5),
              const SizedBox(height: 10),
              TextField(controller: businessNameController, decoration: const InputDecoration(labelText: "Business Name")),
              const SizedBox(height: 10),
              TextField(controller: businessTypeController, decoration: const InputDecoration(labelText: "Business Type")),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: submitAdvertisement,
                child: const Text("Submit for Approval"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
