import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import './firestore_service.dart';

class CloudinaryService {
  static final CloudinaryService _instance = CloudinaryService._internal();
  factory CloudinaryService() => _instance;
  
  // Singleton instance
  CloudinaryService._internal() {
    // Initialize in constructor to avoid multiple init calls
    _cloudinary = CloudinaryPublic(_cloudName, _uploadPreset, cache: false);
    debugPrint('Cloudinary service initialized with cloud name: $_cloudName and preset: $_uploadPreset');
  }

  // Cloudinary credentials - cloudName must match exactly what's in your Cloudinary account
  final String _cloudName = 'deid4hvdc';
  
  // The upload preset must be created in your Cloudinary dashboard and set to "unsigned"
  // You need to create this preset in your Cloudinary dashboard -> Settings -> Upload -> Upload presets
  final String _uploadPreset = 'fdzdajit'; // Using user-provided preset
  
  // Cloudinary instance
  late final CloudinaryPublic _cloudinary;
  
  // Firestore service instance for saving image metadata
  final FirestoreService _firestoreService = FirestoreService();

  // Initialize the service - kept for backward compatibility
  void init() {
    // No-op as initialization is now done in constructor
    debugPrint('CloudinaryService.init() called but initialization already done in constructor');
  }

  // Upload an image with user-specific folder and save metadata to Firestore
  Future<String> uploadImage(File imageFile, {String? customFileName, String? imageType = 'meal'}) async {
    try {
      // Get current user ID
      final userId = _firestoreService.userId;
      
      debugPrint('Uploading image to Cloudinary for user: $userId');
      debugPrint('Image path: ${imageFile.path} using preset: $_uploadPreset');
      
      // Generate a unique filename if not provided
      final fileName = customFileName ?? '${const Uuid().v4()}_${DateTime.now().millisecondsSinceEpoch}';
      
      // Create user-specific folder structure: users/{userId}/{imageType}/
      final folder = 'users/$userId/$imageType';
      
      // Create CloudinaryResponse
      final response = await _cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          imageFile.path,
          folder: folder,
          resourceType: CloudinaryResourceType.Image, // Explicitly set for images
          publicId: fileName,
        ),
      );
      
      // Log the successful upload
      debugPrint('Image uploaded successfully: ${response.secureUrl}');
      debugPrint('Image stored in folder: $folder');
      
      // Save image metadata to Firestore
      await _saveImageMetadataToFirestore(
        imageUrl: response.secureUrl,
        fileName: fileName,
        folder: folder,
        imageType: imageType ?? 'meal',
        userId: userId,
      );
      
      return response.secureUrl;
    } catch (e) {
      debugPrint('Error uploading image to Cloudinary: $e');
      rethrow;
    }
  }

  // Upload a video with user-specific folder and save metadata to Firestore
  Future<String> uploadVideo(File videoFile, {String? customFileName, String? videoType = 'training'}) async {
    try {
      // Get current user ID
      final userId = _firestoreService.userId;
      
      debugPrint('Uploading video to Cloudinary for user: $userId');
      debugPrint('Video path: ${videoFile.path} using preset: $_uploadPreset');
      
      // Generate a unique filename if not provided
      final fileName = customFileName ?? '${const Uuid().v4()}_${DateTime.now().millisecondsSinceEpoch}';
      
      // Create user-specific folder structure: users/{userId}/{videoType}/
      final folder = 'users/$userId/$videoType';
      
      // Create CloudinaryResponse
      final response = await _cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          videoFile.path,
          folder: folder,
          resourceType: CloudinaryResourceType.Video,
          publicId: fileName,
        ),
      );
      
      // Log the successful upload
      debugPrint('Video uploaded successfully: ${response.secureUrl}');
      debugPrint('Video stored in folder: $folder');
      
      // Save video metadata to Firestore
      await _saveVideoMetadataToFirestore(
        videoUrl: response.secureUrl,
        fileName: fileName,
        folder: folder,
        videoType: videoType ?? 'training',
        userId: userId,
      );
      
      return response.secureUrl;
    } catch (e) {
      debugPrint('Error uploading video to Cloudinary: $e');
      rethrow;
    }
  }
  
  // Save image metadata to Firestore under user's images collection
  Future<void> _saveImageMetadataToFirestore({
    required String imageUrl,
    required String fileName,
    required String folder,
    required String imageType,
    required String userId,
  }) async {
    try {
      final imageId = const Uuid().v4();
      final imageData = {
        'id': imageId,
        'url': imageUrl,
        'fileName': fileName,
        'folder': folder,
        'type': imageType,
        'userId': userId,
        'uploadedAt': DateTime.now().toIso8601String(),
        'cloudinaryPath': '$folder/$fileName',
      };
      
      // Save to Firestore under users/{userId}/images/{imageId}
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('images')
          .doc(imageId)
          .set(imageData);
      
      debugPrint('Image metadata saved to Firestore: $imageId');
    } catch (e) {
      debugPrint('Error saving image metadata to Firestore: $e');
      // Don't rethrow - we don't want to fail the upload if metadata save fails
    }
  }
  
  // Save video metadata to Firestore under user's videos collection
  Future<void> _saveVideoMetadataToFirestore({
    required String videoUrl,
    required String fileName,
    required String folder,
    required String videoType,
    required String userId,
  }) async {
    try {
      final videoId = const Uuid().v4();
      final videoData = {
        'id': videoId,
        'url': videoUrl,
        'fileName': fileName,
        'folder': folder,
        'type': videoType,
        'userId': userId,
        'uploadedAt': DateTime.now().toIso8601String(),
        'cloudinaryPath': '$folder/$fileName',
      };
      
      // Save to Firestore under users/{userId}/videos/{videoId}
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('videos')
          .doc(videoId)
          .set(videoData);
      
      debugPrint('Video metadata saved to Firestore: $videoId');
    } catch (e) {
      debugPrint('Error saving video metadata to Firestore: $e');
      // Don't rethrow - we don't want to fail the upload if metadata save fails
    }
  }
  
  // Get user's images from Firestore
  Future<List<Map<String, dynamic>>> getUserImages({String? imageType}) async {
    try {
      final userId = _firestoreService.userId;
      var query = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('images')
          .orderBy('uploadedAt', descending: true);
      
      if (imageType != null) {
        query = query.where('type', isEqualTo: imageType);
      }
      
      final snapshot = await query.get();
      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      debugPrint('Error getting user images: $e');
      return [];
    }
  }
  
  // Get user's videos from Firestore
  Future<List<Map<String, dynamic>>> getUserVideos({String? videoType}) async {
    try {
      final userId = _firestoreService.userId;
      var query = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('videos')
          .orderBy('uploadedAt', descending: true);
      
      if (videoType != null) {
        query = query.where('type', isEqualTo: videoType);
      }
      
      final snapshot = await query.get();
      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      debugPrint('Error getting user videos: $e');
      return [];
    }
  }
} 