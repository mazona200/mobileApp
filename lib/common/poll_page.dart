import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobile_project/models/poll_model.dart';
import '../components/role_protected_page.dart';

class PollPage extends StatefulWidget {
  final String pollId;

  const PollPage({super.key, required this.pollId});

  @override
  State<PollPage> createState() => _PollPageState();
}

class _PollPageState extends State<PollPage> {
  Poll? poll;
  String? selectedOption;
  bool isLoading = false;

  Future<void> fetchPoll() async {
    setState(() => isLoading = true);
    try {
      final doc = await FirebaseFirestore.instance.collection('polls').doc(widget.pollId).get();
      if (doc.exists) {
        setState(() {
          poll = Poll.fromDoc(doc);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Poll not found')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching poll: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> vote() async {
    if (selectedOption == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an option before voting')),
      );
      return;
    }

    final pollRef = FirebaseFirestore.instance.collection('polls').doc(poll!.id);

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final freshSnap = await transaction.get(pollRef);
        final freshVotes = Map<String, int>.from(freshSnap['votes'] ?? {});
        freshVotes[selectedOption!] = (freshVotes[selectedOption!] ?? 0) + 1;
        transaction.update(pollRef, {'votes': freshVotes});
      });

      await fetchPoll(); // Refresh poll data after vote
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting vote: $e')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    fetchPoll();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (poll == null) {
      return const Scaffold(
        body: Center(child: Text('Loading poll...')),
      );
    }

    return RoleProtectedPage(
      requiredRole: "all_roles",
      child: Scaffold(
        appBar: AppBar(title: const Text('Poll')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                poll!.question,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ...poll!.options.map((opt) => RadioListTile<String>(
                    title: Text(opt),
                    value: opt,
                    groupValue: selectedOption,
                    onChanged: (val) => setState(() => selectedOption = val),
                  )),
              ElevatedButton(
                onPressed: vote,
                child: const Text('Vote'),
              ),
              const SizedBox(height: 20),
              const Divider(),
              const Text(
                'Results',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              ...poll!.options.map((opt) {
                final votes = poll!.votes[opt] ?? 0;
                return ListTile(
                  title: Text(opt),
                  trailing: Text('$votes votes'),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
