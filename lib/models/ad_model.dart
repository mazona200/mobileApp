import 'package:cloud_firestore/cloud_firestore.dart';

class Ad {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final Timestamp createdAt;
  final String status;

  Ad({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.createdAt,
    required this.status,
  });

  factory Ad.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Ad(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      createdAt: data['createdAt'] ?? Timestamp.now(),
      status: data['status'] ?? 'inactive',
    );
  }
}
