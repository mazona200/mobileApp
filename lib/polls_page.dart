import 'package:flutter/material.dart';
import 'poll_results_page.dart'; // will be step 2

class PollsPage extends StatelessWidget {
  const PollsPage({super.key});

  final List<Map<String, dynamic>> samplePolls = const [
    {
      'question': 'Should we build a new park?',
      'id': 'poll1',
    },
    {
      'question': 'Do you support increasing public transport funding?',
      'id': 'poll2',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Polls")),
      body: ListView.builder(
        itemCount: samplePolls.length,
        itemBuilder: (context, index) {
          final poll = samplePolls[index];
          return ListTile(
            title: Text(poll['question']),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PollResultsPage(pollId: poll['id'], question: poll['question']),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
