import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class GovReportsPage extends StatelessWidget {
  const GovReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Citizen Reports")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('citizen_reports')
            .orderBy('submittedAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text("Error loading reports."));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final reports = snapshot.data!.docs;

          if (reports.isEmpty) {
            return const Center(child: Text("No reports submitted yet."));
          }

          return ListView.builder(
            itemCount: reports.length,
            itemBuilder: (context, index) {
              final doc = reports[index];
              final data = doc.data() as Map<String, dynamic>;

              final title = data['title'] ?? 'No title';
              final description = data['description'] ?? 'No description';
              final timestamp = data['submittedAt'] as Timestamp?;
              final date = timestamp != null
                  ? DateFormat.yMMMd().add_jm().format(timestamp.toDate())
                  : 'Unknown date';

              return ListTile(
                leading: const Icon(Icons.report),
                title: Text(title),
                subtitle: Text('$description\n$date'),
                isThreeLine: true,
              );
            },
          );
        },
      ),
    );
  }
}
