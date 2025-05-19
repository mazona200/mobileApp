import 'package:cloud_firestore/cloud_firestore.dart';

class Announcement {
  final String id;
  final String title;
  final String content;
  final DateTime startDate;
  final DateTime endDate;
  final String category;
  final List<String> imageUrls;
  final List<String> fileUrls;
  final DateTime createdAt;
  final String createdBy;
  final List<Comment> comments;

  Announcement({
    required this.id,
    required this.title,
    required this.content,
    required this.startDate,
    required this.endDate,
    required this.category,
    this.imageUrls = const [],
    this.fileUrls = const [],
    required this.createdAt,
    required this.createdBy,
    this.comments = const [],
  });

  factory Announcement.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Announcement(
      id: doc.id,
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      category: data['category'] ?? '',
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      fileUrls: List<String>.from(data['fileUrls'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      createdBy: data['createdBy'] ?? '',
      comments: (data['comments'] as List<dynamic>? ?? [])
          .map((comment) => Comment.fromMap(comment))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'content': content,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'category': category,
      'imageUrls': imageUrls,
      'fileUrls': fileUrls,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
      'comments': comments.map((comment) => comment.toMap()).toList(),
    };
  }
}

class Comment {
  final String id;
  final String content;
  final String userId;
  final String userName;
  final bool isAnonymous;
  final DateTime createdAt;

  Comment({
    required this.id,
    required this.content,
    required this.userId,
    required this.userName,
    this.isAnonymous = false,
    required this.createdAt,
  });

  factory Comment.fromMap(Map<String, dynamic> map) {
    return Comment(
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