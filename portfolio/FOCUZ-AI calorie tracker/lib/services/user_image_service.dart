import 'package:cloud_firestore/cloud_firestore.dart';
import './firestore_service.dart';

class UserImageService {
  static final UserImageService _instance = UserImageService._internal();
  factory UserImageService() => _instance;
  
  UserImageService._internal();
  
  final FirestoreService _firestoreService = FirestoreService();
  
  // Get user's meal images
  Future<List<Map<String, dynamic>>> getMealImages() async {
    try {
      final userId = _firestoreService.userId;
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('images')
          .where('type', isEqualTo: 'meal')
          .orderBy('uploadedAt', descending: true)
          .get();
      
      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print('Error getting meal images: $e');
      return [];
    }
  }
  
  // Get user's training images
  Future<List<Map<String, dynamic>>> getTrainingImages() async {
    try {
      final userId = _firestoreService.userId;
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('images')
          .where('type', isEqualTo: 'training')
          .orderBy('uploadedAt', descending: true)
          .get();
      
      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print('Error getting training images: $e');
      return [];
    }
  }
  
  // Get all user images
  Future<List<Map<String, dynamic>>> getAllImages() async {
    try {
      final userId = _firestoreService.userId;
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('images')
          .orderBy('uploadedAt', descending: true)
          .get();
      
      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print('Error getting all images: $e');
      return [];
    }
  }
  
  // Delete an image from Firestore (Note: This doesn't delete from Cloudinary)
  Future<bool> deleteImageMetadata(String imageId) async {
    try {
      final userId = _firestoreService.userId;
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('images')
          .doc(imageId)
          .delete();
      
      return true;
    } catch (e) {
      print('Error deleting image metadata: $e');
      return false;
    }
  }
  
  // Get images by date range
  Future<List<Map<String, dynamic>>> getImagesByDateRange(
    DateTime startDate, 
    DateTime endDate, 
    {String? imageType}
  ) async {
    try {
      final userId = _firestoreService.userId;
      var query = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('images')
          .where('uploadedAt', isGreaterThanOrEqualTo: startDate.toIso8601String())
          .where('uploadedAt', isLessThanOrEqualTo: endDate.toIso8601String());
      
      if (imageType != null) {
        query = query.where('type', isEqualTo: imageType);
      }
      
      final snapshot = await query.orderBy('uploadedAt', descending: true).get();
      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print('Error getting images by date range: $e');
      return [];
    }
  }
} 