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
  Map<String, int> optionResults = {};
  Map<String, int> roleResults = {};
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
          optionResults = {};
          roleResults = {};
          isLoading = false;
        });
        return;
      }

      final data = doc.data()!;
      final votesMap = Map<String, dynamic>.from(data['votes'] ?? {});
      final parsedVotes = votesMap.map((key, value) => MapEntry(key, (value ?? 0) as int));

      final subVotesSnap = await doc.reference.collection('votes').get();
      final Map<String, int> roles = {};
      for (var voteDoc in subVotesSnap.docs) {
        final role = voteDoc['role'] ?? 'unknown';
        roles[role] = (roles[role] ?? 0) + 1;
      }

      setState(() {
        optionResults = parsedVotes;
        roleResults = roles;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        optionResults = {};
        roleResults = {};
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading results: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (optionResults.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text("Results")),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Center(child: Text("No votes yet for: ${widget.question}")),
        ),
      );
    }

    final totalVotes = optionResults.values.fold<int>(0, (sum, val) => sum + val);

    return Scaffold(
      appBar: AppBar(title: const Text("Results")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.question, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ...optionResults.entries.map((entry) {
              final percent = totalVotes == 0 ? 0 : (entry.value * 100 / totalVotes).round();
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${entry.key}: $percent% (${entry.value} votes)'),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: totalVotes == 0 ? 0 : entry.value / totalVotes,
                      backgroundColor: Colors.grey.shade300,
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                      minHeight: 8,
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 30),
            if (roleResults.isNotEmpty) ...[
              const Text("Votes by Role", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              ...roleResults.entries.map((entry) => Text('${entry.key.capitalize()}: ${entry.value}')),
            ],
          ],
        ),
      ),
    );
  }
}

extension StringCasingExtension on String {
  String capitalize() => isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
}