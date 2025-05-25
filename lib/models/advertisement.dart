import 'package:cloud_firestore/cloud_firestore.dart';

class Advertisement {
  final String id;
  final String title;
  final String description;
  final String businessName;
  final String businessType;
  final List<String> imageUrls;
  final DateTime startDate;
  final DateTime endDate;
  final String createdBy;
  final DateTime createdAt;
  final bool isApproved;
  final String? rejectionReason;
  final Map<String, dynamic> contactInfo;
  final Map<String, dynamic> location;

  Advertisement({
    required this.id,
    required this.title,
    required this.description,
    required this.businessName,
    required this.businessType,
    required this.imageUrls,
    required this.startDate,
    required this.endDate,
    required this.createdBy,
    required this.createdAt,
    this.isApproved = false,
    this.rejectionReason,
    required this.contactInfo,
    required this.location,
  });

  factory Advertisement.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Advertisement(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      businessName: data['businessName'] ?? '',
      businessType: data['businessType'] ?? '',
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      createdBy: data['createdBy'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      isApproved: data['isApproved'] ?? false,
      rejectionReason: data['rejectionReason'],
      contactInfo: Map<String, dynamic>.from(data['contactInfo'] ?? {}),
      location: Map<String, dynamic>.from(data['location'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'businessName': businessName,
      'businessType': businessType,
      'imageUrls': imageUrls,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'isApproved': isApproved,
      'rejectionReason': rejectionReason,
      'contactInfo': contactInfo,
      'location': location,
    };
  }

  bool get isActive => 
      isApproved && 
      DateTime.now().isAfter(startDate) && 
      DateTime.now().isBefore(endDate);
} 