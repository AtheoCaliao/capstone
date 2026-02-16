import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:mycapstone_project/app/login.dart';

const Color _primaryAqua = Color(0xFF8ED7DA);
const Color _secondaryIceBlue = Color(0xFFC6D4E1);
const Color _darkDeepTeal = Color(0xFF0E2F34);
const Color _mutedCoolGray = Color(0xFF8A8FA3);
const Color _lightOffWhite = Color(0xFFF1F1EE);

class ForgotPassword extends StatefulWidget {
	const ForgotPassword({super.key});

	@override
	State<ForgotPassword> createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
	final TextEditingController emailController = TextEditingController();
	bool _isLoading = false;

	Future<void> resetPassword() async {
		final String email = emailController.text.trim();
		if (email.isEmpty) {
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
			// Configure ActionCodeSettings to handle the reset link inside the app.
			// Replace the `url` with your app's deep link or continue URL configured
			// in Firebase Dynamic Links or your web handler.
			// Use the Firebase project hosting domain so the link is allowlisted by
			// default if you enable Firebase Hosting, or add this domain to
			// Firebase Console -> Authentication -> Settings -> Authorized domains.
			// Replace with your Dynamic Links domain if you have one (recommended).
			final ActionCodeSettings actionCodeSettings = ActionCodeSettings(
				url: 'https://capstone-c98f9.firebaseapp.com/reset?email=${Uri.encodeComponent(email)}',
				handleCodeInApp: true,
				androidPackageName: 'com.example.mycapstone_project',
				androidInstallApp: true,
				androidMinimumVersion: '21',
				iOSBundleId: 'com.example.mycapstone_project',
			);

			await FirebaseAuth.instance.sendPasswordResetEmail(
				email: email,
				actionCodeSettings: actionCodeSettings,
			);
			Get.snackbar(
				'Success',
				'Password reset link sent. Open the link in this app to complete reset.',
				backgroundColor: const Color(0xFF388E3C),
				colorText: Colors.white,
			);
			Future.delayed(const Duration(seconds: 2), () {
				Get.offAll(() => const Login());
			});
		} on FirebaseAuthException catch (e) {
			final String msg = e.message ?? e.code;
			// If the error indicates an authorized domain / reCAPTCHA issue,
			// attempt a fallback plain reset email (no ActionCodeSettings) to
			// verify basic email deliverability.
			if (msg.toLowerCase().contains('allowlist') ||
			    msg.toLowerCase().contains('domain') ||
			    msg.toLowerCase().contains('recaptcha')) {
				// ignore: avoid_print
				print('ActionCodeSettings send failed: $msg — trying plain send as fallback');
				try {
					await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
					Get.snackbar(
						'Fallback Sent',
						'Password reset email sent (fallback). Check your inbox/spam.',
						backgroundColor: const Color(0xFF388E3C),
						colorText: Colors.white,
					);
					Future.delayed(const Duration(seconds: 2), () {
						Get.offAll(() => const Login());
					});
				} catch (fallbackErr) {
					// ignore: avoid_print
					print('Fallback send failed: $fallbackErr');
					Get.snackbar(
						'Reset Failed',
						fallbackErr.toString(),
						backgroundColor: const Color(0xFFD32F2F),
						colorText: Colors.white,
					);
				}
			} else {
				Get.snackbar(
					'Reset Failed',
					msg,
					backgroundColor: const Color(0xFFD32F2F),
					colorText: Colors.white,
				);
			}
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
		return Scaffold(
			backgroundColor: _lightOffWhite,
			appBar: AppBar(
				elevation: 0,
				backgroundColor: _darkDeepTeal,
				leading: IconButton(
					icon: const Icon(Icons.arrow_back, color: _lightOffWhite),
					onPressed: () {
						Navigator.of(context).pushReplacement(
							MaterialPageRoute(builder: (context) => const Login()),
						);
					},
				),
				title: Text(
					'Forgot Password',
					style: Theme.of(context).textTheme.headlineMedium?.copyWith(
								color: _lightOffWhite,
							),
				),
			),
			body: SingleChildScrollView(
				child: Padding(
					padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40),
					child: Column(
						crossAxisAlignment: CrossAxisAlignment.start,
						children: [
							Center(
								child: Container(
									width: 100,
									height: 100,
									decoration: BoxDecoration(
										color: _primaryAqua.withOpacity(0.2),
										borderRadius: BorderRadius.circular(20),
										border: Border.all(color: _primaryAqua, width: 2),
									),
									child: const Icon(
										Icons.lock_reset,
										color: _primaryAqua,
										size: 50,
									),
								),
							),
							const SizedBox(height: 32),
							Text(
								'Reset Password',
								style: Theme.of(context).textTheme.displaySmall?.copyWith(
											color: _darkDeepTeal,
										),
							),
							const SizedBox(height: 8),
							Text(
								'Enter your email address and we\'ll send you a link to reset your password.',
								style: Theme.of(context).textTheme.bodyLarge?.copyWith(
											color: _mutedCoolGray,
										),
							),
							const SizedBox(height: 32),
							Text(
								'Email Address',
								style: Theme.of(context).textTheme.titleMedium?.copyWith(
											color: _darkDeepTeal,
										),
							),
							const SizedBox(height: 8),
							TextField(
								controller: emailController,
								keyboardType: TextInputType.emailAddress,
								style: const TextStyle(color: _darkDeepTeal),
								decoration: InputDecoration(
									hintText: 'you@example.com',
									hintStyle: const TextStyle(color: _mutedCoolGray),
									prefixIcon: const Icon(Icons.email_outlined, color: _primaryAqua),
									border: OutlineInputBorder(
										borderRadius: BorderRadius.circular(12),
										borderSide: const BorderSide(color: _mutedCoolGray),
									),
									enabledBorder: OutlineInputBorder(
										borderRadius: BorderRadius.circular(12),
										borderSide: const BorderSide(color: _mutedCoolGray),
									),
									focusedBorder: OutlineInputBorder(
										borderRadius: BorderRadius.circular(12),
										borderSide: const BorderSide(color: _primaryAqua, width: 2),
									),
									filled: true,
									fillColor: Colors.white,
								),
							),
							const SizedBox(height: 32),
							SizedBox(
								width: double.infinity,
								height: 56,
								child: ElevatedButton(
									onPressed: _isLoading ? null : resetPassword,
									style: ElevatedButton.styleFrom(
										backgroundColor: _primaryAqua,
										foregroundColor: _darkDeepTeal,
										shape: RoundedRectangleBorder(
											borderRadius: BorderRadius.circular(12),
										),
										elevation: 2,
									),
									child: _isLoading
											? const SizedBox(
													height: 24,
													width: 24,
													child: CircularProgressIndicator(
														valueColor: AlwaysStoppedAnimation<Color>(_darkDeepTeal),
														strokeWidth: 2.5,
													),
												)
											: Text(
													'Send Reset Link',
													style: Theme.of(context).textTheme.titleLarge?.copyWith(
																color: _darkDeepTeal,
															),
												),
								),
							),
							const SizedBox(height: 24),
							Center(
								child: Row(
									mainAxisAlignment: MainAxisAlignment.center,
									children: [
										Text(
											'Remember your password? ',
											style: Theme.of(context).textTheme.bodyMedium?.copyWith(
														color: _mutedCoolGray,
													),
										),
										GestureDetector(
											onTap: () {
												Get.offAll(() => const Login());
											},
											child: Text(
												'Sign In',
												style: Theme.of(context).textTheme.titleMedium?.copyWith(
															color: _primaryAqua,
															fontWeight: FontWeight.bold,
														),
											),
										),
									],
								),
							),
						],
					),
				),
			),
		);
	}
}
