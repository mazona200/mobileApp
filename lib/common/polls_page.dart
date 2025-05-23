import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/poll_model.dart';
import 'poll_page.dart';

class PollsPage extends StatelessWidget {
  const PollsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Current Polls'),
        centerTitle: true,
      ),
      body: _buildPollsList(),
    );
  }

  Widget _buildPollsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('polls')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final polls = snapshot.data?.docs.map((doc) {
          try {
            return Poll.fromDoc(doc);
          } catch (e) {
            print('Error parsing poll ${doc.id}: $e');
            return null;
          }
        }).whereType<Poll>().toList() ?? [];

        if (polls.isEmpty) {
          return const Center(
            child: Text(
              'No active polls available',
              style: TextStyle(fontSize: 16),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: polls.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final poll = polls[index];
            return _buildPollCard(context, poll);
          },
        );
      },
    );
  }

  Widget _buildPollCard(BuildContext context, Poll poll) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PollPage(pollId: poll.id),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                poll.question,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${poll.options.length} options',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  Text(
                    '${poll.totalVotes} votes',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
              if (poll.createdAt != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    'Created: ${poll.createdAt!.toLocal().toString().split(' ')[0]}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}