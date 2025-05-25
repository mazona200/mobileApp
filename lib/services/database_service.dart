import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'push_notifications.dart';

class DatabaseService {
  // Firebase instances
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  // ignore: unused_field
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  
  // Collection references
  static final CollectionReference users = _firestore.collection('users');
  static final CollectionReference announcements = _firestore.collection('announcements');
  static final CollectionReference problemReports = _firestore.collection('problem_reports');
  static final CollectionReference governmentMessages = _firestore.collection('government_messages');
  static final CollectionReference polls = _firestore.collection('polls');
  static final CollectionReference emergencyContacts = _firestore.collection('emergency_contacts');
  
  // User methods
  static Future<void> createOrUpdateUser({
    required String uid,
    required String email,
    required String role,
    String? name,
    String? phone,
    String? nationalId,
    String? dateOfBirth,
    String? profession,
    String? gender,
    String? hometown,
  }) async {
    return await users.doc(uid).set({
      'email': email,
      'role': role,
      'name': name ?? '',
      'phone': phone ?? '',
      'nationalId': nationalId ?? '',
      'dateOfBirth': dateOfBirth ?? '',
      'profession': profession ?? '',
      'gender': gender ?? '',
      'hometown': hometown ?? '',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
  
  static Future<Map<String, dynamic>?> getUserData(String uid) async {
    DocumentSnapshot doc = await users.doc(uid).get();
    if (doc.exists) {
      return doc.data() as Map<String, dynamic>?;
    }
    return null;
  }
  
  static Future<Map<String, dynamic>?> getCurrentUserData() async {
    User? user = _auth.currentUser;
    if (user != null) {
      return getUserData(user.uid);
    }
    return null;
  }
  
  // Announcements methods
  static Future<DocumentReference> addAnnouncement({
    required String title,
    required String content,
    required String category,
    String? imageUrl,
    String? authorId,
    String? authorName,
  }) async {
    final docRef = await announcements.add({
      'title': title,
      'content': content,
      'category': category,
      'imageUrl': imageUrl,
      'authorId': authorId ?? _auth.currentUser?.uid,
      'authorName': authorName,
      'views': 0,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Send push notification to all citizens
    try {
      await PushNotificationService.notifyNewAnnouncement(
        announcementId: docRef.id,
        title: title,
        category: category,
      );
    } catch (e) {
      // Log error but don't fail the operation
      print('Failed to send announcement notification: $e');
    }

    return docRef;
  }
  
  static Future<DocumentReference> addAnnouncementComment({
    required String announcementId,
    required String text,
    required bool isAnonymous,
  }) async {
    final userData = await getCurrentUserData();
    final currentUser = _auth.currentUser;
    
    return await announcements
        .doc(announcementId)
        .collection('comments')
        .add({
          'text': text,
          'isAnonymous': isAnonymous,
          'userId': isAnonymous ? null : currentUser?.uid,
          'userName': isAnonymous ? 'Anonymous' : (userData?['name'] ?? 'Unknown'),
          'createdAt': FieldValue.serverTimestamp(),
        });
  }
  
  static Stream<QuerySnapshot> getAnnouncementsStream() {
    return announcements
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
  
  static Stream<QuerySnapshot> getAnnouncementCommentsStream(String announcementId) {
    return announcements
        .doc(announcementId)
        .collection('comments')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
  
  static Future<void> incrementAnnouncementViews(String announcementId) async {
    return await announcements.doc(announcementId).update({
      'views': FieldValue.increment(1),
    });
  }
  
  // Problem reports methods
  static Future<DocumentReference> addProblemReport({
    required String title,
    required String description,
    required String type,
    required GeoPoint location,
    required List<String> imageUrls,
  }) async {
    final userData = await getCurrentUserData();
    final userId = _auth.currentUser?.uid;
    
    return await problemReports.add({
      'title': title,
      'description': description,
      'type': type,
      'location': location,
      'images': imageUrls,
      'status': 'Pending',
      'userId': userId,
      'userName': userData?['name'] ?? 'Anonymous',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'assignedTo': null,
      'resolutionNotes': null,
      'resolutionDate': null,
    });
  }
  
  static Stream<QuerySnapshot> getProblemReportsStream() {
    return problemReports
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
  
  static Stream<QuerySnapshot> getUserProblemReportsStream(String userId) {
    return problemReports
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
  
  static Future<void> updateProblemReportStatus({
    required String reportId,
    required String status,
    String? assignedTo,
    String? resolutionNotes,
  }) async {
    // Get the original report to find the reporter
    final reportDoc = await problemReports.doc(reportId).get();
    final reportData = reportDoc.data() as Map<String, dynamic>?;
    
    final data = {
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    
    if (assignedTo != null) {
      data['assignedTo'] = assignedTo;
    }
    
    if (resolutionNotes != null) {
      data['resolutionNotes'] = resolutionNotes;
      data['resolutionDate'] = FieldValue.serverTimestamp();
    }
    
    await problemReports.doc(reportId).update(data);

    // Send push notification to the citizen who reported the problem
    try {
      final userId = reportData?['userId'] as String?;
      final title = reportData?['title'] as String? ?? 'Your report';
      
      if (userId != null) {
        await PushNotificationService.notifyProblemReportUpdate(
          userId: userId,
          reportTitle: title,
          newStatus: status,
          resolutionNotes: resolutionNotes,
        );
      }
    } catch (e) {
      print('Failed to send problem report update notification: $e');
    }
  }
  
  // Government messages methods
  static Future<DocumentReference> sendGovernmentMessage({
    required String subject,
    required String message,
    required String type,
    required bool isAnonymous,
  }) async {
    final userData = await getCurrentUserData();
    final currentUser = _auth.currentUser;
    
    final docRef = await governmentMessages.add({
      'subject': subject,
      'message': message,
      'type': type,
      'isAnonymous': isAnonymous,
      'userId': isAnonymous ? null : currentUser?.uid,
      'senderName': isAnonymous ? 'Anonymous' : (userData?['name'] ?? 'Unknown'),
      'senderEmail': isAnonymous ? null : (userData?['email'] ?? currentUser?.email),
      'status': 'Unread',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'response': null,
      'responseDate': null,
      'respondedBy': null,
    });

    // Send push notification to government users
    try {
      await PushNotificationService.notifyNewCitizenMessage(
        messageId: docRef.id,
        subject: subject,
        senderName: isAnonymous ? 'Anonymous' : (userData?['name'] ?? 'Unknown'),
        messageType: type,
      );
    } catch (e) {
      print('Failed to send citizen message notification: $e');
    }

    return docRef;
  }
  
  static Future<void> respondToMessage({
    required String messageId,
    required String response,
  }) async {
    final userData = await getCurrentUserData();
    
    // Get the original message to find the sender
    final messageDoc = await governmentMessages.doc(messageId).get();
    final messageData = messageDoc.data() as Map<String, dynamic>?;
    
    await governmentMessages.doc(messageId).update({
      'response': response,
      'responseDate': FieldValue.serverTimestamp(),
      'respondedBy': userData?['name'] ?? _auth.currentUser?.uid,
      'status': 'Responded',
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Send push notification to the citizen who sent the message
    try {
      final userId = messageData?['userId'] as String?;
      final subject = messageData?['subject'] as String? ?? 'Your message';
      
      if (userId != null) {
        await PushNotificationService.notifyGovernmentResponse(
          userId: userId,
          messageSubject: subject,
        );
      }
    } catch (e) {
      print('Failed to send government response notification: $e');
    }
  }
  
  static Stream<QuerySnapshot> getGovernmentMessagesStream() {
    return governmentMessages
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
  
  static Stream<QuerySnapshot> getUserMessagesStream(String userId) {
    return governmentMessages
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
  
  // Polls methods
  static Future<DocumentReference> createPoll({
    required String title,
    required String description,
    required List<String> options,
    required DateTime expiryDate,
    required bool isAnonymous,
  }) async {
    final userData = await getCurrentUserData();
    
    final Map<String, int> optionsMap = {};
    for (String option in options) {
      optionsMap[option] = 0;
    }
    
    final docRef = await polls.add({
      'title': title,
      'description': description,
      'options': optionsMap,
      'createdBy': _auth.currentUser?.uid,
      'creatorName': userData?['name'] ?? 'Unknown',
      'isAnonymous': isAnonymous,
      'createdAt': FieldValue.serverTimestamp(),
      'expiryDate': Timestamp.fromDate(expiryDate),
      'totalVotes': 0,
      'isActive': true,
    });

    // Send push notification to all citizens
    try {
      await PushNotificationService.notifyNewPoll(
        pollId: docRef.id,
        title: title,
      );
    } catch (e) {
      print('Failed to send poll notification: $e');
    }

    return docRef;
  }
  
  static Future<void> votePoll({
    required String pollId,
    required String option,
  }) async {
    final userId = _auth.currentUser?.uid;
    
    // First check if user already voted
    final userVote = await polls
        .doc(pollId)
        .collection('votes')
        .doc(userId)
        .get();
    
    if (userVote.exists) {
      // User already voted, update vote
      final previousVote = userVote.data()?['option'];
      
      // Update poll options count
      await polls.doc(pollId).update({
        'options.$previousVote': FieldValue.increment(-1),
        'options.$option': FieldValue.increment(1),
      });
      
      // Update user vote
      await polls
          .doc(pollId)
          .collection('votes')
          .doc(userId)
          .update({
            'option': option,
            'updatedAt': FieldValue.serverTimestamp(),
          });
    } else {
      // User hasn't voted, create new vote
      await polls.doc(pollId).update({
        'options.$option': FieldValue.increment(1),
        'totalVotes': FieldValue.increment(1),
      });
      
      // Save user vote
      await polls
          .doc(pollId)
          .collection('votes')
          .doc(userId)
          .set({
            'option': option,
            'userId': userId,
            'createdAt': FieldValue.serverTimestamp(),
          });
    }
  }
  
  static Stream<QuerySnapshot> getPollsStream() {
    return polls
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
  
  static Stream<QuerySnapshot> getActivePollsStream() {
    return polls
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
  
  static Future<void> closePoll(String pollId) async {
    return await polls.doc(pollId).update({
      'isActive': false,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
  
  // Emergency contacts methods
  static Future<DocumentReference> addEmergencyContact({
    required String name,
    required String number,
    required String category,
    String? description,
  }) async {
    return await emergencyContacts.add({
      'name': name,
      'number': number,
      'category': category,
      'description': description,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
  
  static Stream<QuerySnapshot> getEmergencyContactsStream() {
    return emergencyContacts
        .orderBy('name')
        .snapshots();
  }
} 