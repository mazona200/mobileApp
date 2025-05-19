import 'package:flutter/material.dart';

class PollResultsPage extends StatelessWidget {
  final String pollId;
  final String question;

  const PollResultsPage({super.key, required this.pollId, required this.question});

  @override
  Widget build(BuildContext context) {
    // Simulated result data
    final Map<String, int> results = {
      'Yes': 60,
      'No': 40,
    };

    return Scaffold(
      appBar: AppBar(title: Text("Results")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(question, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ...results.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Expanded(flex: entry.value, child: Container(height: 20, color: Colors.blue)),
                    const SizedBox(width: 10),
                    Text('${entry.key}: ${entry.value}%'),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}
