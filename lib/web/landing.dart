import 'package:flutter/material.dart';
import 'package:mycapstone_project/web/login.dart';
import 'package:mycapstone_project/web/signup.dart';
import 'package:mycapstone_project/web/homepage.dart';

const Color _primaryAqua = Color(0xFF6B9DA8);
const Color _secondaryIceBlue = Color(0xFF2F4156);
const Color _darkDeepTeal = Color(0xFF1B2A3A);
const Color _mutedCoolGray = Color(0xFFB5C1C9);
const Color _lightOffWhite = Color(0xFFFFFFFF);

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _lightOffWhite,
      body: Row(
        children: [
          // Left Side - Branding Section
          Expanded(
            flex: 5,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _primaryAqua,
                    _secondaryIceBlue,
                  ],
                ),
              ),
              child: Stack(
                children: [
                  // Decorative circles
                  Positioned(
                    top: -100,
                    left: -100,
                    child: Container(
                      width: 300,
                      height: 300,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -80,
                    right: -80,
                    child: Container(
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  // Main content
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(60.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Large Logo
                          Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 30,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                'assets/bg2.png',
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(
                                    Icons.medical_services_rounded,
                                    size: 100,
                                    color: _primaryAqua,
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 50),
                          // Title
                          const Text(
                            'DSUHIS',
                            style: TextStyle(
                              fontSize: 72,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Subtitle
                          const Text(
                            'Smart Health Integration System',
                            style: TextStyle(
                              fontSize: 24,
                              color: Colors.white,
                              fontWeight: FontWeight.w300,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 40),
                          // Feature badges
                          Wrap(
                            spacing: 16,
                            runSpacing: 16,
                            alignment: WrapAlignment.center,
                            children: [
                              _buildFeatureBadge(Icons.health_and_safety_rounded, 'Health Monitoring'),
                              _buildFeatureBadge(Icons.analytics_rounded, 'Advanced Analytics'),
                              _buildFeatureBadge(Icons.security_rounded, 'Secure & Private'),
                              _buildFeatureBadge(Icons.cloud_sync_rounded, 'Cloud Sync'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Right Side - Action Section
          Expanded(
            flex: 4,
            child: Container(
              color: _lightOffWhite,
              child: Center(
                child: SingleChildScrollView(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 500),
                    padding: const EdgeInsets.all(60.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Welcome text
                        const Text(
                          'Welcome Back',
                          style: TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.bold,
                            color: _darkDeepTeal,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Access your healthcare dashboard',
                          style: TextStyle(
                            fontSize: 18,
                            color: _mutedCoolGray,
                          ),
                        ),
                        const SizedBox(height: 60),
                        
                        // Login Button
                        _buildActionButton(
                          context: context,
                          label: 'Login to Account',
                          icon: Icons.login_rounded,
                          isPrimary: true,
                          onPressed: () {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(builder: (context) => const Login()),
                            );
                          },
                        ),
                        const SizedBox(height: 20),
                        
                        // Sign Up Button
                        _buildActionButton(
                          context: context,
                          label: 'Create New Account',
                          icon: Icons.person_add_rounded,
                          isPrimary: false,
                          onPressed: () {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(builder: (context) => const Signup()),
                            );
                          },
                        ),
                        const SizedBox(height: 40),
                        
                        // Divider
                        Row(
                          children: [
                            Expanded(child: Divider(color: _mutedCoolGray.withOpacity(0.3))),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'OR',
                                style: TextStyle(
                                  color: _mutedCoolGray,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Expanded(child: Divider(color: _mutedCoolGray.withOpacity(0.3))),
                          ],
                        ),
                        const SizedBox(height: 40),
                        
                        // Offline Mode Button
                        _buildActionButton(
                          context: context,
                          label: 'Continue Offline',
                          icon: Icons.cloud_off_rounded,
                          isPrimary: false,
                          isOutlined: false,
                          backgroundColor: _secondaryIceBlue.withOpacity(0.2),
                          textColor: _darkDeepTeal,
                          onPressed: () {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(builder: (context) => const HomePage()),
                            );
                          },
                        ),
                        const SizedBox(height: 60),
                        
                        // Footer info
                        Text(
                          '© 2026 DSUHIS. All rights reserved.',
                          style: TextStyle(
                            fontSize: 14,
                            color: _mutedCoolGray.withOpacity(0.7),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureBadge(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required bool isPrimary,
    bool isOutlined = true,
    Color? backgroundColor,
    Color? textColor,
    required VoidCallback onPressed,
  }) {
    return Container(
      height: 65,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: isPrimary
            ? [
                BoxShadow(
                  color: _primaryAqua.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ]
            : null,
      ),
      child: isPrimary
          ? ElevatedButton.icon(
              onPressed: onPressed,
              icon: Icon(icon, size: 24),
              label: Text(
                label,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryAqua,
                foregroundColor: _darkDeepTeal,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
            )
          : isOutlined
              ? OutlinedButton.icon(
                  onPressed: onPressed,
                  icon: Icon(icon, size: 24),
                  label: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _primaryAqua,
                    side: BorderSide(
                      color: _primaryAqua,
                      width: 2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                )
              : ElevatedButton.icon(
                  onPressed: onPressed,
                  icon: Icon(icon, size: 24),
                  label: Text(
                    label,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: backgroundColor,
                    foregroundColor: textColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                ),
    );
  }
}
