import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class PushNotificationService {
  static Future<void> initialize(BuildContext context) async {
    try {
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
      }, onError: (error) {
        print('Error in FCM message listener: $error');
      });
    } catch (e) {
      print('Error initializing push notifications: $e');
      // Don't throw - push notifications are a non-critical feature
    }
  }

  static Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    try {
      await Firebase.initializeApp();
      print('[BG] Message: ${message.notification?.title}');
    } catch (e) {
      print('Error in background message handler: $e');
    }
  }
}
