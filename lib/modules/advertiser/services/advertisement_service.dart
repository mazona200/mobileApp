import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/advertisement.dart';

class AdvertisementService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Create new advertisement
  Future<Advertisement> createAdvertisement({
    required String title,
    required String description,
    required File image,
    required String category,
    String? businessLocation,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No user logged in');

      // Upload image to Firebase Storage
      final imageRef = _storage.ref().child('advertisements/${user.uid}/${DateTime.now().millisecondsSinceEpoch}.jpg');
      await imageRef.putFile(image);
      final imageUrl = await imageRef.getDownloadURL();

      // Create advertisement document
      final docRef = _firestore.collection('advertisements').doc();
      final advertisement = Advertisement(
        id: docRef.id,
        advertiserId: user.uid,
        title: title,
        description: description,
        imageUrl: imageUrl,
        category: category,
        businessLocation: businessLocation,
        status: AdvertisementStatus.pending,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await docRef.set(advertisement.toMap());
      return advertisement;
    } catch (e) {
      throw Exception('Failed to create advertisement: ${e.toString()}');
    }
  }

  // Get advertiser's advertisements
  Stream<List<Advertisement>> getAdvertiserAdvertisements({
    AdvertisementStatus? status,
  }) {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No user logged in');

      Query query = _firestore
          .collection('advertisements')
          .where('advertiserId', isEqualTo: user.uid);

      if (status != null) {
        query = query.where('status', isEqualTo: status.toString().split('.').last);
      }

      return query.snapshots().map((snapshot) {
        return snapshot.docs
            .map((doc) => Advertisement.fromFirestore(doc))
            .toList();
      });
    } catch (e) {
      throw Exception('Failed to get advertisements: ${e.toString()}');
    }
  }

  // Update advertisement
  Future<void> updateAdvertisement({
    required String id,
    String? title,
    String? description,
    File? image,
    String? category,
    String? businessLocation,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No user logged in');

      final docRef = _firestore.collection('advertisements').doc(id);
      final doc = await docRef.get();

      if (!doc.exists) throw Exception('Advertisement not found');
      if (doc.data()?['advertiserId'] != user.uid) {
        throw Exception('Not authorized to update this advertisement');
      }

      final updates = <String, dynamic>{
        'updatedAt': Timestamp.now(),
      };

      if (title != null) updates['title'] = title;
      if (description != null) updates['description'] = description;
      if (category != null) updates['category'] = category;
      if (businessLocation != null) updates['businessLocation'] = businessLocation;

      if (image != null) {
        // Delete old image
        final oldImageUrl = doc.data()?['imageUrl'];
        if (oldImageUrl != null) {
          try {
            await _storage.refFromURL(oldImageUrl).delete();
          } catch (e) {
            print('Failed to delete old image: $e');
          }
        }

        // Upload new image
        final imageRef = _storage.ref().child('advertisements/${user.uid}/${DateTime.now().millisecondsSinceEpoch}.jpg');
        await imageRef.putFile(image);
        final imageUrl = await imageRef.getDownloadURL();
        updates['imageUrl'] = imageUrl;
      }

      await docRef.update(updates);
    } catch (e) {
      throw Exception('Failed to update advertisement: ${e.toString()}');
    }
  }

  // Delete advertisement
  Future<void> deleteAdvertisement(String id) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No user logged in');

      final docRef = _firestore.collection('advertisements').doc(id);
      final doc = await docRef.get();

      if (!doc.exists) throw Exception('Advertisement not found');
      if (doc.data()?['advertiserId'] != user.uid) {
        throw Exception('Not authorized to delete this advertisement');
      }

      // Delete image from storage
      final imageUrl = doc.data()?['imageUrl'];
      if (imageUrl != null) {
        try {
          await _storage.refFromURL(imageUrl).delete();
        } catch (e) {
          print('Failed to delete image: $e');
        }
      }

      await docRef.delete();
    } catch (e) {
      throw Exception('Failed to delete advertisement: ${e.toString()}');
    }
  }

  // Check for profanity in text (simple implementation)
  bool containsProfanity(String text) {
    final profanityWords = [
      'badword1',
      'badword2',
      // Add more words as needed
    ];

    final words = text.toLowerCase().split(' ');
    return words.any((word) => profanityWords.contains(word));
  }
} 