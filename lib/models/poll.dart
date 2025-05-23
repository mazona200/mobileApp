import 'package:cloud_firestore/cloud_firestore.dart';

class Poll {
  final String id;
  final String title;
  final String description;
  final DateTime startDate;
  final DateTime endDate;
  final String createdBy;
  final DateTime createdAt;
  final List<PollOption> options;
  final List<PollComment> comments;
  final bool isActive;

  Poll({
    required this.id,
    required this.title,
    required this.description,
    required this.startDate,
    required this.endDate,
    required this.createdBy,
    required this.createdAt,
    required this.options,
    this.comments = const [],
    this.isActive = true,
  });

  factory Poll.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Poll(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      createdBy: data['createdBy'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      options: (data['options'] as List<dynamic>? ?? [])
          .map((option) => PollOption.fromMap(option))
          .toList(),
      comments: (data['comments'] as List<dynamic>? ?? [])
          .map((comment) => PollComment.fromMap(comment))
          .toList(),
      isActive: data['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'options': options.map((option) => option.toMap()).toList(),
      'comments': comments.map((comment) => comment.toMap()).toList(),
      'isActive': isActive,
    };
  }

  int get totalVotes => options.fold(0, (sum, option) => sum + option.votes);
}

class PollOption {
  final String id;
  final String text;
  final int votes;
  final List<String> votedBy;

  PollOption({
    required this.id,
    required this.text,
    this.votes = 0,
    this.votedBy = const [],
  });

  factory PollOption.fromMap(Map<String, dynamic> map) {
    return PollOption(
      id: map['id'] ?? '',
      text: map['text'] ?? '',
      votes: map['votes'] ?? 0,
      votedBy: List<String>.from(map['votedBy'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'votes': votes,
      'votedBy': votedBy,
    };
  }
}

class PollComment {
  final String id;
  final String content;
  final String userId;
  final String userName;
  final bool isAnonymous;
  final DateTime createdAt;

  PollComment({
    required this.id,
    required this.content,
    required this.userId,
    required this.userName,
    this.isAnonymous = false,
    required this.createdAt,
  });

  factory PollComment.fromMap(Map<String, dynamic> map) {
    return PollComment(
      id: map['id'] ?? '',
      content: map['content'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      isAnonymous: map['isAnonymous'] ?? false,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'content': content,
      'userId': userId,
      'userName': userName,
      'isAnonymous': isAnonymous,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
} 