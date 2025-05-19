import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PollResultsPage extends StatefulWidget {
  final String pollId;
  final String question;

  const PollResultsPage({super.key, required this.pollId, required this.question});

  @override
  State<PollResultsPage> createState() => _PollResultsPageState();
}

class _PollResultsPageState extends State<PollResultsPage> {
  Map<String, int> results = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchResults();
  }

  Future<void> fetchResults() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('polls').doc(widget.pollId).get();

      if (!doc.exists) {
        setState(() {
          results = {};
          isLoading = false;
        });
        return;
      }

      final data = doc.data()!;
      final votesMap = Map<String, dynamic>.from(data['votes'] ?? {});

      setState(() {
        results = votesMap.map((key, value) => MapEntry(key, (value ?? 0) as int));
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        results = {};
        isLoading = false;
      });
      // Optional: handle error, show snackbar, etc.
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (results.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text("Results")),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Center(child: Text("No votes yet for: ${widget.question}")),
        ),
      );
    }

    final totalVotes = results.values.fold<int>(0, (sum, val) => sum + val);

    return Scaffold(
      appBar: AppBar(title: const Text("Results")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.question,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ...results.entries.map((entry) {
              final percent = totalVotes == 0 ? 0 : (entry.value * 100 / totalVotes).round();
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      flex: percent,
                      child: Container(height: 20, color: Colors.blue),
                    ),
                    Expanded(
                      flex: 100 - percent,
                      child: Container(),
                    ),
                    const SizedBox(width: 10),
                    Text('${entry.key}: $percent% (${entry.value} votes)'),
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
