import 'package:cloud_firestore/cloud_firestore.dart';

class Poll {
  final String id;
  final String question;
  final List<String> options;
  final Map<String, int> votes;
  final DateTime? createdAt;
  final DateTime? expiresAt;
  final bool isActive;
  final String? creatorId;
  final String? description;

  Poll({
    required this.id,
    required this.question,
    required this.options,
    required this.votes,
    this.createdAt,
    this.expiresAt,
    this.isActive = true,
    this.creatorId,
    this.description,
  });

  factory Poll.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return Poll(
      id: doc.id,
      question: data['question']?.toString() ?? 'No question provided',
      options: _parseStringList(data['options']),
      votes: _parseVotesMap(data['votes']),
      createdAt: _parseTimestamp(data['createdAt']),
      expiresAt: _parseTimestamp(data['expiresAt']),
      isActive: data['isActive'] as bool? ?? true,
      creatorId: data['creatorId']?.toString(),
      description: data['description']?.toString(),
    );
  }

  static List<String> _parseStringList(dynamic data) {
    if (data is List) {
      return data.map((e) => e.toString()).toList();
    }
    return <String>[];
  }

  static Map<String, int> _parseVotesMap(dynamic data) {
    final votes = <String, int>{};
    if (data is Map) {
      data.forEach((key, value) {
        final keyStr = key.toString();
        votes[keyStr] = (value is int) 
            ? value 
            : (value is String) 
                ? int.tryParse(value) ?? 0 
                : 0;
      });
    }
    return votes;
  }

  static DateTime? _parseTimestamp(dynamic data) {
    if (data is Timestamp) return data.toDate();
    if (data is DateTime) return data;
    if (data is String) return DateTime.tryParse(data);
    return null;
  }

  int get totalVotes => votes.values.fold(0, (sum, count) => sum + count);
  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);

  Map<String, dynamic> toMap() {
    return {
      'question': question,
      'options': options,
      'votes': votes,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
      'isActive': isActive,
      'creatorId': creatorId,
      'description': description,
    };
  }
}