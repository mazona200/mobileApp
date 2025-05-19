import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class PushNotificationService {
  static Future<void> initialize(BuildContext context) async {
    final messaging = FirebaseMessaging.instance;

    // Request permissions (required for Android 13+ and iOS)
    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    print('🔔 Notification permission: ${settings.authorizationStatus}');

    // Print token for testing via Firebase Console
    final token = await messaging.getToken();
    print('🔑 FCM Token: $token');

    // Foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('🔔 Foreground: ${message.notification?.title}');
      final notification = message.notification;
      if (notification != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(notification.title ?? 'New Notification')),
        );
      }
    });
  }

  static Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    await Firebase.initializeApp();
    print('[BG] Message: ${message.notification?.title}');
  }
}
