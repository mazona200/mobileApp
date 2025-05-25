// GovReportsPage.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../components/shared_app_bar.dart';
import '../components/role_protected_page.dart';

class GovReportsPage extends StatelessWidget {
  const GovReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return RoleProtectedPage(
      requiredRole: 'government',
      child: Scaffold(
        appBar: const SharedAppBar(title: "Citizen Reports"),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('problem_reports')
              .orderBy('createdAt', descending: true) // make sure field name matches Firestore!
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Center(
                child: Text(
                  "Error loading reports.",
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
              );
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final reports = snapshot.data?.docs ?? [];

            if (reports.isEmpty) {
              return const Center(
                child: Text(
                  "No reports submitted yet.",
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              itemCount: reports.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final doc = reports[index];
                final data = doc.data() as Map<String, dynamic>;

                final title = data['title'] ?? 'No title';
                final description = data['description'] ?? 'No description';
                final timestamp = data['createdAt'] as Timestamp?;
                final date = timestamp != null
                    ? DateFormat.yMMMd().add_jm().format(timestamp.toDate())
                    : 'Unknown date';

                final isRead = data['isRead'] ?? false;

                return Card(
                  color: isRead ? Colors.grey.shade200 : Colors.white,
                  elevation: 5,
                  shadowColor: Colors.blueGrey.withOpacity(0.15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                    side: BorderSide(color: Colors.blueGrey.shade100),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () async {
                      if (!isRead) {
                        await doc.reference.update({'isRead': true});
                      }

                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: Text(title),
                          content: Text(description),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Close'),
                            ),
                          ],
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.blueAccent.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.all(12),
                            child: const Icon(Icons.report, color: Colors.blueAccent, size: 36),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: isRead ? Colors.grey : Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  description,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.black54,
                                    height: 1.3,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  date,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontStyle: FontStyle.italic,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}