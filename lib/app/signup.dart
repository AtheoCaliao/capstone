import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:flutter/gestures.dart';
import 'package:mycapstone_project/app/homepage.dart';

const Color _primaryAqua = Color(0xFF00A8B5);
const Color _secondaryIceBlue = Color(0xFF1E5A7A);
const Color _darkDeepTeal = Color(0xFF0A1F24);
const Color _mutedCoolGray = Color(0xFF546E7A);
const Color _lightOffWhite = Color(0xFFF5F5F5);

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
    return Scaffold(
      backgroundColor: _lightOffWhite,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _darkDeepTeal, size: 24),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Create Account',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: _darkDeepTeal,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo/Icon Section with gradient
              Center(
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _primaryAqua.withOpacity(0.2),
                    border: Border.all(color: _primaryAqua, width: 2.5),
                    boxShadow: [
                      BoxShadow(
                        color: _primaryAqua.withOpacity(0.15),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/background.png',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.person_add,
                          color: _primaryAqua,
                          size: 60,
                        );
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // Heading Section
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Create Account',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: _darkDeepTeal,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Join us to start monitoring your health',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: _mutedCoolGray,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),

              // Username Field
              _buildFieldLabel(context, 'Username'),
              const SizedBox(height: 10),
              _buildTextField(
                controller: usernameController,
                hintText: 'Enter your username',
                icon: Icons.person_outline,
                keyboardType: TextInputType.text,
              ),
              const SizedBox(height: 24),

              // Email Field
              _buildFieldLabel(context, 'Email Address'),
              const SizedBox(height: 10),
              _buildTextField(
                controller: emailController,
                hintText: 'you@example.com',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 24),

              // Password Field
              _buildFieldLabel(context, 'Password'),
              const SizedBox(height: 10),
              _buildPasswordField(),
              const SizedBox(height: 24),

              // Confirm Password Field
              _buildFieldLabel(context, 'Confirm Password'),
              const SizedBox(height: 10),
              _buildConfirmPasswordField(),
              const SizedBox(height: 32),

              // Sign Up Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : signup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryAqua,
                    foregroundColor: _darkDeepTeal,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 6,
                    shadowColor: _primaryAqua.withOpacity(0.4),
                  ),
                  icon: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _darkDeepTeal,
                            ),
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Icon(Icons.person_add, size: 20),
                  label: Text(
                    _isLoading ? 'Creating Account...' : 'Create Account',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: _darkDeepTeal,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Sign In Link
              Center(
                child: RichText(
                  text: TextSpan(
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: _mutedCoolGray),
                    children: [
                      const TextSpan(text: 'Already have an account? '),
                      TextSpan(
                        text: 'Sign In',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
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
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method for field labels
  Widget _buildFieldLabel(BuildContext context, String label) {
    return Text(
      label,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        color: _darkDeepTeal,
        fontWeight: FontWeight.bold,
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
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: _darkDeepTeal, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: _mutedCoolGray),
        prefixIcon: Icon(icon, color: _primaryAqua, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: _primaryAqua.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: _primaryAqua.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _primaryAqua, width: 2.5),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }

  // Helper method for password field
  Widget _buildPasswordField() {
    return TextField(
      controller: passwordController,
      obscureText: _obscurePassword,
      style: const TextStyle(color: _darkDeepTeal, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: 'At least 6 characters',
        hintStyle: const TextStyle(color: _mutedCoolGray),
        prefixIcon: const Icon(
          Icons.lock_outline,
          color: _primaryAqua,
          size: 20,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_off : Icons.visibility,
            color: _mutedCoolGray,
            size: 20,
          ),
          onPressed: () {
            setState(() => _obscurePassword = !_obscurePassword);
          },
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: _primaryAqua.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: _primaryAqua.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _primaryAqua, width: 2.5),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }

  // Helper method for confirm password field
  Widget _buildConfirmPasswordField() {
    return TextField(
      controller: confirmPasswordController,
      obscureText: _obscureConfirmPassword,
      style: const TextStyle(color: _darkDeepTeal, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: 'Re-enter your password',
        hintStyle: const TextStyle(color: _mutedCoolGray),
        prefixIcon: const Icon(
          Icons.lock_outline,
          color: _primaryAqua,
          size: 20,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
            color: _mutedCoolGray,
            size: 20,
          ),
          onPressed: () {
            setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
          },
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: _primaryAqua.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: _primaryAqua.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _primaryAqua, width: 2.5),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }
}


