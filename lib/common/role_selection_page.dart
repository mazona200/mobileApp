import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'signup_page.dart';
import 'forgot_password_page.dart';
import '../services/theme_service.dart';
import '../services/auth_service.dart';
import '../government/gov_home_page.dart';
import '../citizen/citizen_home_page.dart';
import '../advertiser/advertiser_home_page.dart';

class RoleSelectionPage extends StatefulWidget {
  const RoleSelectionPage({super.key});

  @override
  State<RoleSelectionPage> createState() => _RoleSelectionPageState();
}

class _RoleSelectionPageState extends State<RoleSelectionPage> {
  final Map<String, bool> cardFlipped = {
    'citizen': false,
    'government': false,
    'advertiser': false,
  };

  final Map<String, TextEditingController> emailControllers = {
    'citizen': TextEditingController(),
    'government': TextEditingController(),
    'advertiser': TextEditingController(),
  };

  final Map<String, TextEditingController> passwordControllers = {
    'citizen': TextEditingController(),
    'government': TextEditingController(),
    'advertiser': TextEditingController(),
  };

  final Map<String, GlobalKey<FormState>> formKeys = {
    'citizen': GlobalKey<FormState>(),
    'government': GlobalKey<FormState>(),
    'advertiser': GlobalKey<FormState>(),
  };
  
  final Map<String, bool> rememberMe = {
    'citizen': false,
    'government': false,
    'advertiser': false,
  };
  
  bool _isChecking = true;
  
  @override
  void initState() {
    super.initState();
    _checkExistingLogins();
    _loadSavedCredentials();
  }
  
  Future<void> _checkExistingLogins() async {
    // Check if any user is logged in
    if (await AuthService.isAnyUserLoggedIn()) {
      // Get the current role
      final currentRole = await AuthService.getCachedCurrentRole();
      
      if (mounted && currentRole != null) {
        // Navigate to the appropriate home page based on role
        _navigateToRoleHome(context, currentRole);
      }
    } else {
      // No logged in roles, stay on selection page
      if (mounted) {
        setState(() {
          _isChecking = false;
        });
      }
    }
  }
  
  Future<void> _loadSavedCredentials() async {
    try {
      final credentials = await AuthService.loadSavedCredentials();
      final savedEmail = credentials['email'];
      final savedPassword = credentials['password'];
      final remember = credentials['remember'] == 'true';
      
      if (remember && savedEmail != null && savedPassword != null && mounted) {
        setState(() {
          // Apply saved credentials to all role forms
          for (final role in AuthService.validRoles) {
            emailControllers[role]?.text = savedEmail;
            passwordControllers[role]?.text = savedPassword;
            rememberMe[role] = true;
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading saved credentials: $e');
    }
  }
  
  void _navigateToRoleHome(BuildContext context, String role) {
    Widget homePage;
    
    switch (role.toLowerCase()) {
      case 'citizen':
        homePage = const CitizenHomePage();
        break;
      case 'government':
        homePage = const GovernmentHomePage();
        break;
      case 'advertiser':
        homePage = const AdvertiserHomePage();
        break;
      default:
        setState(() {
          _isChecking = false;
        });
        return;
    }
    
    // Navigate to the appropriate home page
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => homePage),
    );
  }

  void flipCard(String role) {
    setState(() {
      // Reset all cards first
      cardFlipped.forEach((key, value) {
        cardFlipped[key] = false;
      });
      
      // Then flip the selected card
      cardFlipped[role] = !cardFlipped[role]!;
    });
  }

  void navigateToSignup(BuildContext context, String role) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SignupPage(role: role)),
    ).then((_) {
      // When returning from signup, check if the user has been logged in
      _checkExistingLogins();
    });
  }

  Future<void> login(BuildContext context, String role) async {
    if (!formKeys[role]!.currentState!.validate()) return;
    
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );
    
    try {
      // Use the unified AuthService for login
      await AuthService.signInWithEmailAndPassword(
        email: emailControllers[role]!.text.trim(),
        password: passwordControllers[role]!.text.trim(),
        role: role,
      );
      
      // Save credentials if remember me is checked
      await AuthService.saveCredentials(
        emailControllers[role]!.text.trim(),
        passwordControllers[role]!.text.trim(),
        rememberMe[role] ?? false,
      );
      
      // Close the loading dialog
      if (context.mounted) Navigator.pop(context);
      
      // Navigate to the appropriate home page based on role
      if (context.mounted) {
        _navigateToRoleHome(context, role);
      }
    } catch (e) {
      // Close the loading dialog
      if (context.mounted) Navigator.pop(context);
      
      // Show error message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().contains('Exception:') 
              ? e.toString().split('Exception: ')[1] 
              : 'Login failed. Please check your credentials.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    
    // Show loading indicator while checking for existing logins
    if (_isChecking) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    return GestureDetector(
      // Handle taps outside of cards to unflip all cards
      onTap: () {
        setState(() {
          cardFlipped.forEach((key, value) {
            cardFlipped[key] = false;
          });
        });
      },
      child: WillPopScope(
        // Prevent back navigation from this screen
        onWillPop: () async => false,
        child: Scaffold(
          appBar: AppBar(
            title: const Text("Select Role"),
            centerTitle: true,
            automaticallyImplyLeading: false, // Remove back button
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      "Welcome to GovGate",
                      style: ThemeService.headingStyle,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      "You want to login as ...",
                      style: TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 30),
                  
                  // Citizen Card
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: _buildFlipCard(
                      role: 'citizen',
                      title: 'Citizen',
                      description: 'Access government services, emergency numbers, and community updates',
                      color: Colors.green.shade600,
                      icon: Icons.person,
                      cardHeight: screenSize.height * 0.35,
                    ),
                  ),
                  
                  // Government Card
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: _buildFlipCard(
                      role: 'government',
                      title: 'Government',
                      description: 'Create announcements, manage polls, and respond to citizen inquiries',
                      color: Colors.blue.shade700,
                      icon: Icons.account_balance,
                      cardHeight: screenSize.height * 0.35,
                    ),
                  ),
                  
                  // Advertiser Card
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: _buildFlipCard(
                      role: 'advertiser',
                      title: 'Advertiser',
                      description: 'Create and manage advertising campaigns for government services',
                      color: Colors.orange.shade600,
                      icon: Icons.campaign,
                      cardHeight: screenSize.height * 0.35,
                    ),
                  ),
                  
                  // Forgot Password Button
                  const SizedBox(height: 10),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ForgotPasswordPage()),
                      );
                    },
                    icon: const Icon(Icons.lock_reset),
                    label: const Text('Forgot Password?'),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFlipCard({
    required String role,
    required String title,
    required String description,
    required Color color,
    required IconData icon,
    required double cardHeight,
  }) {
    return GestureDetector(
      onTap: () => flipCard(role),
      child: TweenAnimationBuilder(
        tween: Tween<double>(
          begin: 0,
          end: cardFlipped[role]! ? math.pi : 0,
        ),
        duration: const Duration(milliseconds: 500),
        builder: (context, value, child) {
          // Determine if card is showing front or back
          final showFront = value < (math.pi / 2);
          
          return Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001) // perspective
              ..rotateY(value),
            alignment: Alignment.center,
            child: showFront
                ? _buildCardFront(role, title, description, color, icon, cardHeight)
                : Transform(
                    transform: Matrix4.identity()..rotateY(math.pi),
                    alignment: Alignment.center,
                    child: _buildCardBack(role, title, color, cardHeight),
                  ),
          );
        },
      ),
    );
  }

  Widget _buildCardFront(
    String role,
    String title,
    String description,
    Color color,
    IconData icon,
    double cardHeight,
  ) {
    return Container(
      height: cardHeight,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Image background (this will be replaced with actual images)
            // For now, we'll use a gradient until images are placed in the assets/roles/ directory
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    color.withOpacity(0.7),
                    color,
                  ],
                ),
              ),
              // This is where you would place the Image.asset widget when images are available
              // Image.asset(
              //   'assets/roles/$role.jpg',
              //   fit: BoxFit.cover,
              // ),
            ),
            
            // Card content overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),
            
            // Card content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Spacer(),
                  Icon(
                    icon,
                    color: Colors.white,
                    size: 40,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Tap to login',
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardBack(
    String role,
    String title,
    Color color,
    double cardHeight,
  ) {
    return Container(
      height: cardHeight,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: formKeys[role],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "Login as $title",
                style: TextStyle(
                  color: color,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              // Email field
              TextFormField(
                controller: emailControllers[role],
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: "Email",
                  prefixIcon: const Icon(Icons.email),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  isDense: true, // Reduces height of field
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              // Password field
              TextFormField(
                controller: passwordControllers[role],
                obscureText: true,
                decoration: InputDecoration(
                  labelText: "Password",
                  prefixIcon: const Icon(Icons.lock),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  isDense: true, // Reduces height of field
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 4),
              // Remember Me checkbox
              SizedBox(
                height: 36, // Fixed height for checkbox row
                child: Row(
                  children: [
                    Checkbox(
                      value: rememberMe[role] ?? false,
                      onChanged: (value) {
                        setState(() {
                          rememberMe[role] = value ?? false;
                        });
                      },
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    const Text("Remember Me", style: TextStyle(fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              // Login button
              SizedBox(
                height: 36, // Fixed height for button
                child: ElevatedButton(
                  onPressed: () => login(context, role),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 0), // Reduce padding
                  ),
                  child: const Text(
                    "Login",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 2),
              // Sign up link - only show for citizen and advertiser roles
              if (role != 'government')
                SizedBox(
                  height: 32, // Fixed height for signup button
                  child: TextButton(
                    onPressed: () => navigateToSignup(context, role),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 0), // Reduce padding
                      minimumSize: const Size(0, 32), // Set minimum size
                    ),
                    child: Text(
                      "Don't have an account? Sign Up",
                      style: TextStyle(color: color, fontSize: 11), // Smaller text
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
  
  @override
  void dispose() {
    emailControllers.forEach((key, controller) => controller.dispose());
    passwordControllers.forEach((key, controller) => controller.dispose());
    super.dispose();
  }
}
