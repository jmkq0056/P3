import 'dart:io';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:lottie/lottie.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/assets.dart';
import '../../core/constants.dart';
import '../../models/training.dart';
import '../../services/training_service.dart';
import '../../services/cloudinary_service.dart';
import '../../widgets/video_preview_player.dart';

class TrainingFormScreen extends StatefulWidget {
  final Training? existingTraining;

  const TrainingFormScreen({super.key, this.existingTraining});

  @override
  State<TrainingFormScreen> createState() => _TrainingFormScreenState();
}

class _TrainingFormScreenState extends State<TrainingFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final TrainingService _trainingService = TrainingService();
  final CloudinaryService _cloudinaryService = CloudinaryService();
  final ImagePicker _imagePicker = ImagePicker();
  
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _caloriesController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();
  
  String _selectedType = 'running';
  DateTime _selectedDate = DateTime.now();
  String? _videoUrl; // Changed from _videoPath to _videoUrl for Cloudinary
  File? _selectedVideoFile; // Store selected video file before upload
  bool _isLoading = false;
  bool _isUploadingVideo = false;
  
  // Training type options
  final List<Map<String, dynamic>> _trainingTypes = [
    {'type': 'running', 'name': 'Running', 'icon': FontAwesomeIcons.personRunning},
    {'type': 'weights', 'name': 'Weights', 'icon': FontAwesomeIcons.dumbbell},
    {'type': 'yoga', 'name': 'Yoga', 'icon': FontAwesomeIcons.hands},
    {'type': 'cycling', 'name': 'Cycling', 'icon': FontAwesomeIcons.bicycle},
    {'type': 'swimming', 'name': 'Swimming', 'icon': FontAwesomeIcons.personSwimming},
    {'type': 'hiit', 'name': 'HIIT', 'icon': FontAwesomeIcons.stopwatch},
  ];

  @override
  void initState() {
    super.initState();
    _initService();
    
    // Populate form if editing existing session
    if (widget.existingTraining != null) {
      _titleController.text = widget.existingTraining!.title;
      _caloriesController.text = widget.existingTraining!.calories.toString();
      _durationController.text = widget.existingTraining!.duration.toString();
      _selectedType = widget.existingTraining!.type;
      _selectedDate = widget.existingTraining!.date;
      _videoUrl = widget.existingTraining!.videoUrl; // Use existing Cloudinary URL
      
      debugPrint('Editing training with video URL: $_videoUrl');
    }
  }

  Future<void> _initService() async {
    setState(() {
      _isLoading = true;
    });
    
    await _trainingService.init();
    
    setState(() {
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _caloriesController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingTraining != null;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Training' : 'Add Training'),
        actions: [
          if (isEditing)
            IconButton(
              icon: FaIcon(
                AppAssets.iconDelete,
                color: AppColors.error,
                size: AppDimensions.iconMedium,
              ),
              onPressed: () {
                _showDeleteConfirmation();
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(AppDimensions.s16),
                  children: [
                    // Training type selection
                    Text(
                      'Training Type',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppDimensions.s12),
                    
                    _buildTrainingTypeSelector(),
                    const SizedBox(height: AppDimensions.s24),
                    
                    // Title input
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.title),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a title';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppDimensions.s16),
                    
                    // Date selector
                    InkWell(
                      onTap: () => _selectDate(context),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Date',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(
                          _formatDate(_selectedDate),
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppDimensions.s16),
                    
                    // Two fields in one row: Duration and Calories
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _durationController,
                            decoration: const InputDecoration(
                              labelText: 'Duration (min)',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.timer),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Required';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: AppDimensions.s16),
                        Expanded(
                          child: TextFormField(
                            controller: _caloriesController,
                            decoration: const InputDecoration(
                              labelText: 'Calories (kcal)',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.local_fire_department),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Required';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.s24),
                    
                    // Video attachment and preview
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Training Video (max 20 seconds)',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppDimensions.s12),
                        
                        // Show video preview if we have a video
                        if (_videoUrl != null || _selectedVideoFile != null) ...[
                          Container(
                            height: 200,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                            ),
                            child: Stack(
                              children: [
                                // Video preview
                                if (_videoUrl != null)
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                                    child: VideoPreviewPlayer(
                                      videoPath: _videoUrl!,
                                      height: 200,
                                    ),
                                  )
                                else if (_selectedVideoFile != null)
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                                    child: VideoPreviewPlayer(
                                      videoPath: _selectedVideoFile!.path,
                                      height: 200,
                                    ),
                                  ),
                                
                                // Remove button
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: IconButton(
                                      icon: const Icon(Icons.close, color: Colors.white),
                                      onPressed: () {
                                        setState(() {
                                          _videoUrl = null;
                                          _selectedVideoFile = null;
                                        });
                                      },
                                    ),
                                  ),
                                ),
                                
                                // Upload progress overlay
                                if (_isUploadingVideo)
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                                    ),
                                    child: const Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          CircularProgressIndicator(color: Colors.white),
                                          SizedBox(height: 8),
                                          Text(
                                            'Uploading video...',
                                            style: TextStyle(color: Colors.white),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppDimensions.s12),
                        ],
                        
                        // Attach video button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isUploadingVideo ? null : _attachVideo,
                            icon: FaIcon(
                              (_videoUrl == null && _selectedVideoFile == null) 
                                  ? AppAssets.iconVideo 
                                  : Icons.edit,
                              size: AppDimensions.iconMedium,
                            ),
                            label: Text(
                              (_videoUrl == null && _selectedVideoFile == null) 
                                  ? 'Record Workout Video' 
                                  : 'Change Video'
                            ),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: AppDimensions.s16),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.s16),
                    
                    // Lottie animation (only show if no video)
                    if (_videoUrl == null && _selectedVideoFile == null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: AppDimensions.s16),
                        child: Center(
                          child: Lottie.asset(
                            AppAssets.lottieTraining,
                            width: 200,
                            height: 200,
                            repeat: true,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 150,
                                width: 150,
                                decoration: BoxDecoration(
                                  color: AppColors.accent.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: FaIcon(
                                    _getIconForType(_selectedType),
                                    size: 80,
                                    color: AppColors.accent,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    
                    // Save button
                    ElevatedButton(
                      onPressed: _isUploadingVideo ? null : _saveTraining,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: AppDimensions.s16),
                      ),
                      child: _isUploadingVideo 
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text('Uploading...'),
                              ],
                            )
                          : Text(isEditing ? 'Save Changes' : 'Add Training'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTrainingTypeSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _trainingTypes.map((type) {
          final isSelected = _selectedType == type['type'];
          
          return Padding(
            padding: const EdgeInsets.only(right: AppDimensions.s12),
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedType = type['type'];
                });
              },
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              child: AnimatedContainer(
                duration: AppDurations.short,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.s16,
                  vertical: AppDimensions.s12,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.accent
                      : Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.accent
                        : Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    FaIcon(
                      type['icon'],
                      size: AppDimensions.iconMedium,
                      color: isSelected
                          ? Colors.white
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                    const SizedBox(width: AppDimensions.s8),
                    Text(
                      type['name'],
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : Theme.of(context).colorScheme.onSurface,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _attachVideo() async {
    try {
      // Show options for camera or gallery
      final source = await showModalBottomSheet<ImageSource>(
        context: context,
        builder: (BuildContext context) {
          return SafeArea(
            child: Wrap(
              children: <Widget>[
                ListTile(
                  leading: const Icon(Icons.videocam),
                  title: const Text('Record Video'),
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Choose from Gallery'),
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                ),
              ],
            ),
          );
        },
      );

      if (source == null) return;

      // Set maximum duration to 20 seconds
      final XFile? videoFile = await _imagePicker.pickVideo(
        source: source,
        maxDuration: const Duration(seconds: 20),
      );

      if (videoFile != null) {
        setState(() {
          _selectedVideoFile = File(videoFile.path);
          _videoUrl = null; // Clear existing URL when selecting new video
        });

        // Upload video to Cloudinary immediately
        await _uploadVideoToCloudinary();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking video: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _uploadVideoToCloudinary() async {
    if (_selectedVideoFile == null) return;

    setState(() {
      _isUploadingVideo = true;
    });

    try {
      debugPrint('Uploading video to Cloudinary...');
      
      // Generate a custom filename with user UUID and date
      final customFileName = '${DateTime.now().millisecondsSinceEpoch}_${_selectedType}_training';
      
      final videoUrl = await _cloudinaryService.uploadVideo(
        _selectedVideoFile!,
        customFileName: customFileName,
        videoType: 'training',
      );

      if (videoUrl != null) {
        setState(() {
          _videoUrl = videoUrl;
          _selectedVideoFile = null; // Clear the file reference after successful upload
          _isUploadingVideo = false;
        });

        debugPrint('Video uploaded successfully: $videoUrl');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Video uploaded successfully!'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        throw Exception('Failed to upload video');
      }
    } catch (e) {
      setState(() {
        _isUploadingVideo = false;
      });

      debugPrint('Error uploading video: $e');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error uploading video: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _saveTraining() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      
      try {
        final calories = int.parse(_caloriesController.text);
        final duration = int.parse(_durationController.text);
        
        // If we have a selected video file but no URL, upload it first
        if (_selectedVideoFile != null && _videoUrl == null) {
          await _uploadVideoToCloudinary();
        }
        
        if (widget.existingTraining != null) {
          // Update existing training
          final updatedTraining = widget.existingTraining!.copyWith(
            title: _titleController.text,
            date: _selectedDate,
            calories: calories,
            duration: duration,
            type: _selectedType,
            videoUrl: _videoUrl, // Use Cloudinary URL
          );
          
          await _trainingService.updateTraining(updatedTraining);
        } else {
          // Create new training
          final newTraining = Training(
            title: _titleController.text,
            date: _selectedDate,
            calories: calories,
            duration: duration,
            type: _selectedType,
            videoUrl: _videoUrl, // Use Cloudinary URL
          );
          
          await _trainingService.addTraining(newTraining);
        }
        
        // Return success to previous screen
        if (mounted) {
          Navigator.pop(context, true);
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Training?'),
        content: Text('Are you sure you want to delete "${widget.existingTraining!.title}"?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              
              setState(() {
                _isLoading = true;
              });
              
              try {
                await _trainingService.deleteTraining(widget.existingTraining!.id);
                
                if (mounted) {
                  Navigator.pop(context, true); // Go back to training list with refresh flag
                }
              } catch (e) {
                setState(() {
                  _isLoading = false;
                });
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error deleting: ${e.toString()}'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // Helper to get the appropriate icon for training type
  IconData _getIconForType(String type) {
    final foundType = _trainingTypes.firstWhere(
      (element) => element['type'] == type,
      orElse: () => {'type': type, 'icon': AppAssets.iconTraining},
    );
    
    return foundType['icon'];
  }

  // Helper to format date
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return 'Today';
    } else if (date.year == yesterday.year && date.month == yesterday.month && date.day == yesterday.day) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
} 