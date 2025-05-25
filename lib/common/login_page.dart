import 'package:flutter/material.dart';
import 'signup_page.dart';
import '../government/gov_home_page.dart';
import '../citizen/citizen_home_page.dart';
import '../advertiser/advertiser_home_page.dart';
import '../services/auth_service.dart';
import '../services/error_handler.dart';
import '../utils/string_extensions.dart';

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

  bool isLoading = false;
  bool rememberMe = false;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    try {
      final credentials = await AuthService.loadSavedCredentials();
      final savedEmail = credentials['email'];
      final savedPassword = credentials['password'];
      final savedRemember = credentials['remember'] == 'true';

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

  Future<void> login({bool auto = false}) async {
    if (!auto && !_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      // Use the unified AuthService for login
      await AuthService.signInWithEmailAndPassword(
        email: widget.emailController.text.trim(),
        password: widget.passwordController.text.trim(),
        role: widget.role,
      );

      // Save or clear stored credentials based on rememberMe
      await AuthService.saveCredentials(
        widget.emailController.text.trim(),
        widget.passwordController.text.trim(),
        rememberMe,
      );

      if (!mounted) return;

      debugPrint('🔐 Login successful: ${widget.emailController.text} with role ${widget.role}');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login successful as ${widget.role}!')),
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

    late Widget targetPage;
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
                const SizedBox(height: 12),
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
                    : ElevatedButton(
                        onPressed: () => login(),
                        child: const Text("Login"),
                      ),
                const SizedBox(height: 20),
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