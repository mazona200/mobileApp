import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

import 'signup_page.dart';
import 'government/gov_home_page.dart';
import 'utils/string_extensions.dart';
import 'services/user_service.dart';
import 'services/error_handler.dart';
import 'services/theme_service.dart';
import 'citizen/citizen_home_page.dart';
import 'advertiser/advertiser_home_page.dart';

class LoginPage extends StatefulWidget {
  final String role;
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  LoginPage({super.key, required this.role});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final auth = FirebaseAuth.instance;
  final _formKey = GlobalKey<FormState>();

  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();
  final LocalAuthentication biometricAuth = LocalAuthentication();

  bool isLoading = false;
  bool rememberMe = false;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
    _triggerBiometricLogin();
  }

  Future<void> _loadSavedCredentials() async {
    final savedEmail = await secureStorage.read(key: 'saved_email');
    final savedPassword = await secureStorage.read(key: 'saved_password');
    final savedRemember = await secureStorage.read(key: 'remember_me') == 'true';

    if (savedRemember) {
      setState(() {
        widget.emailController.text = savedEmail ?? '';
        widget.passwordController.text = savedPassword ?? '';
        rememberMe = true;
      });
    }
  }

  Future<void> _triggerBiometricLogin() async {
    final remember = await secureStorage.read(key: 'remember_me');
    if (remember != 'true') return;

    final canCheck = await biometricAuth.canCheckBiometrics;
    final isSupported = await biometricAuth.isDeviceSupported();

    if (!canCheck || !isSupported) {
      print('[DEBUG] Biometric not supported');
      return;
    }

    final authenticated = await biometricAuth.authenticate(
      localizedReason: 'Authenticate to log in',
      options: const AuthenticationOptions(biometricOnly: true),
    );

    print('[DEBUG] Biometric authenticated=$authenticated');

    if (authenticated) {
      login(auto: true);
    }
  }

  Future<void> login({bool auto = false}) async {
    if (!auto && !_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      // Sign in with Firebase Auth
      final userCredential = await auth.signInWithEmailAndPassword(
        email: widget.emailController.text.trim(),
        password: widget.passwordController.text.trim(),
      );
      
      // Check if user role matches the requested role
      final String? storedRole = await UserService.getUserRole(userCredential.user!.uid);
      
      if (storedRole != widget.role) {
        throw Exception('You are registered as a $storedRole, not as a ${widget.role}');
      }

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

      // Navigate to the appropriate home page based on role
      if (widget.role.toLowerCase() == 'government') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const GovernmentHomePage()),
        );
      } else if (widget.role.toLowerCase() == 'citizen') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const CitizenHomePage()),
        );
      } else if (widget.role.toLowerCase() == 'advertiser') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdvertiserHomePage()),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ErrorHandler.showError(context, e);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
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
