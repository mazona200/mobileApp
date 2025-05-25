import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../models/advertisement.dart';

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
    DateTime now = DateTime.now();
    return _firestore
        .collection('advertisements')
        .where('isApproved', isEqualTo: true)
        .where('startDate', isLessThanOrEqualTo: now)
        .where('endDate', isGreaterThanOrEqualTo: now)
        .orderBy('startDate', descending: true)
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
      await _firestore.collection('advertisements').doc(id).update({
        'isApproved': true,
        'rejectionReason': null,
      });
    } catch (e) {
      throw Exception('Failed to approve advertisement: $e');
    }
  }

  // Reject advertisement
  Future<void> rejectAdvertisement(String id, String reason) async {
    try {
      await _firestore.collection('advertisements').doc(id).update({
        'isApproved': false,
        'rejectionReason': reason,
      });
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

