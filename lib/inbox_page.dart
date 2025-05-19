import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class InboxPage extends StatelessWidget {
  const InboxPage({super.key});

  @override
  Widget build(BuildContext context) {
    final messagesStream = FirebaseFirestore.instance
        .collection('messages')
        .where('recipientRole', isEqualTo: 'government')  // Filter messages for gov
        .orderBy('timestamp', descending: true)
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

          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data()! as Map<String, dynamic>;
              final title = data['title'] ?? 'No title';
              final content = data['content'] ?? '';
              final timestamp = data['timestamp'] as Timestamp?;
              final isRead = data['isRead'] ?? false;

              return ListTile(
                leading: Icon(
                  isRead ? Icons.mark_email_read : Icons.mark_email_unread,
                  color: isRead ? Colors.grey : Colors.blue,
                ),
                title: Text(title),
                subtitle: Text(content, maxLines: 2, overflow: TextOverflow.ellipsis),
                trailing: timestamp != null
                    ? Text(
                        TimeOfDay.fromDateTime(timestamp.toDate()).format(context),
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      )
                    : null,
                onTap: () async {
                  // Optional: mark as read
                  if (!isRead) {
                    await doc.reference.update({'isRead': true});
                  }
                  // Show message details or do something else
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: Text(title),
                      content: Text(content),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Close'),
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
