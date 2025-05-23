import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageAdsPage extends StatelessWidget {
  const ManageAdsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Ads')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('ads').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No ads found.'));
          }

          final ads = snapshot.data!.docs;

          return ListView.builder(
            itemCount: ads.length,
            itemBuilder: (context, index) {
              final doc = ads[index];
              final data = doc.data() as Map<String, dynamic>;
              final title = data['title'] ?? 'No title';
              final description = data['description'] ?? '';
              // ignore: unused_local_variable
              final timestamp = (data['createdAt'] as Timestamp?)?.toDate();

              return ListTile(
                title: Text(title),
                subtitle: Text(description),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () async {
                    await FirebaseFirestore.instance
                        .collection('ads')
                        .doc(doc.id)
                        .delete();
                  },
                ),
                onTap: () {
                  // Optionally: navigate to edit screen
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Optional: add ad creation logic here
        },
        child: const Icon(Icons.add),
        tooltip: 'Add New Ad',
      ),
    );
  }
}