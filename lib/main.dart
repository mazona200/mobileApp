import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'common/role_selection_page.dart';
import 'services/push_notifications.dart';
import 'services/theme_provider.dart';
import 'services/user_service.dart';

import 'citizen/citizen_home_page.dart';
import 'government/gov_home_page.dart';
import 'advertiser/advertiser_home_page.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('[BG] FCM received: ${message.notification?.title}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    final secureStorage = const FlutterSecureStorage();
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      await secureStorage.delete(key: 'user_role');
      await secureStorage.delete(key: 'current_role');
      print('[Auth] No user at startup; cleared cached roles.');
    } else {
      print('[Auth] User at startup: ${user.email} (${user.uid})');
    }

    FirebaseAuth.instance.authStateChanges().listen((user) async {
      if (user == null) {
        // Wait a bit before clearing cached roles to avoid false signout on reload
        await Future.delayed(const Duration(seconds: 5));
        if (FirebaseAuth.instance.currentUser == null) {
          await secureStorage.delete(key: 'user_role');
          await secureStorage.delete(key: 'current_role');
          print('[Auth] Confirmed no user after delay; cleared cached roles.');
        } else {
          print('[Auth] User re-signed in during delay; not clearing roles.');
        }
      } else {
        final role = await UserService.getUserRole(user.uid);
        if (role != null) {
          await secureStorage.write(key: 'user_role', value: role);
          await secureStorage.write(key: 'current_role', value: role);
          print('✅ Signed-in user: ${user.email} (${user.uid}) with role $role cached locally.');
        } else {
          await secureStorage.delete(key: 'user_role');
          await secureStorage.delete(key: 'current_role');
          print('[Auth] No role found for user, cleared cached roles.');
        }
      }
    });
  } catch (e) {
    runApp(MyApp(showFirebaseError: true, errorMessage: e.toString()));
    return;
  }

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  final bool showFirebaseError;
  final String? errorMessage;

  const MyApp({super.key, this.showFirebaseError = false, this.errorMessage});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    try {
      PushNotificationService.initialize(context);
    } catch (e) {
      print('PushNotificationService init error: $e');
    }

    if (widget.showFirebaseError) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Firebase Initialization Error'),
            content: Text(
              'Error initializing Firebase:\n${widget.errorMessage ?? ''}\nSome features may not work.',
            ),
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

  Future<Widget> _getInitialScreen() async {
    final isLoggedIn = await UserService.isAnyUserLoggedIn();
    if (isLoggedIn) {
      final role = await UserService.getCurrentLoggedInRole();
      print('[Startup] Detected logged in role: $role');
      switch (role?.toLowerCase()) {
        case 'citizen':
          return const CitizenHomePage();
        case 'government':
          return const GovernmentHomePage();
        case 'advertiser':
          return const AdvertiserHomePage();
      }
    }
    return const RoleSelectionPage();
  }

  @override
  Widget build(BuildContext context) {
    return DynamicThemeProvider(
      child: Builder(
        builder: (context) => MaterialApp(
          title: 'GovGate',
          debugShowCheckedModeBanner: false,
          theme: context.theme,
          home: FutureBuilder<Widget>(
            future: _getInitialScreen(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              return snapshot.data ?? const RoleSelectionPage();
            },
          ),
          onGenerateRoute: (settings) =>
              MaterialPageRoute(builder: (_) => const RoleSelectionPage()),
        ),
      ),
    );
  }
}