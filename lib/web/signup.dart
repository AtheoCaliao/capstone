import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:flutter/gestures.dart';
import 'package:mycapstone_project/web/homepage.dart';
import 'package:mycapstone_project/web/landing.dart';
import 'package:mycapstone_project/web/login.dart';

const Color _primaryAqua = Color(0xFF6B9DA8);
const Color _secondaryIceBlue = Color(0xFF2F4156);
const Color _darkDeepTeal = Color(0xFF1B2A3A);
const Color _mutedCoolGray = Color(0xFFB5C1C9);
const Color _lightOffWhite = Color(0xFFFFFFFF);

class Signup extends StatefulWidget {
  const Signup({super.key});

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  TextEditingController usernameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  Future<void> signup() async {
    if (usernameController.text.isEmpty ||
        emailController.text.isEmpty ||
        passwordController.text.isEmpty ||
        confirmPasswordController.text.isEmpty) {
      Get.snackbar(
        'Error',
        'Please fill in all fields',
        backgroundColor: const Color(0xFFD32F2F),
        colorText: Colors.white,
      );
      return;
    }

    if (usernameController.text.length < 3) {
      Get.snackbar(
        'Error',
        'Username must be at least 3 characters',
        backgroundColor: const Color(0xFFD32F2F),
        colorText: Colors.white,
      );
      return;
    }

    if (passwordController.text != confirmPasswordController.text) {
      Get.snackbar(
        'Error',
        'Passwords do not match',
        backgroundColor: const Color(0xFFD32F2F),
        colorText: Colors.white,
      );
      return;
    }

    if (passwordController.text.length < 6) {
      Get.snackbar(
        'Error',
        'Password must be at least 6 characters',
        backgroundColor: const Color(0xFFD32F2F),
        colorText: Colors.white,
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      // Create user account
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: emailController.text.trim(),
            password: passwordController.text,
          );

      // Update display name
      await userCredential.user!.updateDisplayName(
        usernameController.text.trim(),
      );

      // Store username in Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
            'username': usernameController.text.trim(),
            'email': emailController.text.trim(),
            'uid': userCredential.user!.uid,
            'createdAt': FieldValue.serverTimestamp(),
          });

      Get.snackbar(
        'Success',
        'Welcome ${usernameController.text.trim()}! Account created successfully.',
        backgroundColor: const Color(0xFF388E3C),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );

      // Navigate to HomePage
      Get.offAll(() => const HomePage());
    } catch (e) {
      String errorMessage = e.toString();

      // Provide user-friendly error messages
      if (errorMessage.contains('email-already-in-use')) {
        errorMessage =
            'This email is already registered. Please use a different email or try logging in.';
      } else if (errorMessage.contains('invalid-email')) {
        errorMessage = 'Please enter a valid email address.';
      } else if (errorMessage.contains('weak-password')) {
        errorMessage = 'Password is too weak. Please use a stronger password.';
      } else if (errorMessage.contains('network-request-failed')) {
        errorMessage = 'Network error. Please check your internet connection.';
      }

      Get.snackbar(
        'Signup Failed',
        errorMessage,
        backgroundColor: const Color(0xFFD32F2F),
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    usernameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWideScreen = size.width > 900;

    return Scaffold(
      backgroundColor: _lightOffWhite,
      body: Stack(
        children: [
          // Background gradient pattern
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _primaryAqua.withOpacity(0.05),
                  _secondaryIceBlue.withOpacity(0.05),
                  _lightOffWhite,
                ],
              ),
            ),
          ),

          // Decorative circles
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _primaryAqua.withOpacity(0.1),
                    _primaryAqua.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),

          Positioned(
            bottom: -150,
            left: -150,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _secondaryIceBlue.withOpacity(0.08),
                    _secondaryIceBlue.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isWideScreen ? 0 : 24,
                    vertical: 40,
                  ),
                  child: isWideScreen
                      ? _buildWideScreenLayout(context)
                      : _buildMobileLayout(context),
                ),
              ),
            ),
          ),

          // Back button
          Positioned(
            top: 16,
            left: 16,
            child: SafeArea(
              child: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.arrow_back,
                    color: _darkDeepTeal,
                    size: 24,
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => const Login()),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Wide screen layout (desktop/tablet landscape)
  Widget _buildWideScreenLayout(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 1200),
      child: Row(
        children: [
          // Left side - Branding/Info
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(60),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _primaryAqua.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/bg2.png',
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [_primaryAqua, _secondaryIceBlue],
                              ),
                            ),
                            child: Center(
                              child: Text(
                                'Logo',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  Text(
                    'DSUHIS',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: _darkDeepTeal,
                      height: 1.2,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 24),

                  Text(
                    'Smart Health Integration System',
                    style: TextStyle(
                      fontSize: 18,
                      color: _mutedCoolGray,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Feature highlights
                  _buildFeatureItem(
                    Icons.verified_user_outlined,
                    'Secure Registration',
                  ),
                  const SizedBox(height: 16),
                  _buildFeatureItem(
                    Icons.health_and_safety_outlined,
                    'Health Tracking',
                  ),
                  const SizedBox(height: 16),
                  _buildFeatureItem(
                    Icons.support_agent_outlined,
                    '24/7 Support',
                  ),
                ],
              ),
            ),
          ),

          // Right side - Signup form
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(20),
              child: _buildSignupCard(context, isCompact: false),
            ),
          ),
        ],
      ),
    );
  }

  // Mobile layout
  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      children: [
        // Logo
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: _primaryAqua.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/bg2.png',
              width: 100,
              height: 100,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [_primaryAqua, _secondaryIceBlue],
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'Logo',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 30),

        _buildSignupCard(context, isCompact: true),
      ],
    );
  }

  // Feature item widget
  Widget _buildFeatureItem(IconData icon, String text) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _primaryAqua.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: _primaryAqua, size: 24),
        ),
        const SizedBox(width: 16),
        Text(
          text,
          style: TextStyle(
            fontSize: 16,
            color: _darkDeepTeal,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // Signup card widget
  Widget _buildSignupCard(BuildContext context, {required bool isCompact}) {
    return Container(
      padding: EdgeInsets.all(isCompact ? 24 : 40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Create Account',
                style: TextStyle(
                  fontSize: isCompact ? 28 : 36,
                  fontWeight: FontWeight.bold,
                  color: _darkDeepTeal,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Join us to start monitoring your health',
                style: TextStyle(
                  fontSize: isCompact ? 15 : 16,
                  color: _mutedCoolGray,
                  height: 1.4,
                ),
              ),
            ],
          ),
          SizedBox(height: isCompact ? 28 : 32),

          // Username Field
          _buildFieldLabel(context, 'Username'),
          const SizedBox(height: 10),
          _buildTextField(
            controller: usernameController,
            hintText: 'Enter your username',
            icon: Icons.person_outline,
            keyboardType: TextInputType.text,
          ),
          const SizedBox(height: 20),

          // Email Field
          _buildFieldLabel(context, 'Email Address'),
          const SizedBox(height: 10),
          _buildTextField(
            controller: emailController,
            hintText: 'you@example.com',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 20),

          // Password Field
          _buildFieldLabel(context, 'Password'),
          const SizedBox(height: 10),
          _buildPasswordField(),
          const SizedBox(height: 20),

          // Confirm Password Field
          _buildFieldLabel(context, 'Confirm Password'),
          const SizedBox(height: 10),
          _buildConfirmPasswordField(),
          const SizedBox(height: 28),

          // Sign Up Button
          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: _isLoading ? null : signup,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryAqua,
                foregroundColor: Colors.white,
                disabledBackgroundColor: _mutedCoolGray.withOpacity(0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 2.5,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.person_add, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Create Account',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 24),

          // Sign In Link
          Center(
            child: RichText(
              text: TextSpan(
                style: TextStyle(color: _mutedCoolGray, fontSize: 14),
                children: [
                  const TextSpan(text: 'Already have an account? '),
                  TextSpan(
                    text: 'Sign In',
                    style: TextStyle(
                      color: _primaryAqua,
                      fontWeight: FontWeight.bold,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        Get.back();
                      },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper method for field labels
  Widget _buildFieldLabel(BuildContext context, String label) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 14,
        color: _darkDeepTeal,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
      ),
    );
  }

  // Helper method for text fields
  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: TextStyle(
          color: _darkDeepTeal,
          fontWeight: FontWeight.w500,
          fontSize: 15,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            color: _mutedCoolGray.withOpacity(0.6),
            fontSize: 15,
          ),
          prefixIcon: Icon(icon, color: _primaryAqua, size: 20),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: _mutedCoolGray.withOpacity(0.1),
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: _primaryAqua, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
        ),
      ),
    );
  }

  // Helper method for password field
  Widget _buildPasswordField() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: passwordController,
        obscureText: _obscurePassword,
        style: TextStyle(
          color: _darkDeepTeal,
          fontWeight: FontWeight.w500,
          fontSize: 15,
        ),
        decoration: InputDecoration(
          hintText: 'At least 6 characters',
          hintStyle: TextStyle(
            color: _mutedCoolGray.withOpacity(0.6),
            fontSize: 15,
          ),
          prefixIcon: const Icon(
            Icons.lock_outline_rounded,
            color: _primaryAqua,
            size: 20,
          ),
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: _mutedCoolGray,
              size: 20,
            ),
            onPressed: () {
              setState(() => _obscurePassword = !_obscurePassword);
            },
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: _mutedCoolGray.withOpacity(0.1),
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: _primaryAqua, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
        ),
      ),
    );
  }

  // Helper method for confirm password field
  Widget _buildConfirmPasswordField() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: confirmPasswordController,
        obscureText: _obscureConfirmPassword,
        style: TextStyle(
          color: _darkDeepTeal,
          fontWeight: FontWeight.w500,
          fontSize: 15,
        ),
        decoration: InputDecoration(
          hintText: 'Re-enter your password',
          hintStyle: TextStyle(
            color: _mutedCoolGray.withOpacity(0.6),
            fontSize: 15,
          ),
          prefixIcon: const Icon(
            Icons.lock_outline_rounded,
            color: _primaryAqua,
            size: 20,
          ),
          suffixIcon: IconButton(
            icon: Icon(
              _obscureConfirmPassword
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: _mutedCoolGray,
              size: 20,
            ),
            onPressed: () {
              setState(
                () => _obscureConfirmPassword = !_obscureConfirmPassword,
              );
            },
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: _mutedCoolGray.withOpacity(0.1),
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: _primaryAqua, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
        ),
      ),
    );
  }
}
