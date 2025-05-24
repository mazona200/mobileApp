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

  @override
  void initState() {
    super.initState();
    // Set default date of birth to empty
    dateOfBirthController.text = '';
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime now = DateTime.now();
    final DateTime minimumAge = DateTime(now.year - 18, now.month, now.day); // Minimum age: 18 years
    
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? minimumAge,
      firstDate: DateTime(1900),
      lastDate: minimumAge,
      helpText: 'Select Date of Birth',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: ThemeService.getRoleColor(widget.role),
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        dateOfBirthController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> signup() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => isLoading = true);
    
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
      
      // Navigate back to login page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => LoginPage(role: widget.role)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Signup Failed: $e')),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // Helper to create required field label
  InputDecoration _buildInputDecoration(String label, bool isRequired, {IconData? icon}) {
    return InputDecoration(
      labelText: isRequired ? "$label *" : label,
      prefixIcon: icon != null ? Icon(icon) : null,
      labelStyle: TextStyle(
        color: ThemeService.getRoleColor(widget.role).withOpacity(0.8),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: ThemeService.getRoleColor(widget.role).withOpacity(0.5),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: ThemeService.getRoleColor(widget.role),
          width: 2,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color roleColor = ThemeService.getRoleColor(widget.role);
    
    return Scaffold(
      appBar: AppBar(
        title: Text("Sign Up as ${widget.role.capitalize()}"),
        backgroundColor: roleColor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    "Fields marked with * are required",
                    style: TextStyle(
                      fontStyle: FontStyle.italic, 
                      color: Colors.redAccent,
                    ),
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Full Name (Required)
                TextFormField(
                  controller: nameController,
                  decoration: _buildInputDecoration("Full Name", true, icon: Icons.person),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Email (Required)
                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _buildInputDecoration("Email", true, icon: Icons.email),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!value.contains('@') || !value.contains('.')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Password (Required)
                TextFormField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: _buildInputDecoration("Password", true, icon: Icons.lock),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                // National ID (Required, 14 digits)
                TextFormField(
                  controller: nationalIdController,
                  keyboardType: TextInputType.number,
                  decoration: _buildInputDecoration("National ID", true, icon: Icons.badge),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your National ID';
                    }
                    if (value.length != 14 || !RegExp(r'^[0-9]+$').hasMatch(value)) {
                      return 'National ID must be exactly 14 digits';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Date of Birth (Required)
                TextFormField(
                  controller: dateOfBirthController,
                  readOnly: true,
                  decoration: _buildInputDecoration("Date of Birth", true, icon: Icons.calendar_today),
                  onTap: () => _selectDate(context),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select your date of birth';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Gender (Required)
                DropdownButtonFormField<String>(
                  value: selectedGender,
                  decoration: _buildInputDecoration("Gender", true, icon: Icons.people),
                  items: genderOptions.map((String gender) {
                    return DropdownMenuItem<String>(
                      value: gender,
                      child: Text(gender),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedGender = value;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select your gender';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Profession (Required)
                TextFormField(
                  controller: professionController,
                  decoration: _buildInputDecoration("Profession", true, icon: Icons.work),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your profession';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Hometown (Required)
                TextFormField(
                  controller: hometownController,
                  decoration: _buildInputDecoration("Hometown", true, icon: Icons.home),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your hometown';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Phone Number (Required)
                TextFormField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: _buildInputDecoration("Phone Number", true, icon: Icons.phone),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your phone number';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 24),
                
                // Submit Button
                Center(
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: isLoading 
                      ? Center(child: CircularProgressIndicator(color: roleColor))
                      : ElevatedButton(
                          onPressed: signup,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: roleColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            "Create Account",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}