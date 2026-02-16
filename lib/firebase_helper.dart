import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

/// Helper to get the correct Firestore instance with the proper database ID.
///
/// For the capstone project, the database ID is 'capstone-c98f9' (not 'default').
/// This ensures all Firestore operations use the correct database.
FirebaseFirestore getFirestoreInstance() {
  // Always specify the database ID for both web and mobile
  return FirebaseFirestore.instanceFor(
    app: Firebase.app(),
    databaseId: 'capstone-c98f9',
  );
}
