import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'common/role_selection_page.dart';
import 'services/push_notifications.dart'; // ✅ Modular FCM service
import 'services/theme_service.dart';
import 'services/theme_provider.dart'; // Import our new theme provider
import 'services/user_service.dart';
import 'citizen/citizen_home_page.dart';
import 'government/gov_home_page.dart';
import 'advertiser/advertiser_home_page.dart';
import 'dart:async';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
    print('[BG] Message received: ${message.notification?.title}');
  } catch (e) {
    print('[BG] Error initializing Firebase: $e');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase with more robust error handling
  try {
    await Firebase.initializeApp();
    print('Firebase initialization successful');
    
    // Register background FCM handler
    FirebaseMessaging.onBackgroundMessage(
      PushNotificationService.firebaseMessagingBackgroundHandler,
    );
  } catch (e) {
    print('Firebase initialization failed: $e');
    // Continue without Firebase, but show an error dialog when the app starts
    runApp(MyApp(showFirebaseError: true, errorMessage: e.toString()));
    return;
  }

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  final bool showFirebaseError;
  final String? errorMessage;
  
  const MyApp({
    super.key, 
    this.showFirebaseError = false,
    this.errorMessage,
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    
    // Try to initialize push notifications, but continue if it fails
    try {
      PushNotificationService.initialize(context);
    } catch (e) {
      print('Error initializing push notifications: $e');
      // Continue without push notifications
    }
    
    // Show Firebase error if needed
    if (widget.showFirebaseError) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Firebase Error'),
            content: Text(
              'There was an error initializing Firebase. Some features may not work properly.\n\n'
              'Error: ${widget.errorMessage}'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      });
    }
  }
  
  // Helper method to determine initial route based on login status
  Future<Widget> _getInitialScreen() async {
    if (await UserService.isAnyUserLoggedIn()) {
      final currentRole = await UserService.getCurrentLoggedInRole();
      
      if (currentRole != null) {
        switch (currentRole.toLowerCase()) {
          case 'citizen':
            return const CitizenHomePage();
          case 'government':
            return const GovernmentHomePage();
          case 'advertiser':
            return const AdvertiserHomePage();
          default:
            break;
        }
      }
    }
    return const RoleSelectionPage();
  }

  @override
  Widget build(BuildContext context) {
    // Wrap the app with our DynamicThemeProvider
    return DynamicThemeProvider(
      child: Builder(
        builder: (context) {
          return MaterialApp(
            title: 'GovGate',
            debugShowCheckedModeBanner: false,
            // Use the theme from our ThemeProvider
            theme: context.theme,
            // Use FutureBuilder to determine the initial route based on login status
            home: FutureBuilder<Widget>(
              future: _getInitialScreen(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                return snapshot.data ?? const RoleSelectionPage();
              },
            ),
            // Handle all routes through our protection logic
            onGenerateRoute: (settings) {
              // All routes go to RoleSelectionPage first, which will handle redirection based on login status
              return MaterialPageRoute(builder: (_) => const RoleSelectionPage());
            },
          );
        },
      ),
    );
  }
}
