import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ViewMessagesPage extends StatefulWidget {
  const ViewMessagesPage({super.key});

  @override
  State<ViewMessagesPage> createState() => _ViewMessagesPageState();
}

class _ViewMessagesPageState extends State<ViewMessagesPage> {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  Stream<QuerySnapshot>? messagesStream;

  @override
  void initState() {
    super.initState();
    if (uid != null) {
      messagesStream = FirebaseFirestore.instance
          .collection('government_messages')
          .where('userId', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .snapshots();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (uid == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Messages')),
        body: const Center(child: Text('You must be logged in to view your messages.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('My Messages')),
      body: StreamBuilder<QuerySnapshot>(
        stream: messagesStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No messages sent.'));
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final subject = data['subject'] ?? 'No subject';
              final message = data['message'] ?? 'No content';
              final senderEmail = data['senderEmail'] ?? 'Unknown';
              final timestamp = (data['createdAt'] as Timestamp?)?.toDate();

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ExpansionTile(
                  title: Text(subject, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(senderEmail),
                      if (timestamp != null)
                        Text(
                          'Sent: ${timestamp.toLocal()}',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                    ],
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(message),
                    ),
                    StreamBuilder<QuerySnapshot>(
                      stream: doc.reference.collection('replies').orderBy('timestamp').snapshots(),
                      builder: (context, replySnap) {
                        if (!replySnap.hasData || replySnap.data!.docs.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.all(12),
                            child: Text('No replies yet.'),
                          );
                        }
                        return Column(
                          children: replySnap.data!.docs.map((replyDoc) {
                            final reply = replyDoc.data() as Map<String, dynamic>;
                            return ListTile(
                              leading: const Icon(Icons.reply, color: Colors.green),
                              title: Text(reply['message'] ?? ''),
                              subtitle: reply['timestamp'] != null
                                  ? Text((reply['timestamp'] as Timestamp).toDate().toLocal().toString())
                                  : null,
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}