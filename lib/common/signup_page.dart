import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/string_extensions.dart';
import '../services/auth_service.dart';
import 'login_page.dart';
import '../services/theme_service.dart';
import 'package:intl/intl.dart';

class SignupPage extends StatefulWidget {
  final String role;

  const SignupPage({super.key, required this.role});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final nationalIdController = TextEditingController();
  final professionController = TextEditingController();
  final hometownController = TextEditingController();
  final dateOfBirthController = TextEditingController();
  
  String? selectedGender;
  DateTime? selectedDate;
  
  final List<String> genderOptions = ['Male', 'Female', 'Other', 'Prefer not to say'];
  
  final _formKey = GlobalKey<FormState>();
  bool isLoading = false;
  
  // Safely get FirebaseAuth instance or null if not available
  FirebaseAuth? get _auth {
    try {
      return FirebaseAuth.instance;
    } catch (e) {
      print('Firebase Auth not available: $e');
      return null;
    }
  }

  void signup() async {
    try {
      if (_auth == null) {
        // Firebase not available in this environment
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Firebase services are not available. Using demo mode.')),
        );
        
        // Wait briefly to simulate network request
        await Future.delayed(const Duration(seconds: 1));
        
        if (!mounted) return;
        // Navigate back to home/login for demo purposes
        Navigator.pop(context);
        return;
      }
      
      // Create the user account with additional data
      await AuthService.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
        role: widget.role,
        additionalData: {
          'name': nameController.text.trim(),
          'phone': phoneController.text.trim(),
          'nationalId': nationalIdController.text.trim(),
          'dateOfBirth': dateOfBirthController.text,
          'profession': professionController.text.trim(),
          'gender': selectedGender,
          'hometown': hometownController.text.trim(),
        },
      );
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Signup Successful as ${widget.role}!')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Signup Failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Sign Up as ${widget.role.capitalize()}")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: emailController, decoration: const InputDecoration(labelText: "Email")),
            TextField(controller: passwordController, obscureText: true, decoration: const InputDecoration(labelText: "Password")),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: signup, child: const Text("Sign Up")),
          ],
        ),
      ),
    );
  }
}