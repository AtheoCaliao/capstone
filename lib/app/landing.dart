import 'package:flutter/material.dart';
import 'package:mycapstone_project/app/login.dart';
import 'package:mycapstone_project/app/signup.dart';
import 'package:mycapstone_project/app/homepage.dart';

const Color _primaryAqua = Color(0xFF8ED7DA);
const Color _secondaryIceBlue = Color(0xFFC6D4E1);
const Color _darkDeepTeal = Color(0xFF0E2F34);
const Color _mutedCoolGray = Color(0xFF8A8FA3);
const Color _lightOffWhite = Color(0xFFF1F1EE);

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _lightOffWhite,
      body: Stack(
        children: [
          // Decorative background circles
          Positioned(
            top: -60,
            left: -60,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                color: _primaryAqua.withOpacity(0.18),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -40,
            right: -40,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: _secondaryIceBlue.withOpacity(0.18),
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Main content
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo Container
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _primaryAqua.withOpacity(0.2),
                        border: Border.all(
                          color: _primaryAqua,
                          width: 3,
                        ),
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/background.png',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.favorite,
                              size: 70,
                              color: _primaryAqua,
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    // Title
                    Text(
                      'DSUHIS',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            color: _darkDeepTeal,
                            fontWeight: FontWeight.bold,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    // Subtitle
                    Text(
                      'Smart Health Integration',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: _mutedCoolGray,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    // Login Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(builder: (context) => const Login()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryAqua,
                          foregroundColor: _darkDeepTeal,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: Text(
                          'Login',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: _darkDeepTeal,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Sign Up Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(builder: (context) => const Signup()),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _primaryAqua,
                          side: const BorderSide(
                            color: _primaryAqua,
                            width: 2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Sign Up',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: _primaryAqua,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Continue to Offline Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(builder: (context) => const HomePage()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _secondaryIceBlue,
                          foregroundColor: _darkDeepTeal,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: Text(
                          'Continue to Offline',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: _darkDeepTeal,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
