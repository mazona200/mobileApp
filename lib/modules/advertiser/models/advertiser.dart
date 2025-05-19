import 'package:cloud_firestore/cloud_firestore.dart';

class Advertiser {
  final String id;
  final String email;
  final String businessName;
  final String? phoneNumber;
  final String? businessAddress;
  final bool isVerified;
  final DateTime createdAt;
  final DateTime updatedAt;

  Advertiser({
    required this.id,
    required this.email,
    required this.businessName,
    this.phoneNumber,
    this.businessAddress,
    required this.isVerified,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Advertiser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Advertiser(
      id: doc.id,
      email: data['email'] ?? '',
      businessName: data['businessName'] ?? '',
      phoneNumber: data['phoneNumber'],
      businessAddress: data['businessAddress'],
      isVerified: data['isVerified'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'businessName': businessName,
      'phoneNumber': phoneNumber,
      'businessAddress': businessAddress,
      'isVerified': isVerified,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  Advertiser copyWith({
    String? id,
    String? email,
    String? businessName,
    String? phoneNumber,
    String? businessAddress,
    bool? isVerified,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Advertiser(
      id: id ?? this.id,
      email: email ?? this.email,
      businessName: businessName ?? this.businessName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      businessAddress: businessAddress ?? this.businessAddress,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
} 