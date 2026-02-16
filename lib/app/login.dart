import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:mycapstone_project/app/homepage.dart';
import 'package:mycapstone_project/app/landing.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:mycapstone_project/app/signup.dart';
import 'package:mycapstone_project/app/forgot.dart';


const Color _primaryAqua = Color(0xFF00A8B5);
const Color _secondaryIceBlue = Color(0xFF1E5A7A);
const Color _darkDeepTeal = Color(0xFF0A1F24);
const Color _mutedCoolGray = Color(0xFF546E7A);
const Color _lightOffWhite = Color(0xFFF5F5F5);

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  // Replace this with the OAuth 2.0 Client ID (Web application) from
  // Google Cloud / Firebase console (looks like "...apps.googleusercontent.com").
  // Required on Android for server-side auth flows.
  static const String _googleServerClientId = '628319595773-o2goeoicefu66u0kdpe1mcvf1q7jmn4l.apps.googleusercontent.com';
  static bool _googleInitialized = false;
  Future<void> signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      if (kIsWeb) {
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.setCustomParameters({'login_hint': 'user@example.com'});

        final UserCredential userCredential = await FirebaseAuth.instance
            .signInWithPopup(googleProvider);

        if (userCredential.user != null) {
          Get.snackbar(
            'Success',
            'Google sign-in successful!',
            backgroundColor: const Color(0xFF388E3C),
            colorText: Colors.white,
          );
          Get.offAll(() => const HomePage());
        }
      } else {
        try {
          if (!_googleInitialized) {
            await GoogleSignIn.instance.initialize(serverClientId: _googleServerClientId);
            _googleInitialized = true;
          }

          final GoogleSignInAccount account =
              await GoogleSignIn.instance.authenticate(scopeHint: ['email']);

          final GoogleSignInAuthentication auth = account.authentication;

          // Try to obtain an access token for APIs that require it.
          final GoogleSignInClientAuthorization? clientAuth =
              await GoogleSignIn.instance.authorizationClient
                  .authorizationForScopes(<String>['email', 'profile']);

          final AuthCredential credential = GoogleAuthProvider.credential(
            accessToken: clientAuth?.accessToken,
            idToken: auth.idToken,
          );

          await FirebaseAuth.instance.signInWithCredential(credential);
          Get.snackbar(
            'Success',
            'Google sign-in successful!',
            backgroundColor: const Color(0xFF388E3C),
            colorText: Colors.white,
          );
          Get.offAll(() => const HomePage());
        } on GoogleSignInException catch (gse, st) {
          // Show more detailed information to help debugging configuration
          final String code = gse.code.toString();
          final String desc = gse.toString();
          // Log to console as well as show in snackbar
          // ignore: avoid_print
          print('GoogleSignInException: code=$code description=$desc');
          // ignore: avoid_print
          print(st);
          Get.snackbar(
            'Google Sign-In Failed',
            'Code: $code\n${desc}',
            backgroundColor: const Color(0xFFD32F2F),
            colorText: Colors.white,
            duration: const Duration(seconds: 6),
          );
        } catch (e, st) {
          // Generic fallback for unexpected errors
          // ignore: avoid_print
          print('Google sign-in error: $e');
          // ignore: avoid_print
          print(st);
          Get.snackbar(
            'Google Sign-In Failed',
            e.toString(),
            backgroundColor: const Color(0xFFD32F2F),
            colorText: Colors.white,
            duration: const Duration(seconds: 6),
          );
        } finally {
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      Get.snackbar(
        'Google Sign-In Failed',
        e.toString(),
        backgroundColor: const Color(0xFFD32F2F),
        colorText: Colors.white,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  Future<void> signIn() async {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      Get.snackbar(
        'Error',
        'Please fill in all fields',
        backgroundColor: const Color(0xFFD32F2F),
        colorText: Colors.white,
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text,
      );
      Get.snackbar(
        'Success',
        'Login successful!',
        backgroundColor: const Color(0xFF388E3C),
        colorText: Colors.white,
      );
      // Navigate to HomePage after successful login
      Get.offAll(() => const HomePage());
    } catch (e) {
      Get.snackbar(
        'Login Failed',
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
    passwordController.dispose();
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
          onPressed: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const LandingPage()),
            );
          },
        ),
        title: Text(
          'Sign In',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: _darkDeepTeal,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
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
                          Icons.favorite,
                          size: 60,
                          color: _primaryAqua,
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
                    'Welcome Back',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: _darkDeepTeal,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sign in to access your health monitoring dashboard',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: _mutedCoolGray,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),

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
              const SizedBox(height: 12),

              // Forgot Password
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    Get.to(() => const ForgotPassword());
                  },
                  child: Text(
                    'Forgot Password?',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: _primaryAqua,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Sign In Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : signIn,
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
                      : const Icon(Icons.login, size: 20),
                  label: Text(
                    _isLoading ? 'Signing In...' : 'Sign In',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: _darkDeepTeal,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Divider with text
              Row(
                children: [
                  Expanded(
                    child: Divider(
                      color: _mutedCoolGray.withOpacity(0.3),
                      thickness: 1,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'OR',
                      style: TextStyle(
                        color: _mutedCoolGray,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Divider(
                      color: _mutedCoolGray.withOpacity(0.3),
                      thickness: 1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Social Login Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildSocialButton(
                    icon: Icons.facebook,
                    color: const Color(0xFF1877F3),
                    onTap: () {
                      // TODO: Implement Facebook sign-in
                    },
                  ),
                  const SizedBox(width: 16),
                  _buildSocialButton(
                    icon: Icons.g_mobiledata,
                    color: Colors.black,
                    onTap: _isLoading ? null : signInWithGoogle,
                  ),
                  const SizedBox(width: 16),
                  _buildSocialButton(
                    icon: Icons.apple,
                    color: Colors.black,
                    onTap: () {
                      // TODO: Implement Apple sign-in
                    },
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Continue to Offline Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.wifi_off, size: 20),
                  label: Text(
                    'Continue Offline',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: _darkDeepTeal,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: _primaryAqua.withOpacity(0.5),
                      width: 2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    foregroundColor: _darkDeepTeal,
                  ),
                  onPressed: () {
                    Get.offAll(
                      () => const HomePage(),
                      arguments: {'offline': true},
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Sign Up Link
              Center(
                child: RichText(
                  text: TextSpan(
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: _mutedCoolGray),
                    children: [
                      const TextSpan(text: "Don't have an account? "),
                      TextSpan(
                        text: 'Sign Up',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: _primaryAqua,
                              fontWeight: FontWeight.bold,
                            ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            Get.to(() => const Signup());
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
        hintText: 'Enter your password',
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

  // Helper method for social buttons
  Widget _buildSocialButton({
    required IconData icon,
    required Color color,
    required VoidCallback? onTap,
  }) {
    return Material(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            border: Border.all(color: color.withOpacity(0.3), width: 1.5),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, color: color, size: 28),
        ),
      ),
    );
  }
}
