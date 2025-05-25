import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../models/advertisement.dart';
import 'push_notifications.dart';

class AdvertisementService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Create a new advertisement
  Future<Advertisement> createAdvertisement(Advertisement advertisement, List<File> images) async {
    try {
      // Upload images
      List<String> imageUrls = [];
      for (File image in images) {
        String fileName = 'advertisements/${DateTime.now().millisecondsSinceEpoch}_${image.path.split('/').last}';
        Reference ref = _storage.ref().child(fileName);
        await ref.putFile(image);
        String url = await ref.getDownloadURL();
        imageUrls.add(url);
      }

      // Create advertisement document
      DocumentReference docRef = await _firestore.collection('advertisements').add({
        ...advertisement.toMap(),
        'imageUrls': imageUrls,
      });

      // Send push notification to government for review
      try {
        await PushNotificationService.notifyNewAdvertisementForReview(
          adId: docRef.id,
          title: advertisement.title,
          businessName: advertisement.businessName,
        );
      } catch (e) {
        print('Failed to send advertisement review notification: $e');
      }

      // Get the created advertisement
      DocumentSnapshot doc = await docRef.get();
      return Advertisement.fromFirestore(doc);
    } catch (e) {
      throw Exception('Failed to create advertisement: $e');
    }
  }

  // Get all advertisements
  Stream<List<Advertisement>> getAdvertisements() {
    return _firestore
        .collection('advertisements')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Advertisement.fromFirestore(doc)).toList();
    });
  }

  // Get active advertisements
  Stream<List<Advertisement>> getActiveAdvertisements() {
    // Simplify the query to avoid complex index requirements
    // We'll filter by approval status and do date filtering client-side
    return _firestore
        .collection('advertisements')
        .where('isApproved', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      try {
        final DateTime now = DateTime.now();
        return snapshot.docs
            .map((doc) => Advertisement.fromFirestore(doc))
            .where((ad) => 
                ad.startDate.isBefore(now.add(const Duration(days: 1))) && 
                ad.endDate.isAfter(now.subtract(const Duration(days: 1))))
            .toList();
      } catch (e) {
        print('Error filtering advertisements: $e');
        // Return all approved ads if filtering fails
        return snapshot.docs
            .map((doc) => Advertisement.fromFirestore(doc))
            .toList();
      }
    });
  }

  // Simple method to get all approved advertisements (fallback)
  Stream<List<Advertisement>> getApprovedAdvertisements() {
    return _firestore
        .collection('advertisements')
        .where('isApproved', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Advertisement.fromFirestore(doc)).toList();
    });
  }

  // Get pending advertisements
  Stream<List<Advertisement>> getPendingAdvertisements() {
    return _firestore
        .collection('advertisements')
        .where('isApproved', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Advertisement.fromFirestore(doc)).toList();
    });
  }

  // Get advertisement by ID
  Future<Advertisement> getAdvertisement(String id) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('advertisements').doc(id).get();
      return Advertisement.fromFirestore(doc);
    } catch (e) {
      throw Exception('Failed to get advertisement: $e');
    }
  }

  // Update advertisement
  Future<void> updateAdvertisement(String id, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('advertisements').doc(id).update(data);
    } catch (e) {
      throw Exception('Failed to update advertisement: $e');
    }
  }

  // Delete advertisement
  Future<void> deleteAdvertisement(String id) async {
    try {
      // Get advertisement to delete associated images
      DocumentSnapshot doc = await _firestore.collection('advertisements').doc(id).get();
      Advertisement advertisement = Advertisement.fromFirestore(doc);

      // Delete images from storage
      for (String imageUrl in advertisement.imageUrls) {
        Reference ref = _storage.refFromURL(imageUrl);
        await ref.delete();
      }

      // Delete advertisement document
      await _firestore.collection('advertisements').doc(id).delete();
    } catch (e) {
      throw Exception('Failed to delete advertisement: $e');
    }
  }

  // Approve advertisement
  Future<void> approveAdvertisement(String id) async {
    try {
      // Get advertisement details first
      DocumentSnapshot doc = await _firestore.collection('advertisements').doc(id).get();
      Advertisement advertisement = Advertisement.fromFirestore(doc);

      await _firestore.collection('advertisements').doc(id).update({
        'isApproved': true,
        'rejectionReason': null,
      });

      // Send push notification to advertiser
      try {
        await PushNotificationService.notifyAdvertisementStatus(
          advertiserId: advertisement.createdBy,
          adTitle: advertisement.title,
          isApproved: true,
        );
      } catch (e) {
        print('Failed to send advertisement approval notification: $e');
      }
    } catch (e) {
      throw Exception('Failed to approve advertisement: $e');
    }
  }

  // Reject advertisement
  Future<void> rejectAdvertisement(String id, String reason) async {
    try {
      // Get advertisement details first
      DocumentSnapshot doc = await _firestore.collection('advertisements').doc(id).get();
      Advertisement advertisement = Advertisement.fromFirestore(doc);

      await _firestore.collection('advertisements').doc(id).update({
        'isApproved': false,
        'rejectionReason': reason,
      });

      // Send push notification to advertiser
      try {
        await PushNotificationService.notifyAdvertisementStatus(
          advertiserId: advertisement.createdBy,
          adTitle: advertisement.title,
          isApproved: false,
          rejectionReason: reason,
        );
      } catch (e) {
        print('Failed to send advertisement rejection notification: $e');
      }
    } catch (e) {
      throw Exception('Failed to reject advertisement: $e');
    }
  }

  // Get advertisements by business type
  Stream<List<Advertisement>> getAdvertisementsByBusinessType(String businessType) {
    return _firestore
        .collection('advertisements')
        .where('businessType', isEqualTo: businessType)
        .where('isApproved', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Advertisement.fromFirestore(doc)).toList();
    });
  }

  // Get advertisements by advertiser
  Stream<List<Advertisement>> getAdvertisementsByAdvertiser(String advertiserId) {
    return _firestore
        .collection('advertisements')
        .where('createdBy', isEqualTo: advertiserId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Advertisement.fromFirestore(doc)).toList();
    });
  }
}