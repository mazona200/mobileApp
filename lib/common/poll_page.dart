import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/poll_model.dart';

class PollPage extends StatefulWidget {
  final String pollId;

  const PollPage({super.key, required this.pollId});

  @override
  State<PollPage> createState() => _PollPageState();
}

class _PollPageState extends State<PollPage> {
  Poll? poll;
  String? selectedOption;
  bool isLoading = true;
  bool isSubmitting = false;
  bool hasVoted = false;
  String? errorMessage;
  User? currentUser;

  @override
  void initState() {
    super.initState();

    // Listen to auth state changes and update currentUser + poll accordingly
    FirebaseAuth.instance.authStateChanges().listen((user) async {
      if (mounted) {
        setState(() {
          currentUser = user;
          hasVoted = false; // reset voting status on user change
          selectedOption = null;
        });
        await fetchPoll();
      }
    });

    // Initial fetch (in case user is already signed in)
    fetchPoll();
  }

  Future<void> fetchPoll() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // Refresh current user before fetching poll to get latest
      await FirebaseAuth.instance.currentUser?.reload();
      currentUser = FirebaseAuth.instance.currentUser;

      print('🔄 Fetching poll, current user: ${currentUser?.email} (${currentUser?.uid})');

      final doc = await FirebaseFirestore.instance
          .collection('polls')
          .doc(widget.pollId)
          .get();

      if (!doc.exists) {
        setState(() {
          errorMessage = 'Poll not found';
        });
        if (mounted) Navigator.pop(context);
        return;
      }

      setState(() {
        poll = Poll.fromDoc(doc);
      });

      if (currentUser != null) {
        await checkVoteStatus();
      } else {
        setState(() {
          hasVoted = false;
          selectedOption = null;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error fetching poll: $e';
      });
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> checkVoteStatus() async {
    if (currentUser == null || poll == null) return;

    try {
      final voteDoc = await FirebaseFirestore.instance
          .collection('polls')
          .doc(poll!.id)
          .collection('votes')
          .doc(currentUser!.uid)
          .get();

      if (voteDoc.exists) {
        setState(() {
          hasVoted = true;
          selectedOption = voteDoc['option'];
        });
      } else {
        setState(() {
          hasVoted = false;
          selectedOption = null;
        });
      }
    } catch (e) {
      debugPrint('Error checking vote status: $e');
    }
  }

  Future<void> vote() async {
    // Refresh currentUser before voting
    await FirebaseAuth.instance.currentUser?.reload();
    currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to vote')),
      );
      return;
    }

    if (selectedOption == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an option before voting')),
      );
      return;
    }

    if (hasVoted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You have already voted')),
      );
      return;
    }

    setState(() => isSubmitting = true);

    final pollRef = FirebaseFirestore.instance.collection('polls').doc(poll!.id);
    final voteRef = pollRef.collection('votes').doc(currentUser!.uid);

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final voteDoc = await transaction.get(voteRef);
        final freshSnap = await transaction.get(pollRef);

        if (voteDoc.exists) {
          throw Exception('You have already voted');
        }

        Map<String, int> freshVotes = {};
        if (freshSnap.data() != null && freshSnap.data()!.containsKey('votes')) {
          freshVotes = Map<String, int>.from(freshSnap['votes']);
        } else {
          freshVotes = {for (var opt in poll!.options) opt: 0};
        }

        freshVotes[selectedOption!] = (freshVotes[selectedOption!] ?? 0) + 1;

        transaction.set(voteRef, {
          'option': selectedOption,
          'userId': currentUser!.uid,
          'timestamp': FieldValue.serverTimestamp(),
        });
        transaction.update(pollRef, {'votes': freshVotes});
      });

      setState(() => hasVoted = true);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vote submitted successfully!')),
      );

      await fetchPoll();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting vote: $e')),
      );
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(errorMessage!),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: fetchPoll,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (poll == null) {
      return const Scaffold(
        body: Center(child: Text('Poll not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(poll!.question)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...poll!.options.map((opt) => RadioListTile<String>(
                    title: Text(opt),
                    value: opt,
                    groupValue: selectedOption,
                    onChanged: (hasVoted || currentUser == null)
                        ? null
                        : (val) => setState(() => selectedOption = val),
                  )),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (hasVoted || isSubmitting || currentUser == null)
                      ? null
                      : vote,
                  child: isSubmitting
                      ? const CircularProgressIndicator()
                      : Text(hasVoted ? 'Already Voted' : 'Vote'),
                ),
              ),
              if (currentUser == null) ...[
                const SizedBox(height: 10),
                const Text(
                  'You must be signed in to vote',
                  style: TextStyle(color: Colors.red),
                ),
              ],
              const SizedBox(height: 20),
              const Divider(),
              const Text(
                'Results',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              ...poll!.options.map((opt) {
                final votes = poll!.votes[opt] ?? 0;
                final totalVotes =
                    poll!.votes.values.fold(0, (sum, count) => sum + count);
                final percent = totalVotes > 0 ? (votes * 100 / totalVotes) : 0;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(opt),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: totalVotes > 0 ? votes / totalVotes : 0,
                        minHeight: 8,
                      ),
                      const SizedBox(height: 4),
                      Text('$votes votes (${percent.toStringAsFixed(1)}%)'),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}