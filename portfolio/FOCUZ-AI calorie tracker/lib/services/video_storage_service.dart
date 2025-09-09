import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';
import 'package:path/path.dart' as path;
import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'auth_service.dart';

class VideoStorageService {
  static final VideoStorageService _instance = VideoStorageService._internal();
  
  factory VideoStorageService() {
    return _instance;
  }
  
  VideoStorageService._internal();
  
  late SharedPreferences _prefs;
  final String _videoListKey = 'stored_video_paths';
  final String _metadataPrefix = 'video_metadata_';
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final AuthService _authService = AuthService();
  
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }
  
  /// Save a video file to the app's document directory and Firebase Storage if user is authenticated
  Future<String?> saveVideo(File videoFile, {Map<String, dynamic>? metadata}) async {
    try {
      // Generate a unique identifier for the video
      final videoId = const Uuid().v4();
      
      // Get app document directory for storing the video
      final appDir = await getApplicationDocumentsDirectory();
      final videoDir = Directory('${appDir.path}/videos');
      
      // Create the videos directory if it doesn't exist
      if (!await videoDir.exists()) {
        await videoDir.create(recursive: true);
      }
      
      // Define the destination path
      final fileName = '$videoId.mp4';
      final destinationPath = '${videoDir.path}/$fileName';
      
      // Check if the video is already in our directory
      if (videoFile.path == destinationPath) {
        debugPrint('Video is already in our directory');
        
        // Just update metadata and return the path
        final videoMetadata = {
          'id': videoId,
          'path': destinationPath,
          'fileName': fileName,
          'savedAt': DateTime.now().toIso8601String(),
          ...?metadata,
        };
        
        await _saveMetadata(videoId, videoMetadata);
        await _addVideoIdToList(videoId);
        
        // If user is authenticated, upload to Firebase Storage
        await _uploadToFirebaseIfAuthenticated(videoFile, videoId, videoMetadata);
        
        return destinationPath;
      }
      
      // Copy the video file to the new location
      await videoFile.copy(destinationPath);
      debugPrint('Video copied to: $destinationPath');
      
      // Add the metadata with the video path included
      final videoMetadata = {
        'id': videoId,
        'path': destinationPath,
        'fileName': fileName,
        'savedAt': DateTime.now().toIso8601String(),
        ...?metadata,
      };
      
      // Store the metadata in SharedPreferences
      await _saveMetadata(videoId, videoMetadata);
      
      // Add the ID to the list of stored videos
      await _addVideoIdToList(videoId);
      
      // If user is authenticated, upload to Firebase Storage
      await _uploadToFirebaseIfAuthenticated(videoFile, videoId, videoMetadata);
      
      return destinationPath;
    } catch (e) {
      debugPrint('Error saving video: $e');
      return null;
    }
  }
  
  /// Upload video to Firebase Storage if user is authenticated
  Future<void> _uploadToFirebaseIfAuthenticated(File videoFile, String videoId, Map<String, dynamic> metadata) async {
    try {
      // Check if user is authenticated
      if (_authService.isSignedIn) {
        final userId = _authService.currentUser?.uid;
        
        if (userId != null) {
          debugPrint('Uploading video to Firebase Storage');
          
          // Reference to the video location in Firebase Storage
          final storageRef = _storage.ref().child('users/$userId/videos/$videoId.mp4');
          
          // Upload the video
          final uploadTask = storageRef.putFile(
            videoFile,
            SettableMetadata(
              contentType: 'video/mp4',
              customMetadata: {
                'videoId': videoId,
                'userId': userId,
                'savedAt': DateTime.now().toIso8601String(),
                'title': metadata['title'] ?? 'Untitled Video',
                'description': metadata['description'] ?? '',
              },
            ),
          );
          
          // Wait for the upload to complete
          final snapshot = await uploadTask;
          
          // Get the download URL
          final downloadUrl = await snapshot.ref.getDownloadURL();
          
          // Update metadata with cloud reference
          metadata['cloudPath'] = 'users/$userId/videos/$videoId.mp4';
          metadata['downloadUrl'] = downloadUrl;
          metadata['synced'] = true;
          
          // Save updated metadata
          await _saveMetadata(videoId, metadata);
          
          debugPrint('Video uploaded to Firebase Storage: $downloadUrl');
        }
      } else {
        debugPrint('User not authenticated, skipping Firebase Storage upload');
        
        // Mark as not synced
        metadata['synced'] = false;
        await _saveMetadata(videoId, metadata);
      }
    } catch (e) {
      debugPrint('Error uploading to Firebase Storage: $e');
      
      // Mark as failed sync
      metadata['syncFailed'] = true;
      metadata['syncError'] = e.toString();
      await _saveMetadata(videoId, metadata);
    }
  }
  
  /// Sync all local videos to Firebase Storage
  Future<int> syncAllVideosToCloud() async {
    try {
      if (!_authService.isSignedIn) {
        debugPrint('User not authenticated, cannot sync videos');
        return 0;
      }
      
      final userId = _authService.currentUser?.uid;
      if (userId == null) {
        debugPrint('User ID is null, cannot sync videos');
        return 0;
      }
      
      // Get all video metadata
      final allMetadata = await getAllVideosMetadata();
      int syncedCount = 0;
      
      // Filter videos that haven't been synced
      final unsynced = allMetadata.where((metadata) => 
        metadata['synced'] != true || metadata['syncFailed'] == true
      ).toList();
      
      for (final metadata in unsynced) {
        final videoId = metadata['id'];
        final localPath = metadata['path'];
        
        if (videoId != null && localPath != null) {
          final videoFile = await _findVideoFile(localPath);
          
          if (videoFile != null && await videoFile.exists()) {
            // Reference to the video location in Firebase Storage
            final storageRef = _storage.ref().child('users/$userId/videos/$videoId.mp4');
            
            // Upload the video
            final uploadTask = storageRef.putFile(
              videoFile,
              SettableMetadata(
                contentType: 'video/mp4',
                customMetadata: {
                  'videoId': videoId,
                  'userId': userId,
                  'savedAt': metadata['savedAt'] ?? DateTime.now().toIso8601String(),
                  'title': metadata['title'] ?? 'Untitled Video',
                  'description': metadata['description'] ?? '',
                },
              ),
            );
            
            // Wait for the upload to complete
            final snapshot = await uploadTask;
            
            // Get the download URL
            final downloadUrl = await snapshot.ref.getDownloadURL();
            
            // Update metadata with cloud reference
            metadata['cloudPath'] = 'users/$userId/videos/$videoId.mp4';
            metadata['downloadUrl'] = downloadUrl;
            metadata['synced'] = true;
            metadata.remove('syncFailed');
            metadata.remove('syncError');
            
            // Save updated metadata
            await _saveMetadata(videoId, metadata);
            
            syncedCount++;
            debugPrint('Synced video to cloud: $videoId');
          }
        }
      }
      
      return syncedCount;
    } catch (e) {
      debugPrint('Error syncing videos to cloud: $e');
      return 0;
    }
  }
  
  /// Load all saved video metadata
  Future<List<Map<String, dynamic>>> getAllVideosMetadata() async {
    final videoIds = _getVideoIdList();
    final List<Map<String, dynamic>> allMetadata = [];
    
    for (final id in videoIds) {
      final metadata = await getVideoMetadata(id);
      if (metadata != null) {
        allMetadata.add(metadata);
      }
    }
    
    return allMetadata;
  }
  
  /// Get metadata for a specific video
  Future<Map<String, dynamic>?> getVideoMetadata(String videoId) async {
    final key = _metadataPrefix + videoId;
    final jsonData = _prefs.getString(key);
    
    if (jsonData != null) {
      try {
        final Map<String, dynamic> metadata = json.decode(jsonData);
        
        // Get the path from metadata
        final videoPath = metadata['path'];
        if (videoPath == null) {
          return null;
        }
        
        // Try to locate the file with different path variations for iOS
        final file = await _findVideoFile(videoPath);
        
        if (file != null && await file.exists()) {
          // Update the path in metadata if it differs
          if (file.path != videoPath) {
            metadata['path'] = file.path;
            await _saveMetadata(videoId, metadata);
          }
          return metadata;
        } else {
          // Check if we have a cloud version
          if (metadata['cloudPath'] != null && metadata['downloadUrl'] != null) {
            // File exists in the cloud but not locally
            metadata['locallyDeleted'] = true;
            await _saveMetadata(videoId, metadata);
            return metadata;
          } else {
            // File doesn't exist locally or in the cloud, remove the metadata
          await deleteVideo(videoId);
          return null;
          }
        }
      } catch (e) {
        debugPrint('Error parsing video metadata: $e');
        return null;
      }
    }
    
    return null;
  }
  
  /// Try to find a video file with various path interpretations
  Future<File?> _findVideoFile(String videoPath) async {
    try {
      // First try the direct path
      final directFile = File(videoPath);
      if (await directFile.exists()) {
        return directFile;
      }
      
      // Try lowercase path (iOS might use lowercase)
      final lowerCasePath = videoPath.replaceAll('/Documents/', '/documents/');
      final lowerCaseFile = File(lowerCasePath);
      if (await lowerCaseFile.exists()) {
        return lowerCaseFile;
      }
      
      // Try uppercase path (iOS might use uppercase)
      final upperCasePath = videoPath.replaceAll('/documents/', '/Documents/');
      final upperCaseFile = File(upperCasePath);
      if (await upperCaseFile.exists()) {
        return upperCaseFile;
      }
      
      // Try extracting just the filename and looking in our videos directory
      final fileName = path.basename(videoPath);
      final appDir = await getApplicationDocumentsDirectory();
      final videoDirPath = '${appDir.path}/videos';
      final potentialPath = '$videoDirPath/$fileName';
      final potentialFile = File(potentialPath);
      
      if (await potentialFile.exists()) {
        return potentialFile;
      }
      
      return null;
    } catch (e) {
      debugPrint('Error finding video file: $e');
      return null;
    }
  }
  
  /// Delete a video file and its metadata
  Future<bool> deleteVideo(String videoId) async {
    try {
      final metadata = await getVideoMetadata(videoId);
      
      if (metadata != null) {
        // Delete the local file
        final filePath = metadata['path'];
        if (filePath != null) {
          final file = await _findVideoFile(filePath);
          if (file != null && await file.exists()) {
            await file.delete();
          }
        }
        
        // Delete from Firebase Storage if authenticated
        if (_authService.isSignedIn && metadata['cloudPath'] != null) {
          try {
            final storageRef = _storage.ref().child(metadata['cloudPath']);
            await storageRef.delete();
            debugPrint('Deleted video from Firebase Storage: ${metadata['cloudPath']}');
          } catch (e) {
            debugPrint('Error deleting from Firebase Storage: $e');
          }
        }
        
        // Remove metadata
        await _prefs.remove(_metadataPrefix + videoId);
        
        // Remove from list
        await _removeVideoIdFromList(videoId);
        
        return true;
      }
      
      return false;
    } catch (e) {
      debugPrint('Error deleting video: $e');
      return false;
    }
  }
  
  /// Update metadata for a video
  Future<bool> updateVideoMetadata(String videoId, Map<String, dynamic> newMetadata) async {
    try {
      final existingMetadata = await getVideoMetadata(videoId);
      
      if (existingMetadata != null) {
        // Merge existing metadata with new metadata
        final updatedMetadata = {
          ...existingMetadata,
          ...newMetadata,
          'updatedAt': DateTime.now().toIso8601String(),
        };
        
        // Save the updated metadata
        await _saveMetadata(videoId, updatedMetadata);
        
        return true;
      }
      
      return false;
    } catch (e) {
      debugPrint('Error updating video metadata: $e');
      return false;
    }
  }
  
  // Private helper methods
  
  Future<void> _saveMetadata(String videoId, Map<String, dynamic> metadata) async {
    final key = _metadataPrefix + videoId;
    final jsonData = json.encode(metadata);
    await _prefs.setString(key, jsonData);
  }
  
  Future<void> _addVideoIdToList(String videoId) async {
    final videoIds = _getVideoIdList();
    if (!videoIds.contains(videoId)) {
      videoIds.add(videoId);
      await _prefs.setStringList(_videoListKey, videoIds);
    }
  }
  
  Future<void> _removeVideoIdFromList(String videoId) async {
    final videoIds = _getVideoIdList();
    if (videoIds.contains(videoId)) {
      videoIds.remove(videoId);
      await _prefs.setStringList(_videoListKey, videoIds);
    }
  }
  
  List<String> _getVideoIdList() {
    return _prefs.getStringList(_videoListKey) ?? [];
  }
  
  /// Check if a video exists by path
  Future<bool> videoExists(String path) async {
    final file = await _findVideoFile(path);
    return file != null && await file.exists();
  }
} 