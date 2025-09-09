import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:lottie/lottie.dart';
import 'package:intl/intl.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import '../../core/assets.dart';
import '../../core/constants.dart';
import '../../models/training.dart';
import '../../services/training_service.dart' as training_service;
import '../../widgets/video_preview_player.dart';
import '../dashboard/dashboard_screen.dart'; // Import for AppState
import 'training_form.dart';
import '../../widgets/custom_app_bar.dart';

class TrainingScreen extends StatefulWidget {
  final DateTime? selectedDate;
  
  const TrainingScreen({super.key, this.selectedDate});

  @override
  State<TrainingScreen> createState() => _TrainingScreenState();
}

class _TrainingScreenState extends State<TrainingScreen> {
  final training_service.TrainingService _trainingService = training_service.TrainingService();
  final AppState _appState = AppState();
  List<Training> _trainingSessions = [];
  bool _isLoading = true;
  // Map to store generated thumbnails
  final Map<String, Uint8List?> _thumbnails = {};

  @override
  void initState() {
    super.initState();
    _initializeService();
  }

  Future<void> _initializeService() async {
    setState(() {
      _isLoading = true;
    });
    
    await _trainingService.init();
    _loadTrainingSessions();
  }

  void _loadTrainingSessions() {
    setState(() {
      // Get all trainings and sort by date (newest first)
      _trainingSessions = _trainingService.getAllTrainings();
      _trainingSessions.sort((a, b) => b.date.compareTo(a.date));
      _isLoading = false;
    });
    
    // Generate thumbnails for videos
    for (final session in _trainingSessions) {
      if (session.videoUrl != null) {
        _generateThumbnail(session.videoUrl!);
      }
    }
  }
  
  Future<void> _generateThumbnail(String videoUrl) async {
    // Skip if already generated
    if (_thumbnails.containsKey(videoUrl)) {
      return;
    }
    
    try {
      // Check if it's a Cloudinary URL (starts with https)
      if (videoUrl.startsWith('http')) {
        // For Cloudinary URLs, use video thumbnail generation
        final thumbnailBytes = await VideoThumbnail.thumbnailData(
          video: videoUrl,
          imageFormat: ImageFormat.JPEG,
          maxWidth: 300,
          quality: 80,
        );
        
        if (thumbnailBytes != null) {
          setState(() {
            _thumbnails[videoUrl] = thumbnailBytes;
          });
        }
      } else {
        // For local files (backward compatibility)
        if (File(videoUrl).existsSync()) {
          final thumbnailBytes = await VideoThumbnail.thumbnailData(
            video: videoUrl,
            imageFormat: ImageFormat.JPEG,
            maxWidth: 300,
            quality: 80,
          );
          
          if (thumbnailBytes != null) {
            setState(() {
              _thumbnails[videoUrl] = thumbnailBytes;
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error generating thumbnail for $videoUrl: $e');
      // Set null to indicate we tried but failed
      setState(() {
        _thumbnails[videoUrl] = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Training',
        icon: AppAssets.iconFilter,
        onIconPressed: () {},
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _trainingSessions.isEmpty
              ? _buildEmptyState()
              : _buildTrainingList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const TrainingFormScreen(),
            ),
          );
          
          if (result == true) {
            _loadTrainingSessions();
            _appState.notifyDataChanged(); // Notify that data has changed to update energy balance
          }
        },
        child: FaIcon(
          AppAssets.iconAdd,
          size: AppDimensions.iconMedium,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Lottie placeholder
          Lottie.asset(
            AppAssets.lottieTraining,
            width: 200,
            repeat: true,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                height: 200,
                width: 200,
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: FaIcon(
                    AppAssets.iconTraining,
                    size: 80,
                    color: AppColors.accent,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: AppDimensions.s24),
          Text(
            'No training sessions yet',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: AppDimensions.s16),
          Text(
            'Tap the + button to add your first workout',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildTrainingList() {
    return ListView.builder(
      padding: const EdgeInsets.all(AppDimensions.s16),
      itemCount: _trainingSessions.length,
      itemBuilder: (context, index) {
        final session = _trainingSessions[index];
        return _buildTrainingCard(session);
      },
    );
  }

  Widget _buildTrainingCard(Training session) {
    final IconData typeIcon = _getIconForType(session.type);
    final bool hasVideo = session.videoUrl != null && session.videoUrl!.isNotEmpty;
    
    return Dismissible(
      key: Key(session.id),
      background: Container(
        color: AppColors.error,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppDimensions.s16),
        child: const FaIcon(
          FontAwesomeIcons.trash,
          color: Colors.white,
        ),
      ),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await _showDeleteConfirmation(session);
      },
      onDismissed: (direction) {
        _deleteTraining(session.id);
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: AppDimensions.s16),
        elevation: 2,
        child: Column(
          children: [
            // If there's a video, show a preview
            if (hasVideo) ...[
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppDimensions.radiusMedium),
                  topRight: Radius.circular(AppDimensions.radiusMedium),
                ),
                child: AspectRatio(
                  aspectRatio: 16/9,
                  child: Stack(
                    children: [
                      // Video thumbnail
                      _buildVideoThumbnail(session.videoUrl!),
                      
                      // Play button overlay
                      Container(
                        color: Colors.black.withOpacity(0.3),
                        child: Center(
                          child: Icon(
                            Icons.play_circle_fill,
                            size: 60,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ),
                      
                      // Play overlay with tap handler
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _playVideo(session.videoUrl!),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
        
            Padding(
              padding: const EdgeInsets.all(AppDimensions.s16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Training type icon
                  Container(
                    padding: const EdgeInsets.all(AppDimensions.s12),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                    ),
                    child: FaIcon(
                      typeIcon,
                      size: AppDimensions.iconLarge,
                      color: AppColors.accent,
                    ),
                  ),
                  const SizedBox(width: AppDimensions.s16),
                  
                  // Session details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          session.title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: AppDimensions.s4),
                        Row(
                          children: [
                            FaIcon(
                              AppAssets.iconCalories,
                              size: AppDimensions.iconSmall,
                              color: AppColors.calories,
                            ),
                            const SizedBox(width: AppDimensions.s4),
                            Text(
                              '${session.calories} kcal',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(width: AppDimensions.s12),
                            FaIcon(
                              AppAssets.iconClock,
                              size: AppDimensions.iconSmall,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                            ),
                            const SizedBox(width: AppDimensions.s4),
                            Text(
                              '${session.duration} min',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppDimensions.s4),
                        Text(
                          _formatDate(session.date),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                              ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Edit button
                  IconButton(
                    icon: FaIcon(
                      AppAssets.iconEdit,
                      size: AppDimensions.iconSmall,
                    ),
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TrainingFormScreen(
                            existingTraining: session,
                          ),
                        ),
                      );
                      
                      if (result == true) {
                        _loadTrainingSessions();
                        _appState.notifyDataChanged(); // Notify that data has changed to update energy balance
                      }
                    },
                  ),
                ],
              ),
            ),
            
            // Video indicator at the bottom
            if (hasVideo)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(AppDimensions.radiusMedium),
                    bottomRight: Radius.circular(AppDimensions.radiusMedium),
                  ),
                ),
                child: Row(
                  children: [
                    FaIcon(
                      AppAssets.iconVideo,
                      size: 14,
                      color: AppColors.accent,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      session.videoUrl!.startsWith('http') ? 'Video Attached' : 'Video Attached (local)',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.accent,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoThumbnail(String videoUrl) {
    // Check if we have a thumbnail for this video
    if (_thumbnails.containsKey(videoUrl) && _thumbnails[videoUrl] != null) {
      return Image.memory(
        _thumbnails[videoUrl]!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    }
    
    // If thumbnail generation failed or is still loading, show placeholder
    return _buildDemoVideoThumbnail();
  }

  Future<void> _deleteTraining(String id) async {
    await _trainingService.deleteTraining(id);
    _loadTrainingSessions();
    _appState.notifyDataChanged(); // Notify that data has changed to update energy balance
  }

  Future<bool> _showDeleteConfirmation(Training training) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Training?'),
        content: Text('Are you sure you want to delete "${training.title}"?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, false); // Don't delete
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context, true); // Confirm delete
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    ) ?? false;
  }

  void _playVideo(String videoUrl) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('Training Video'),
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
          ),
          backgroundColor: Colors.black,
          body: SafeArea(
            child: Center(
              child: VideoPreviewPlayer(
                videoPath: videoUrl,
                height: double.infinity,
                autoPlay: true,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Helper to get the appropriate icon for training type
  IconData _getIconForType(String type) {
    switch (type.toLowerCase()) {
      case 'running':
        return FontAwesomeIcons.personRunning;
      case 'weights':
        return FontAwesomeIcons.dumbbell;
      case 'yoga':
        return FontAwesomeIcons.hands;
      case 'cycling':
        return FontAwesomeIcons.bicycle;
      case 'swimming':
        return FontAwesomeIcons.personSwimming;
      case 'hiit':
        return FontAwesomeIcons.stopwatch;
      default:
        return AppAssets.iconTraining;
    }
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
      return DateFormat('MMM d, yyyy').format(date);
    }
  }

  Widget _buildDemoVideoThumbnail() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.accent.withOpacity(0.7),
            AppColors.accent.withOpacity(0.3),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(
              AppAssets.iconVideo,
              size: 48,
              color: Colors.white.withOpacity(0.9),
            ),
            const SizedBox(height: 8),
            Text(
              'Video Preview',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 