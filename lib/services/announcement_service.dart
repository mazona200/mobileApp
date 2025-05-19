import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../models/announcement.dart';

class AnnouncementService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Create a new announcement
  Future<Announcement> createAnnouncement(Announcement announcement, List<File>? images, List<File>? files) async {
    try {
      // Upload images if any
      List<String> imageUrls = [];
      if (images != null && images.isNotEmpty) {
        for (File image in images) {
          String fileName = 'announcements/${DateTime.now().millisecondsSinceEpoch}_${image.path.split('/').last}';
          Reference ref = _storage.ref().child(fileName);
          await ref.putFile(image);
          String url = await ref.getDownloadURL();
          imageUrls.add(url);
        }
      }

      // Upload files if any
      List<String> fileUrls = [];
      if (files != null && files.isNotEmpty) {
        for (File file in files) {
          String fileName = 'announcements/${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
          Reference ref = _storage.ref().child(fileName);
          await ref.putFile(file);
          String url = await ref.getDownloadURL();
          fileUrls.add(url);
        }
      }

      // Create announcement document
      DocumentReference docRef = await _firestore.collection('announcements').add({
        ...announcement.toMap(),
        'imageUrls': imageUrls,
        'fileUrls': fileUrls,
      });

      // Get the created announcement
      DocumentSnapshot doc = await docRef.get();
      return Announcement.fromFirestore(doc);
    } catch (e) {
      throw Exception('Failed to create announcement: $e');
    }
  }

  // Get all announcements
  Stream<List<Announcement>> getAnnouncements() {
    return _firestore
        .collection('announcements')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Announcement.fromFirestore(doc)).toList();
    });
  }

  // Get announcement by ID
  Future<Announcement> getAnnouncement(String id) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('announcements').doc(id).get();
      return Announcement.fromFirestore(doc);
    } catch (e) {
      throw Exception('Failed to get announcement: $e');
    }
  }

  // Update announcement
  Future<void> updateAnnouncement(String id, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('announcements').doc(id).update(data);
    } catch (e) {
      throw Exception('Failed to update announcement: $e');
    }
  }

  // Delete announcement
  Future<void> deleteAnnouncement(String id) async {
    try {
      // Get announcement to delete associated files
      DocumentSnapshot doc = await _firestore.collection('announcements').doc(id).get();
      Announcement announcement = Announcement.fromFirestore(doc);

      // Delete images from storage
      for (String imageUrl in announcement.imageUrls) {
        Reference ref = _storage.refFromURL(imageUrl);
        await ref.delete();
      }

      // Delete files from storage
      for (String fileUrl in announcement.fileUrls) {
        Reference ref = _storage.refFromURL(fileUrl);
        await ref.delete();
      }

      // Delete announcement document
      await _firestore.collection('announcements').doc(id).delete();
    } catch (e) {
      throw Exception('Failed to delete announcement: $e');
    }
  }

  // Add comment to announcement
  Future<void> addComment(String announcementId, Comment comment) async {
    try {
      await _firestore.collection('announcements').doc(announcementId).update({
        'comments': FieldValue.arrayUnion([comment.toMap()]),
      });
    } catch (e) {
      throw Exception('Failed to add comment: $e');
    }
  }

  // Delete comment from announcement
  Future<void> deleteComment(String announcementId, Comment comment) async {
    try {
      await _firestore.collection('announcements').doc(announcementId).update({
        'comments': FieldValue.arrayRemove([comment.toMap()]),
      });
    } catch (e) {
      throw Exception('Failed to delete comment: $e');
    }
  }

  // Get announcements by category
  Stream<List<Announcement>> getAnnouncementsByCategory(String category) {
    return _firestore
        .collection('announcements')
        .where('category', isEqualTo: category)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Announcement.fromFirestore(doc)).toList();
    });
  }

  // Get active announcements (between start and end date)
  Stream<List<Announcement>> getActiveAnnouncements() {
    DateTime now = DateTime.now();
    return _firestore
        .collection('announcements')
        .where('startDate', isLessThanOrEqualTo: now)
        .where('endDate', isGreaterThanOrEqualTo: now)
        .orderBy('startDate', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Announcement.fromFirestore(doc)).toList();
    });
  }
} 