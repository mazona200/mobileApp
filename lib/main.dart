import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'common/role_selection_page.dart';
import 'services/push_notifications.dart'; // ✅ Modular FCM service
import 'services/theme_provider.dart'; // Import our new theme provider
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'citizen/citizen_home_page.dart';
import 'government/government_home_page.dart';
import 'advertiser/advertiser_home_page.dart';

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
  
  // Clear any existing login states to ensure we always start at the role selection screen
  // This is commented out for now, uncomment if you want to force logout on app restart
  // try {
  //   final secureStorage = FlutterSecureStorage();
  //   await secureStorage.deleteAll();
  // } catch (e) {
  //   print('Error clearing secure storage: $e');
  // }
  
  // Initialize Firebase with more robust error handling
  try {
    await Firebase.initializeApp();
    print('Firebase initialization successful');
    
    // Initialize App Check in debug mode
    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.debug,
      appleProvider: AppleProvider.debug,
    );
    print('Firebase App Check initialized in debug mode');
    
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
            // Always start with the RoleSelectionPage
            home: const RoleSelectionPage(),
            // Prevent going back to splash screen
            onGenerateRoute: (settings) {
              if (settings.name == '/') {
                return MaterialPageRoute(builder: (_) => const RoleSelectionPage());
              }
              return null;
            },
            initialRoute: '/login',
            routes: {
              '/login': (context) => const LoginScreen(),
              '/register': (context) => const RegisterScreen(),
              '/citizen/home': (context) => const CitizenHomePage(),
              '/government/home': (context) => const GovernmentHomePage(),
              '/advertiser/home': (context) => const AdvertiserHomePage(),
            },
          );
        },
      ),
    );
  }
}
