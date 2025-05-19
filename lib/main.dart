import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'role_selection_page.dart';
import 'services/push_notifications.dart'; // ✅ Modular FCM service
import 'services/theme_service.dart';
import 'services/theme_provider.dart'; // Import our new theme provider
import 'services/user_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('[BG] Message received: ${message.notification?.title}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // ✅ Register background FCM handler
  FirebaseMessaging.onBackgroundMessage(
    PushNotificationService.firebaseMessagingBackgroundHandler,
  );

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    PushNotificationService.initialize(context); // ✅ Moved FCM logic here
  }

  @override
  Widget build(BuildContext context) {
    // Wrap the app with our DynamicThemeProvider
    return DynamicThemeProvider(
      child: Builder(
        builder: (context) {
          return MaterialApp(
            title: 'Gov App',
            debugShowCheckedModeBanner: false,
            // Use the theme from our ThemeProvider
            theme: context.theme,
            home: const RoleSelectionPage(),
          );
        },
      ),
    );
  }
}
