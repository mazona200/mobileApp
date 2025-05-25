import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageAdsPage extends StatefulWidget {
  const ManageAdsPage({super.key});

  @override
  State<ManageAdsPage> createState() => _ManageAdsPageState();
}

class _ManageAdsPageState extends State<ManageAdsPage> {
  final _formKey = GlobalKey<FormState>();
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final imageUrlController = TextEditingController();

  // Add new ad
  Future<void> createAd() async {
    if (!_formKey.currentState!.validate()) return;

    final title = titleController.text.trim();
    final description = descriptionController.text.trim();
    final imageUrl = imageUrlController.text.trim();

    try {
      await FirebaseFirestore.instance.collection('advertisements').add({
        'title': title,
        'description': description,
        'imageUrls': [imageUrl], // Updated to store image URLs as a list
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'active',
        'isApproved': false, // Default to not approved
        'createdBy': 'advertiserId', // Replace with actual advertiser ID
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ad created successfully!')),
      );

      // Clear inputs
      titleController.clear();
      descriptionController.clear();
      imageUrlController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating ad: $e')),
      );
    }
  }

  // Fetch active ads for the advertiser
  Stream<QuerySnapshot> fetchActiveAds(String advertiserId) {
    return FirebaseFirestore.instance
        .collection('advertisements')
        .where('createdBy', isEqualTo: advertiserId) // Use actual advertiser ID
        .where('isApproved', isEqualTo: true)
        .where('status', isEqualTo: 'active')
        .snapshots();
  }

  // Fetch pending ads for the advertiser
  Stream<QuerySnapshot> fetchPendingAds(String advertiserId) {
    return FirebaseFirestore.instance
        .collection('advertisements')
        .where('createdBy', isEqualTo: advertiserId) // Use actual advertiser ID
        .where('isApproved', isEqualTo: false)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final String advertiserId = 'advertiserId'; // Replace with actual logic to fetch advertiser ID

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Advertisements'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Active Ads'),
              Tab(text: 'Pending Ads'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Active Ads Tab
            StreamBuilder<QuerySnapshot>(
              stream: fetchActiveAds(advertiserId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final ads = snapshot.data?.docs ?? [];

                if (ads.isEmpty) {
                  return const Center(child: Text('No active advertisements'));
                }

                return ListView.builder(
                  itemCount: ads.length,
                  itemBuilder: (context, index) {
                    final ad = ads[index].data() as Map<String, dynamic>;
                    final imageUrls = ad['imageUrls'] as List<dynamic>? ?? [];
                    return Card(
                      margin: const EdgeInsets.all(10),
                      child: ListTile(
                        title: Text(
                          ad['title'] ?? 'No Title',
                          style: const TextStyle(
                            fontWeight: FontWeight.w400,
                            color: Colors.black54,
                          ),
                        ),
                        subtitle: Text(ad['description'] ?? 'No Description'),
                        trailing: imageUrls.isNotEmpty
                            ? Image.network(
                                imageUrls.first,
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.broken_image),
                              )
                            : const Icon(Icons.image_not_supported),
                      ),
                    );
                  },
                );
              },
            ),

            // Pending Ads Tab
            StreamBuilder<QuerySnapshot>(
              stream: fetchPendingAds(advertiserId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final ads = snapshot.data?.docs ?? [];

                if (ads.isEmpty) {
                  return const Center(child: Text('No pending advertisements'));
                }

                return ListView.builder(
                  itemCount: ads.length,
                  itemBuilder: (context, index) {
                    final ad = ads[index].data() as Map<String, dynamic>;
                    final imageUrls = ad['imageUrls'] as List<dynamic>? ?? [];
                    return Card(
                      margin: const EdgeInsets.all(10),
                      child: ListTile(
                        title: Text(ad['title'] ?? 'No Title'),
                        subtitle: Text(ad['description'] ?? 'No Description'),
                        trailing: imageUrls.isNotEmpty
                            ? Image.network(
                                imageUrls.first,
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.broken_image),
                              )
                            : const Icon(Icons.image_not_supported),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
