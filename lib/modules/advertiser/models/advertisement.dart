import 'package:cloud_firestore/cloud_firestore.dart';

enum AdvertisementStatus {
  pending,
  approved,
  rejected
}

class Advertisement {
  final String id;
  final String advertiserId;
  final String title;
  final String description;
  final String imageUrl;
  final String category;
  final String? businessLocation;
  final AdvertisementStatus status;
  final String? adminFeedback;
  final DateTime createdAt;
  final DateTime updatedAt;

  Advertisement({
    required this.id,
    required this.advertiserId,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.category,
    this.businessLocation,
    required this.status,
    this.adminFeedback,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Advertisement.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Advertisement(
      id: doc.id,
      advertiserId: data['advertiserId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      category: data['category'] ?? '',
      businessLocation: data['businessLocation'],
      status: AdvertisementStatus.values.firstWhere(
        (e) => e.toString() == 'AdvertisementStatus.${data['status']}',
        orElse: () => AdvertisementStatus.pending,
      ),
      adminFeedback: data['adminFeedback'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'advertiserId': advertiserId,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'category': category,
      'businessLocation': businessLocation,
      'status': status.toString().split('.').last,
      'adminFeedback': adminFeedback,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  Advertisement copyWith({
    String? id,
    String? advertiserId,
    String? title,
    String? description,
    String? imageUrl,
    String? category,
    String? businessLocation,
    AdvertisementStatus? status,
    String? adminFeedback,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Advertisement(
      id: id ?? this.id,
      advertiserId: advertiserId ?? this.advertiserId,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      businessLocation: businessLocation ?? this.businessLocation,
      status: status ?? this.status,
      adminFeedback: adminFeedback ?? this.adminFeedback,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
} 