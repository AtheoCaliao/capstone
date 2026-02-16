import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
// Use local stub for firebase_dynamic_links so the project builds
// without the actual package installed. Replace with real package
// import when adding `firebase_dynamic_links` to `pubspec.yaml`.
import 'firebase_dynamic_links_stub.dart';

// Import Firebase helper
import 'package:mycapstone_project/firebase_helper.dart';

// Import test helper for debugging
import 'package:mycapstone_project/web/firestore_test.dart';

// Import app and web versions
import 'package:mycapstone_project/app/landing.dart' as app;
import 'package:mycapstone_project/web/landing.dart' as web;

// Custom Color Palette
const Color _primaryAqua = Color(0xFF8ED7DA);
const Color _secondaryIceBlue = Color(0xFFC6D4E1);
const Color _darkDeepTeal = Color(0xFF0E2F34);
const Color _mutedCoolGray = Color(0xFF8A8FA3);
const Color _lightOffWhite = Color(0xFFF1F1EE);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    print('🔵 [FIREBASE] Initializing Firebase for web...');

    // Firebase options for web
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyCi_JVTayAfb5cjS1CuYvZeB8Q6HyxBWfY",
        authDomain: "capstone-c98f9.firebaseapp.com",
        projectId: "capstone-c98f9",
        storageBucket: "capstone-c98f9.firebasestorage.app",
        messagingSenderId: "628319595773",
        appId: "1:628319595773:web:afe9520590fad2a3192294",
        measurementId: "G-DFQ4GMPTHP",
      ),
    );
    print('✅ [FIREBASE] Firebase initialized');

    // Configure Firestore settings for web
    // This MUST be done before any Firestore operations
    try {
      print('🔵 [FIRESTORE] Configuring Firestore settings...');

      // Get Firestore instance with the correct database ID
      final firestore = getFirestoreInstance();

      // Important: Check if Firestore is properly initialized
      print('🔵 [FIRESTORE] Firestore instance created: ${firestore.hashCode}');
      print('🔵 [FIRESTORE] App name: ${Firebase.app().name}');
      print('🔵 [FIRESTORE] Project ID: ${Firebase.app().options.projectId}');
      print('🔵 [FIRESTORE] Database ID: capstone-c98f9');

      firestore.settings = const Settings(
        persistenceEnabled: false,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );

      print('✅ [FIRESTORE] Settings configured successfully');
      print('✅ [FIRESTORE] Ready for operations');

      // Run Firestore connection test
      print('\n🧪 Running Firestore connection test...');
      await testFirestoreConnection();
    } catch (e) {
      print('❌ [FIRESTORE] Configuration error: $e');
      print('⚠️ [FIRESTORE] Continuing anyway...');
    }
  } else {
    // Mobile platforms use google-services.json/GoogleService-Info.plist
    await Firebase.initializeApp();
    // Initialize dynamic links on mobile so password reset and other
    // action links can be handled in-app.
    await _initDynamicLinks();
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Health Monitoring System',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.light(
          primary: _primaryAqua,
          onPrimary: _darkDeepTeal,
          secondary: _secondaryIceBlue,
          onSecondary: _darkDeepTeal,
          surface: _lightOffWhite,
          onSurface: _darkDeepTeal,
          outline: _mutedCoolGray,
          outlineVariant: _mutedCoolGray,
          error: const Color(0xFFD32F2F),
          onError: Colors.white,
        ),
        scaffoldBackgroundColor: _lightOffWhite,
        appBarTheme: AppBarTheme(
          backgroundColor: _darkDeepTeal,
          foregroundColor: _lightOffWhite,
          elevation: 0,
          centerTitle: false,
          iconTheme: const IconThemeData(color: _lightOffWhite),
          titleTextStyle: const TextStyle(
            color: _lightOffWhite,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: _primaryAqua,
            foregroundColor: _darkDeepTeal,
            elevation: 2,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: _mutedCoolGray.withOpacity(0.3)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: _mutedCoolGray.withOpacity(0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: _primaryAqua, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFD32F2F), width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: _primaryAqua,
          foregroundColor: _darkDeepTeal,
          elevation: 4,
        ),
        dividerTheme: DividerThemeData(
          color: _mutedCoolGray.withOpacity(0.2),
          thickness: 1,
          space: 1,
        ),
        chipTheme: ChipThemeData(
          backgroundColor: _secondaryIceBlue.withOpacity(0.3),
          labelStyle: TextStyle(
            color: _darkDeepTeal,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: _darkDeepTeal,
          contentTextStyle: const TextStyle(color: _lightOffWhite),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          behavior: SnackBarBehavior.floating,
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: _darkDeepTeal,
          ),
          displayMedium: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: _darkDeepTeal,
          ),
          displaySmall: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: _darkDeepTeal,
          ),
          headlineMedium: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: _darkDeepTeal,
          ),
          headlineSmall: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: _darkDeepTeal,
          ),
          titleLarge: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: _darkDeepTeal,
          ),
          bodyLarge: TextStyle(fontSize: 16, color: _darkDeepTeal),
          bodyMedium: TextStyle(fontSize: 14, color: _darkDeepTeal),
          bodySmall: TextStyle(fontSize: 12, color: _mutedCoolGray),
        ),
      ),
      debugShowCheckedModeBanner: false,
      // Platform-specific routing
      home: kIsWeb ? const web.LandingPage() : const app.LandingPage(),
    );
  }
}

Future<void> _initDynamicLinks() async {
  // Only initialize dynamic links on non-web platforms
  if (kIsWeb) return;
  try {
    final dynamicLinks = getFirebaseDynamicLinks();
    final initialLink =
        await dynamicLinks?.getInitialLink();
    if (initialLink?.link != null) {
      // Handle the deep link, e.g., parse parameters and navigate
      // ignore: avoid_print
      print('Dynamic Link (initial): ${initialLink!.link}');
    }

    dynamicLinks?.onLink.listen((dynamicLinkData) {
      final Uri deepLink = dynamicLinkData.link;
      // Handle the deep link - navigate to reset screen or handle code
      // ignore: avoid_print
      print('Dynamic Link (onLink): $deepLink');
    }).onError((error) {
      // ignore: avoid_print
      print('Dynamic Link error: $error');
    });
  } catch (e) {
    // ignore: avoid_print
    print('Error initializing dynamic links: $e');
  }
}

// Platform-aware stub for getFirebaseDynamicLinks
dynamic getFirebaseDynamicLinks() {
  if (kIsWeb) return null;
  // On non-web platforms, FirebaseDynamicLinks is available via conditional import above
  // Use try-catch to avoid undefined name error if not available
  try {
    // ignore: undefined_identifier
    return FirebaseDynamicLinks.instance;
  } catch (_) {
    return null;
  }
}
