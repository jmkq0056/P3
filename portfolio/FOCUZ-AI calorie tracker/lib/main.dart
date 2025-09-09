import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'app.dart';
import 'app_theme.dart';
import 'services/training_service.dart' as training_service;
import 'services/health_service.dart';
import 'services/video_storage_service.dart';
import 'services/voice_service.dart';
import 'services/ai_image_service.dart';
import 'services/meal_service.dart';
import 'services/firestore_service.dart';
import 'package:health/health.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Import from the root directory, not config/
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  try {
    // Check if Firebase is already initialized to prevent duplicate app error
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      print('Firebase initialized successfully');
    } else {
      print('Firebase already initialized');
    }
  } catch (e) {
    print('Error initializing Firebase: $e');
    // Show an alert or fallback to local storage if Firebase fails to initialize
  }
  
  // Sign in anonymously if not already authenticated
  try {
    final FirebaseAuth auth = FirebaseAuth.instance;
    if (auth.currentUser == null) {
      await auth.signInAnonymously();
      print('Signed in anonymously: ${auth.currentUser?.uid}');
    } else {
      print('User already signed in: ${auth.currentUser?.uid}');
    }
  } catch (e) {
    print('Error signing in anonymously: $e');
  }
  
  // Initialize Firestore service first
  try {
    final firestoreService = FirestoreService();
    await firestoreService.init();
    print('Firestore service initialized');
    
    // Start migration if not completed
    if (!firestoreService.migrationCompleted) {
      // Schedule migration after app initialization
      Future.delayed(const Duration(seconds: 3), () async {
        await firestoreService.migrateFromSharedPreferences();
        print('Migration to Firestore completed');
      });
    }
  } catch (e) {
    print('Error initializing Firestore service: $e');
  }
  
  // Clear any cached health data on app start to ensure fresh data
  try {
    final prefs = await SharedPreferences.getInstance();
    final healthCacheKeys = prefs.getKeys().where((key) => key.startsWith('health_') || key.contains('steps')).toList();
    
    if (healthCacheKeys.isNotEmpty) {
      print('Clearing ${healthCacheKeys.length} cached health data items');
      for (final key in healthCacheKeys) {
        await prefs.remove(key);
      }
    }
  } catch (e) {
    print('Error clearing health cache: $e');
  }
  
  // Initialize health permissions
  try {
    final health = HealthFactory(useHealthConnectIfAvailable: false);
    // Request a broad range of health permissions to ensure we get accurate step data
    final types = [
      HealthDataType.STEPS,
      HealthDataType.ACTIVE_ENERGY_BURNED,
      HealthDataType.DISTANCE_WALKING_RUNNING,
      HealthDataType.WORKOUT,
      HealthDataType.MOVE_MINUTES,
    ];
    final permissions = types.map((e) => HealthDataAccess.READ).toList();
    
    // Revoke and re-request permissions
    try {
      await health.revokePermissions();
    } catch (e) {
      print('Error revoking health permissions: $e');
    }
    
    final authorized = await health.requestAuthorization(types, permissions: permissions);
    print('Health authorization result: $authorized');
  } catch (e) {
    print('Error initializing health permissions: $e');
  }
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Set status bar style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize services
  try {
    final healthService = HealthService();
    await healthService.init();
    
    final trainingService = training_service.TrainingService();
    await trainingService.init();
    
    final videoStorageService = VideoStorageService();
    await videoStorageService.init();
    
    final voiceService = VoiceService();
    await voiceService.initialize();
    
    final mealService = MealService();
    await mealService.init();
    
    final aiImageService = AIImageService();
    
    print('All services initialized successfully');
  } catch (e) {
    print('Error initializing services: $e');
    // Continue anyway - the services will auto-initialize when used
  }

  runApp(const FocuzApp());
}

// This class is no longer used since we're using FocuzApp from app.dart
// class MainApp extends StatelessWidget {
//   const MainApp({super.key});
// 
//   @override
//   Widget build(BuildContext context) {
//     return const MaterialApp(
//       home: Scaffold(
//         body: Center(
//           child: Text('Hello World!'),
//         ),
//       ),
//     );
//   }
// }
