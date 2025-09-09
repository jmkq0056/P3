import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// Utility class to test Firebase initialization and basic functionality
class FirebaseTest {
  /// Tests Firebase authentication initialization
  static Future<bool> testAuth() async {
    try {
      FirebaseAuth auth = FirebaseAuth.instance;
      await auth.authStateChanges().first;
      return true;
    } catch (e) {
      print('Firebase Auth test failed: $e');
      return false;
    }
  }

  /// Tests Firestore initialization
  static Future<bool> testFirestore() async {
    try {
      FirebaseFirestore firestore = FirebaseFirestore.instance;
      await firestore.collection('test').limit(1).get();
      return true;
    } catch (e) {
      print('Firebase Firestore test failed: $e');
      return false;
    }
  }

  /// Tests Firebase Storage initialization
  static Future<bool> testStorage() async {
    try {
      FirebaseStorage storage = FirebaseStorage.instance;
      await storage.ref().listAll();
      return true;
    } catch (e) {
      print('Firebase Storage test failed: $e');
      return false;
    }
  }

  /// Run all Firebase tests
  static Future<Map<String, bool>> testAll() async {
    final results = <String, bool>{};
    
    results['auth'] = await testAuth();
    results['firestore'] = await testFirestore();
    results['storage'] = await testStorage();
    
    final allPassed = results.values.every((result) => result);
    print('Firebase tests ${allPassed ? "PASSED" : "FAILED"}: $results');
    
    return results;
  }
} 