import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_service.dart';

class PushNotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Initialize push notifications for the app
  static Future<void> initialize(BuildContext context) async {
    try {
      // Request permissions (required for Android 13+ and iOS)
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      debugPrint('🔔 Notification permission: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        
        // Get FCM token and store it
        await _storeFCMToken();

        // Set up foreground message handling
        _setupForegroundMessageHandling(context);

        // Set up token refresh handling
        _messaging.onTokenRefresh.listen(_updateFCMToken);
      }
    } catch (e) {
      debugPrint('Error initializing push notifications: $e');
    }
  }

  // Store FCM token for the current user
  static Future<void> _storeFCMToken() async {
    try {
      final user = AuthService.currentUser;
      if (user == null) return;

      final token = await _messaging.getToken();
      if (token != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'fcmToken': token,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        });
        debugPrint('🔑 FCM Token stored: $token');
      }
    } catch (e) {
      debugPrint('Error storing FCM token: $e');
    }
  }

  // Update FCM token when it refreshes
  static Future<void> _updateFCMToken(String token) async {
    try {
      final user = AuthService.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'fcmToken': token,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        });
        debugPrint('🔄 FCM Token updated: $token');
      }
    } catch (e) {
      debugPrint('Error updating FCM token: $e');
    }
  }

  // Setup foreground message handling
  static void _setupForegroundMessageHandling(BuildContext context) {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('🔔 Foreground message: ${message.notification?.title}');
      
      final notification = message.notification;
      if (notification != null && context.mounted) {
        _showInAppNotification(context, notification, message.data);
      }
    });
  }

  // Show in-app notification
  static void _showInAppNotification(
    BuildContext context,
    RemoteNotification notification,
    Map<String, dynamic> data,
  ) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              notification.title ?? 'Notification',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            if (notification.body != null) ...[
              const SizedBox(height: 4),
              Text(notification.body!),
            ],
          ],
        ),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'View',
          onPressed: () => _handleNotificationTap(context, data),
        ),
      ),
    );
  }

  // Handle notification tap actions
  static void _handleNotificationTap(BuildContext context, Map<String, dynamic> data) {
    final type = data['type'];
    // final id = data['id']; // Commented out since not used yet

    switch (type) {
      case 'announcement':
        // Navigate to announcement details
        break;
      case 'problem_report':
        // Navigate to problem report details
        break;
      case 'government_message':
        // Navigate to message details
        break;
      case 'poll':
        // Navigate to poll details
        break;
      case 'advertisement':
        // Navigate to advertisement details
        break;
    }
  }

  // Background message handler
  static Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    try {
      await Firebase.initializeApp();
      debugPrint('[BG] Message: ${message.notification?.title}');
    } catch (e) {
      debugPrint('Error in background message handler: $e');
    }
  }

  // Send notification to specific user
  static Future<void> sendNotificationToUser({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Get user's FCM token
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final fcmToken = userDoc.data()?['fcmToken'] as String?;
      
      if (fcmToken != null) {
        await _sendFCMMessage(
          token: fcmToken,
          title: title,
          body: body,
          data: data ?? {},
        );
      }
    } catch (e) {
      debugPrint('Error sending notification to user $userId: $e');
    }
  }

  // Send notification to all users with specific role
  static Future<void> sendNotificationToRole({
    required String role,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      final usersQuery = await _firestore
          .collection('users')
          .where('role', isEqualTo: role)
          .where('fcmToken', isNotEqualTo: null)
          .get();

      for (final doc in usersQuery.docs) {
        final fcmToken = doc.data()['fcmToken'] as String?;
        if (fcmToken != null) {
          await _sendFCMMessage(
            token: fcmToken,
            title: title,
            body: body,
            data: data ?? {},
          );
        }
      }
    } catch (e) {
      debugPrint('Error sending notification to role $role: $e');
    }
  }

  // Send FCM message using HTTP API
  static Future<void> _sendFCMMessage({
    required String token,
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) async {
    // Note: In production, this should be done from your backend server
    // using the Firebase Admin SDK for security reasons
    debugPrint('📤 Sending notification: $title to token: ${token.substring(0, 20)}...');
    
    // For demo purposes, we'll just log the notification
    // In a real app, implement server-side notification sending
  }

  // Notification methods for specific events

  // When a new problem is reported
  static Future<void> notifyNewProblemReport({
    required String reportId,
    required String title,
    required String reporterName,
    required String problemType,
  }) async {
    await sendNotificationToRole(
      role: 'government',
      title: 'New Problem Report',
      body: '$reporterName reported: $title ($problemType)',
      data: {
        'type': 'problem_report',
        'id': reportId,
        'action': 'view_report',
      },
    );
  }

  // When government responds to a citizen message
  static Future<void> notifyGovernmentResponse({
    required String userId,
    required String messageSubject,
  }) async {
    await sendNotificationToUser(
      userId: userId,
      title: 'Government Response',
      body: 'You received a response to: $messageSubject',
      data: {
        'type': 'government_message',
        'action': 'view_response',
      },
    );
  }

  // When a new announcement is published
  static Future<void> notifyNewAnnouncement({
    required String announcementId,
    required String title,
    required String category,
  }) async {
    await sendNotificationToRole(
      role: 'citizen',
      title: 'New Announcement',
      body: '$category: $title',
      data: {
        'type': 'announcement',
        'id': announcementId,
        'action': 'view_announcement',
      },
    );
  }

  // When a new poll is created
  static Future<void> notifyNewPoll({
    required String pollId,
    required String title,
  }) async {
    await sendNotificationToRole(
      role: 'citizen',
      title: 'New Poll Available',
      body: 'Vote now: $title',
      data: {
        'type': 'poll',
        'id': pollId,
        'action': 'view_poll',
      },
    );
  }

  // When an advertisement is approved/rejected
  static Future<void> notifyAdvertisementStatus({
    required String advertiserId,
    required String adTitle,
    required bool isApproved,
    String? rejectionReason,
  }) async {
    final status = isApproved ? 'approved' : 'rejected';
    final body = isApproved 
        ? 'Your advertisement "$adTitle" has been approved and is now live!'
        : 'Your advertisement "$adTitle" was rejected. Reason: ${rejectionReason ?? 'Not specified'}';

    await sendNotificationToUser(
      userId: advertiserId,
      title: 'Advertisement ${status.toUpperCase()}',
      body: body,
      data: {
        'type': 'advertisement',
        'action': 'view_ads',
        'status': status,
      },
    );
  }

  // When a new advertisement needs review
  static Future<void> notifyNewAdvertisementForReview({
    required String adId,
    required String title,
    required String businessName,
  }) async {
    await sendNotificationToRole(
      role: 'government',
      title: 'New Advertisement for Review',
      body: '$businessName submitted: $title',
      data: {
        'type': 'advertisement',
        'id': adId,
        'action': 'review_advertisement',
      },
    );
  }

  // When a citizen message is received
  static Future<void> notifyNewCitizenMessage({
    required String messageId,
    required String subject,
    required String senderName,
    required String messageType,
  }) async {
    await sendNotificationToRole(
      role: 'government',
      title: 'New Message from Citizen',
      body: '$senderName sent a $messageType: $subject',
      data: {
        'type': 'government_message',
        'id': messageId,
        'action': 'view_message',
      },
    );
  }

  // When a problem report status is updated
  static Future<void> notifyProblemReportUpdate({
    required String userId,
    required String reportTitle,
    required String newStatus,
    String? resolutionNotes,
  }) async {
    final body = newStatus == 'Resolved' && resolutionNotes != null
        ? 'Your report "$reportTitle" has been resolved. Notes: $resolutionNotes'
        : 'Your report "$reportTitle" status updated to: $newStatus';

    await sendNotificationToUser(
      userId: userId,
      title: 'Problem Report Update',
      body: body,
      data: {
        'type': 'problem_report',
        'action': 'view_report',
        'status': newStatus,
      },
    );
  }

  // Clean up old tokens (call this periodically)
  static Future<void> cleanupOldTokens() async {
    try {
      final cutoffDate = DateTime.now().subtract(const Duration(days: 30));
      final oldTokensQuery = await _firestore
          .collection('users')
          .where('lastTokenUpdate', isLessThan: Timestamp.fromDate(cutoffDate))
          .get();

      final batch = _firestore.batch();
      for (final doc in oldTokensQuery.docs) {
        batch.update(doc.reference, {
          'fcmToken': FieldValue.delete(),
          'lastTokenUpdate': FieldValue.delete(),
        });
      }
      await batch.commit();
      
      debugPrint('🧹 Cleaned up ${oldTokensQuery.docs.length} old FCM tokens');
    } catch (e) {
      debugPrint('Error cleaning up old tokens: $e');
    }
  }
}
