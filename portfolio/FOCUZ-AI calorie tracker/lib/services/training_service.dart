import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/training.dart';
import './firestore_service.dart';
import './cloudinary_service.dart';

class TrainingService {
  static const String _trainingStorageKey = 'trainings';
  List<Training> _trainings = [];
  bool _isInitialized = false;
  
  // Firestore service
  final FirestoreService _firestoreService = FirestoreService();
  
  // Cloudinary service for video uploads
  final CloudinaryService _cloudinaryService = CloudinaryService();
  
  // Flag to track if data should be loaded from local or Firestore
  bool _useFirestore = false;
  
  Future<void> init() async {
    if (_isInitialized) return;
    
    // Check if migration is completed
    final prefs = await SharedPreferences.getInstance();
    final migrationKey = 'firestore_migration_completed_${_firestoreService.userId}';
    _useFirestore = prefs.getBool(migrationKey) ?? false;
    
    // Initialize Firestore service
    await _firestoreService.init();
    
    // Load trainings based on storage type
    if (_useFirestore) {
      await _loadTrainingsFromFirestore();
    } else {
      await _loadTrainings();
    }
    
    _isInitialized = true;
  }
  
  Future<void> _loadTrainingsFromFirestore() async {
    try {
      _trainings = await _firestoreService.getAllTrainings();
      debugPrint('Loaded ${_trainings.length} trainings from Firestore');
    } catch (e) {
      debugPrint('Error loading trainings from Firestore: $e');
      _trainings = [];
    }
  }
  
  Future<void> _loadTrainings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final trainingData = prefs.getString(_trainingStorageKey);
      
      if (trainingData != null && trainingData.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(trainingData);
        _trainings = decoded.map((item) => Training.fromJson(item)).toList();
        debugPrint('Loaded ${_trainings.length} trainings from SharedPreferences');
      } else {
        _trainings = [];
        debugPrint('No trainings found in SharedPreferences');
      }
    } catch (e) {
      debugPrint('Error loading trainings: $e');
      _trainings = [];
    }
  }
  
  Future<bool> _saveTrainings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = _trainings.map((training) => training.toJson()).toList();
      final encoded = jsonEncode(data);
      final success = await prefs.setString(_trainingStorageKey, encoded);
      
      if (success) {
        debugPrint('Successfully saved ${_trainings.length} trainings to SharedPreferences');
      } else {
        debugPrint('Failed to save trainings to SharedPreferences');
      }
      
      return success;
    } catch (e) {
      debugPrint('Error saving trainings to SharedPreferences: $e');
      return false;
    }
  }
  
  // Add a training
  Future<bool> addTraining(Training training) async {
    _trainings.add(training);
    
    if (_useFirestore) {
      try {
        await _firestoreService.saveTraining(training);
        debugPrint('Successfully saved training to Firestore');
        return true;
      } catch (e) {
        debugPrint('Error saving training to Firestore: $e');
        return false;
      }
    } else {
      return await _saveTrainings();
    }
  }
  
  // Update a training
  Future<bool> updateTraining(Training training) async {
    final index = _trainings.indexWhere((t) => t.id == training.id);
    if (index >= 0) {
      _trainings[index] = training;
      
      if (_useFirestore) {
        try {
          await _firestoreService.saveTraining(training);
          debugPrint('Successfully updated training in Firestore');
          return true;
        } catch (e) {
          debugPrint('Error updating training in Firestore: $e');
          return false;
        }
      } else {
        return await _saveTrainings();
      }
    }
    return false;
  }
  
  // Delete a training
  Future<bool> deleteTraining(String id) async {
    _trainings.removeWhere((t) => t.id == id);
    
    if (_useFirestore) {
      try {
        await _firestoreService.deleteTraining(id);
        debugPrint('Successfully deleted training from Firestore');
        return true;
      } catch (e) {
        debugPrint('Error deleting training from Firestore: $e');
        return false;
      }
    } else {
      return await _saveTrainings();
    }
  }
  
  // Get all trainings
  List<Training> getAllTrainings() {
    return List<Training>.from(_trainings);
  }
  
  // Get trainings for a specific day
  List<Training> getTrainingsForDay(DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    
    return _trainings.where((training) {
      final trainingDate = DateTime(training.date.year, training.date.month, training.date.day);
      return trainingDate.year == start.year && 
             trainingDate.month == start.month && 
             trainingDate.day == start.day;
    }).toList();
  }
  
  // Get trainings for a month
  List<Training> getTrainingsForMonth(DateTime date) {
    return _trainings.where((training) {
      return training.date.year == date.year && training.date.month == date.month;
    }).toList();
  }
  
  // Get total calories burned in a specific date range
  int getTotalCaloriesBurned(DateTime startDate, DateTime endDate) {
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
    
    return _trainings
        .where((training) => training.date.isAfter(start.subtract(const Duration(minutes: 1))) && 
                             training.date.isBefore(end.add(const Duration(minutes: 1))))
        .fold(0, (sum, training) => sum + training.calories);
  }
  
  // Get total duration in minutes in a specific date range
  int getTotalDuration(DateTime startDate, DateTime endDate) {
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
    
    return _trainings
        .where((training) => training.date.isAfter(start.subtract(const Duration(minutes: 1))) && 
                             training.date.isBefore(end.add(const Duration(minutes: 1))))
        .fold(0, (sum, training) => sum + training.duration);
  }
  
  // Clear all trainings (for testing or user logout)
  Future<bool> clearAllTrainings() async {
    try {
      _trainings = [];
      
      if (_useFirestore) {
        // We can't delete all trainings at once from Firestore
        // We would need to fetch all and then delete one by one
        // This is a potential enhancement for future
        debugPrint('Clearing all trainings from Firestore is not supported');
        return false;
      } else {
        final prefs = await SharedPreferences.getInstance();
        final success = await prefs.remove(_trainingStorageKey);
        return success;
      }
    } catch (e) {
      debugPrint('Error clearing trainings: $e');
      return false;
    }
  }

  // Upload video to Cloudinary and return URL
  Future<String?> uploadTrainingVideo(File videoFile) async {
    try {
      debugPrint('Uploading training video to Cloudinary...');
      final videoUrl = await _cloudinaryService.uploadVideo(
        videoFile, 
        videoType: 'training',
      );
      
      if (videoUrl != null) {
        debugPrint('Successfully uploaded training video: $videoUrl');
      } else {
        debugPrint('Failed to upload training video');
      }
      
      return videoUrl;
    } catch (e) {
      debugPrint('Error uploading training video: $e');
      return null;
    }
  }

  // Add training with video upload
  Future<bool> addTrainingWithVideo({
    required String title,
    required DateTime date,
    required int calories,
    required int duration,
    required String type,
    File? videoFile,
  }) async {
    try {
      String? videoUrl;
      
      // Upload video if provided
      if (videoFile != null) {
        videoUrl = await uploadTrainingVideo(videoFile);
        if (videoUrl == null) {
          debugPrint('Failed to upload video, saving training without video');
        }
      }
      
      // Create training object
      final training = Training(
        title: title,
        date: date,
        calories: calories,
        duration: duration,
        type: type,
        videoUrl: videoUrl,
      );
      
      // Save training
      return await addTraining(training);
    } catch (e) {
      debugPrint('Error adding training with video: $e');
      return false;
    }
  }

  // Update training with video upload
  Future<bool> updateTrainingWithVideo({
    required String id,
    String? title,
    DateTime? date,
    int? calories,
    int? duration,
    String? type,
    File? videoFile,
    bool removeExistingVideo = false,
  }) async {
    try {
      // Find existing training
      final existingIndex = _trainings.indexWhere((t) => t.id == id);
      if (existingIndex < 0) {
        debugPrint('Training with id $id not found');
        return false;
      }
      
      final existingTraining = _trainings[existingIndex];
      String? videoUrl = existingTraining.videoUrl;
      
      // Handle video upload/removal
      if (removeExistingVideo) {
        videoUrl = null;
      } else if (videoFile != null) {
        final uploadedUrl = await uploadTrainingVideo(videoFile);
        if (uploadedUrl != null) {
          videoUrl = uploadedUrl;
        }
      }
      
      // Create updated training
      final updatedTraining = existingTraining.copyWith(
        title: title,
        date: date,
        calories: calories,
        duration: duration,
        type: type,
        videoUrl: videoUrl,
      );
      
      // Update training
      return await updateTraining(updatedTraining);
    } catch (e) {
      debugPrint('Error updating training with video: $e');
      return false;
    }
  }

  // Get video URL for a training
  String? getTrainingVideoUrl(String trainingId) {
    final training = _trainings.firstWhere(
      (t) => t.id == trainingId,
      orElse: () => Training(
        title: '',
        date: DateTime.now(),
        calories: 0,
        duration: 0,
        type: '',
      ),
    );
    
    return training.id.isNotEmpty ? training.videoUrl : null;
  }

  // Check if training has video
  bool hasVideo(String trainingId) {
    final videoUrl = getTrainingVideoUrl(trainingId);
    return videoUrl != null && videoUrl.isNotEmpty;
  }

  // Get all trainings with videos
  List<Training> getTrainingsWithVideos() {
    return _trainings.where((training) => 
        training.videoUrl != null && training.videoUrl!.isNotEmpty).toList();
  }
} 