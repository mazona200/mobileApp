import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'signup_page.dart';
import 'gov_home_page.dart';
import 'forgot_password_page.dart';  // Import for forgot password
import 'utils/string_extensions.dart';

class LoginPage extends StatefulWidget {
  final String role;

  const LoginPage({super.key, required this.role});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final auth = FirebaseAuth.instance;
  final _formKey = GlobalKey<FormState>();

  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();

  bool isLoading = false;
  bool rememberMe = false;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final savedEmail = await secureStorage.read(key: 'saved_email');
    final savedPassword = await secureStorage.read(key: 'saved_password');
    final savedRemember = await secureStorage.read(key: 'remember_me') == 'true';

    if (savedRemember) {
      setState(() {
        emailController.text = savedEmail ?? '';
        passwordController.text = savedPassword ?? '';
        rememberMe = true;
      });
    }
  }

  Future<void> login({bool auto = false}) async {
    if (!auto && !_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      await auth.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      if (rememberMe) {
        await secureStorage.write(key: 'saved_email', value: emailController.text.trim());
        await secureStorage.write(key: 'saved_password', value: passwordController.text.trim());
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

      if (widget.role.toLowerCase() == 'government') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const GovernmentHomePage()),
        );
      } else {
        // TODO: Handle other roles
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login Failed: $e')),
      );
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
          child: Column(
            children: [
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: "Email"),
              ),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: "Password"),
              ),

              // Forgot Password button
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ForgotPasswordPage()),
                    );
                  },
                  child: const Text("Forgot Password?"),
                ),
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
                  : ElevatedButton(
                      onPressed: login,
                      child: const Text("Login"),
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
    );
  }
}
