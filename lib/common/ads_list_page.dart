import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobile_project/models/ad_model.dart';  // Adjust path to your `ad_model.dart`
import '../components/role_protected_page.dart';

class AdsListPage extends StatelessWidget {
  const AdsListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return RoleProtectedPage(
      requiredRole: "all_roles",
      child: Scaffold(
        appBar: AppBar(title: const Text('Ads List')),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('ads')
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            final docs = snapshot.data?.docs ?? [];

            if (docs.isEmpty) {
              return const Center(child: Text('No ads available.'));
            }

            return ListView.separated(
              itemCount: docs.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final doc = docs[index];
                final ad = Ad.fromDoc(doc);

                return ListTile(
                  title: Text(ad.title),
                  subtitle: Text(ad.description),
                  trailing: Text(ad.status),
                  onTap: () {
                    // Navigate to edit or view ad details if needed
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
