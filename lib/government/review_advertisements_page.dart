import 'package:flutter/material.dart';
import '../services/advertisement_service.dart';
import '../models/advertisement.dart';

class ReviewAdvertisementsPage extends StatelessWidget {
  const ReviewAdvertisementsPage({super.key});

  Future<void> approveAdvertisement(BuildContext context, String id) async {
    try {
      await AdvertisementService().approveAdvertisement(id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Advertisement approved!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  Future<void> rejectAdvertisement(BuildContext context, String id) async {
    final TextEditingController reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Reject Advertisement"),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(labelText: "Rejection Reason"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await AdvertisementService().rejectAdvertisement(id, reasonController.text.trim());
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Advertisement rejected!")),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Error: $e")),
                );
              }
            },
            child: const Text("Reject"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Review Advertisements")),
      body: StreamBuilder<List<Advertisement>>(
        stream: AdvertisementService().getPendingAdvertisements(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final advertisements = snapshot.data ?? [];

          if (advertisements.isEmpty) {
            return const Center(child: Text("No pending advertisements"));
          }

          return ListView.builder(
            itemCount: advertisements.length,
            itemBuilder: (context, index) {
              final ad = advertisements[index];
              return Card(
                margin: const EdgeInsets.all(10),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ad.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 5),
                      Text(ad.description),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => approveAdvertisement(context, ad.id),
                            child: const Text("Approve"),
                          ),
                          TextButton(
                            onPressed: () => rejectAdvertisement(context, ad.id),
                            child: const Text("Reject"),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
