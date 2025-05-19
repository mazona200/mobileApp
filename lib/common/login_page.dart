import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'signup_page.dart';
import '../government/gov_home_page.dart';
import '../utils/string_extensions.dart';
import '../services/user_service.dart';
import '../services/error_handler.dart';
import '../services/theme_service.dart';
import '../citizen/citizen_home_page.dart';
import '../advertiser/advertiser_home_page.dart';

class LoginPage extends StatefulWidget {
  final String role;
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  LoginPage({super.key, required this.role});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();
  final LocalAuthentication biometricAuth = LocalAuthentication();

  bool isLoading = false;
  bool rememberMe = false;
  
  // Safely get FirebaseAuth instance or null if not available
  FirebaseAuth? get _auth {
    try {
      return FirebaseAuth.instance;
    } catch (e) {
      debugPrint('Firebase Auth not available: $e');
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
    _triggerBiometricLogin();
  }

  Future<void> _loadSavedCredentials() async {
    try {
      final savedEmail = await secureStorage.read(key: 'saved_email');
      final savedPassword = await secureStorage.read(key: 'saved_password');
      final savedRemember = await secureStorage.read(key: 'remember_me') == 'true';

      if (savedRemember && mounted) {
        setState(() {
          widget.emailController.text = savedEmail ?? '';
          widget.passwordController.text = savedPassword ?? '';
          rememberMe = true;
        });
      }
    } catch (e) {
      debugPrint('Error loading saved credentials: $e');
    }
  }

  Future<void> _triggerBiometricLogin() async {
    try {
      final remember = await secureStorage.read(key: 'remember_me');
      if (remember != 'true') return;

      final canCheck = await biometricAuth.canCheckBiometrics;
      final isSupported = await biometricAuth.isDeviceSupported();

      if (!canCheck || !isSupported) {
        debugPrint('Biometric not supported');
        return;
      }

      final authenticated = await biometricAuth.authenticate(
        localizedReason: 'Authenticate to log in',
        options: const AuthenticationOptions(biometricOnly: true),
      );

      debugPrint('Biometric authenticated=$authenticated');

      if (authenticated && mounted) {
        login(auto: true);
      }
    } catch (e) {
      debugPrint('Error triggering biometric login: $e');
    }
  }

  Future<void> login({bool auto = false}) async {
    if (!auto && !_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      // Check if Firebase Auth is available
      if (_auth == null) {
        await Future.delayed(const Duration(seconds: 1)); // Simulate network delay
        
        if (!mounted) return;
        
        // Demo mode - use predefined roles for testing
        if (widget.emailController.text.trim() == 'admin@example.com' && 
            widget.passwordController.text.trim() == 'password123') {
          
          if (rememberMe) {
            await secureStorage.write(key: 'saved_email', value: widget.emailController.text.trim());
            await secureStorage.write(key: 'saved_password', value: widget.passwordController.text.trim());
            await secureStorage.write(key: 'remember_me', value: 'true');
          }
          
          _navigateToRolePage(widget.role);
          return;
        } else {
          throw Exception('Invalid credentials. In demo mode, use admin@example.com/password123');
        }
      }
      
      // Sign in with Firebase Auth
      final userCredential = await _auth!.signInWithEmailAndPassword(
        email: widget.emailController.text.trim(),
        password: widget.passwordController.text.trim(),
      );
      
      // Check if user exists in Firestore
      final docSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();
      
      if (!docSnapshot.exists) {
        // Create a minimal user record if it doesn't exist
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
              'email': widget.emailController.text.trim(),
              'role': widget.role,
              'createdAt': FieldValue.serverTimestamp(),
            });
      } else {
        // Check if user role matches the requested role
        final String? storedRole = docSnapshot.data()?['role'];
        
        if (storedRole != widget.role) {
          throw Exception('You are registered as a $storedRole, not as a ${widget.role}');
        }
      }

      // Save login state for this role
      await UserService.saveLoginState(
        widget.role,
        userCredential.user!.uid,
        userCredential.user!.email ?? widget.emailController.text.trim()
      );

      // If role matches, proceed with login
      if (rememberMe) {
        await secureStorage.write(key: 'saved_email', value: widget.emailController.text.trim());
        await secureStorage.write(key: 'saved_password', value: widget.passwordController.text.trim());
        await secureStorage.write(key: 'remember_me', value: 'true');
      } else {
        await secureStorage.delete(key: 'saved_email');
        await secureStorage.delete(key: 'saved_password');
        await secureStorage.write(key: 'remember_me', value: 'false');
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login Successful as ${widget.role}!')),
      );

      _navigateToRolePage(widget.role);
    } catch (e) {
      if (!mounted) return;
      ErrorHandler.showError(context, e);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }
  
  void _navigateToRolePage(String role) {
    if (!mounted) return;
    
    Widget targetPage;
    switch (role.toLowerCase()) {
      case 'government':
        targetPage = const GovernmentHomePage();
        break;
      case 'citizen':
        targetPage = const CitizenHomePage();
        break;
      case 'advertiser':
        targetPage = const AdvertiserHomePage();
        break;
      default:
        // Default fallback
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unknown role type')),
        );
        return;
    }
    
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => targetPage),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Login as ${widget.role.capitalize()}")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  controller: widget.emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: "Email"),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: widget.passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: "Password"),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    return null;
                  },
                ),
                Row(
                  children: [
                    Checkbox(
                      value: rememberMe,
                      onChanged: (value) {
                        setState(() {
                          rememberMe = value ?? false;
                        });
                      },
                    ),
                    const Text("Remember Me"),
                  ],
                ),
                const SizedBox(height: 20),
                isLoading
                    ? const CircularProgressIndicator()
                    : Column(
                        children: [
                          ElevatedButton(
                            onPressed: () => login(),
                            child: const Text("Login"),
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton.icon(
                            onPressed: () async {
                              print('[DEBUG] Biometric button pressed');
                              final canCheck = await biometricAuth.canCheckBiometrics;
                              final isSupported = await biometricAuth.isDeviceSupported();
                              print('[DEBUG] canCheck=$canCheck, isSupported=$isSupported');

                              if (!canCheck || !isSupported) {
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Biometrics not supported on this device."),
                                  ),
                                );
                                return;
                              }

                              final authenticated = await biometricAuth.authenticate(
                                localizedReason: 'Authenticate using fingerprint or face ID',
                                options: const AuthenticationOptions(biometricOnly: true),
                              );

                              print('[DEBUG] authenticated=$authenticated');

                              if (authenticated) {
                                login(auto: true);
                              } else {
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Biometric login failed or was canceled.")),
                                );
                              }
                            },
                            icon: const Icon(Icons.fingerprint),
                            label: const Text("Use Biometric Login"),
                          ),
                        ],
                      ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SignupPage(role: widget.role),
                      ),
                    );
                  },
                  child: const Text("Don't have an account? Sign up"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
