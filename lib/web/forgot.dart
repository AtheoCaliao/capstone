import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:mycapstone_project/web/login.dart';

const Color _primaryAqua = Color(0xFF00A8B5);
const Color _secondaryIceBlue = Color(0xFF1E5A7A);
const Color _darkDeepTeal = Color(0xFF0A1F24);
const Color _mutedCoolGray = Color(0xFF546E7A);
const Color _lightOffWhite = Color(0xFFF5F5F5);

class ForgotPassword extends StatefulWidget {
  const ForgotPassword({super.key});

  @override
  State<ForgotPassword> createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  final TextEditingController emailController = TextEditingController();
  bool _isLoading = false;

  Future<void> resetPassword() async {
    if (emailController.text.isEmpty) {
      Get.snackbar(
        'Error',
        'Please enter your email address',
        backgroundColor: const Color(0xFFD32F2F),
        colorText: Colors.white,
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: emailController.text.trim(),
      );
      Get.snackbar(
        'Success',
        'Password reset email sent! Please check your inbox.',
        backgroundColor: const Color(0xFF388E3C),
        colorText: Colors.white,
      );
      Future.delayed(const Duration(seconds: 2), () {
        Get.offAll(() => const Login());
      });
    } catch (e) {
      Get.snackbar(
        'Reset Failed',
        e.toString(),
        backgroundColor: const Color(0xFFD32F2F),
        colorText: Colors.white,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    emailController.dispose();
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

  // Wide screen layout
  Widget _buildWideScreenLayout(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 1000),
      child: Row(
        children: [
          // Left side - Info
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(60),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                ],
              ),
            ),
          ),

          // Right side - Reset form
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(20),
              child: _buildResetCard(context, isCompact: false),
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

        _buildResetCard(context, isCompact: true),
      ],
    );
  }

  // Reset password card
  Widget _buildResetCard(BuildContext context, {required bool isCompact}) {
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
          // Icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: _primaryAqua.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.lock_reset_rounded,
              color: _primaryAqua,
              size: 40,
            ),
          ),
          const SizedBox(height: 24),

          // Header
          Text(
            'Reset Password',
            style: TextStyle(
              fontSize: isCompact ? 28 : 36,
              fontWeight: FontWeight.bold,
              color: _darkDeepTeal,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Enter your email address and we\'ll send you a link to reset your password.',
            style: TextStyle(
              fontSize: isCompact ? 15 : 16,
              color: _mutedCoolGray,
              height: 1.5,
            ),
          ),
          SizedBox(height: isCompact ? 32 : 40),

          // Email Field
          Text(
            'Email Address',
            style: TextStyle(
              fontSize: 14,
              color: _darkDeepTeal,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 10),
          Container(
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
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              style: TextStyle(
                color: _darkDeepTeal,
                fontWeight: FontWeight.w500,
                fontSize: 15,
              ),
              decoration: InputDecoration(
                hintText: 'you@example.com',
                hintStyle: TextStyle(
                  color: _mutedCoolGray.withOpacity(0.6),
                  fontSize: 15,
                ),
                prefixIcon: Icon(
                  Icons.email_outlined,
                  color: _primaryAqua,
                  size: 20,
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
          ),
          const SizedBox(height: 28),

          // Reset Button
          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: _isLoading ? null : resetPassword,
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
                        const Icon(Icons.send_rounded, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Send Reset Link',
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Remember your password? ',
                  style: TextStyle(color: _mutedCoolGray, fontSize: 14),
                ),
                GestureDetector(
                  onTap: () {
                    Get.offAll(() => const Login());
                  },
                  child: Text(
                    'Sign In',
                    style: TextStyle(
                      color: _primaryAqua,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
