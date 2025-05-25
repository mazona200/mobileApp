import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class InboxPage extends StatelessWidget {
  const InboxPage({super.key});

  Future<String> _getSenderEmail(String uid) async {
    if (uid.isEmpty) return 'Unknown';
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (userDoc.exists) {
      return userDoc.data()?['email'] ?? 'Unknown';
    }
    return 'Unknown';
  }

  void _replyToMessage(BuildContext context, DocumentReference messageRef) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reply to Message'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Your Reply'),
          maxLines: 4,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final reply = controller.text.trim();
              if (reply.isNotEmpty) {
                await messageRef.collection('replies').add({
                  'message': reply,
                  'timestamp': FieldValue.serverTimestamp(),
                  'repliedBy': FirebaseAuth.instance.currentUser?.email ?? 'unknown',
                });

                await messageRef.update({
                  'lastRepliedAt': FieldValue.serverTimestamp(),
                  'hasReply': true,
                });
              }
              Navigator.pop(context);
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final messagesStream = FirebaseFirestore.instance
        .collection('government_messages')
        .orderBy('createdAt', descending: true)
        .snapshots();

    return Scaffold(
      appBar: AppBar(title: const Text('Inbox')),
      body: StreamBuilder<QuerySnapshot>(
        stream: messagesStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No messages yet'));
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final subject = data['subject'] ?? 'No subject';
              final message = data['message'] ?? 'No content';
              final senderUid = data['userId'] ?? '';
              final timestamp = data['createdAt'] as Timestamp?;

              return FutureBuilder<String>(
                future: _getSenderEmail(senderUid),
                builder: (context, emailSnap) {
                  final senderEmail = emailSnap.data ?? 'Loading...';

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: ExpansionTile(
                      leading: const Icon(Icons.mark_email_unread),
                      title: Text(subject, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(senderEmail),
                          if (timestamp != null)
                            Text(
                              timestamp.toDate().toLocal().toString(),
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                        ],
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                          child: Text(message),
                        ),
                        StreamBuilder<QuerySnapshot>(
                          stream: doc.reference.collection('replies').orderBy('timestamp').snapshots(),
                          builder: (context, replySnap) {
                            if (!replySnap.hasData || replySnap.data!.docs.isEmpty) {
                              return const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text('No replies yet'),
                              );
                            }
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: replySnap.data!.docs.map((replyDoc) {
                                final reply = replyDoc['message'] ?? '';
                                final time = (replyDoc['timestamp'] as Timestamp?)?.toDate().toLocal();
                                return ListTile(
                                  leading: const Icon(Icons.reply, color: Colors.green),
                                  title: Text(reply),
                                  subtitle: time != null ? Text(time.toString()) : null,
                                );
                              }).toList(),
                            );
                          },
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => _replyToMessage(context, doc.reference),
                            child: const Text('Reply'),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}