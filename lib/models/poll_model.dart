import 'package:cloud_firestore/cloud_firestore.dart';

class Poll {
  final String id;
  final String question;
  final List<String> options;
  final Map<String, int> votes;

  Poll({
    required this.id,
    required this.question,
    required this.options,
    required this.votes,
  });

  factory Poll.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return Poll(
      id: doc.id,
      question: data['question'] ?? '',
      options: List<String>.from(data['options'] ?? []),
      votes: Map<String, int>.from(
        (data['votes'] ?? {}).map((key, value) => MapEntry(key.toString(), value as int)),
      ),
    );
  }
}
