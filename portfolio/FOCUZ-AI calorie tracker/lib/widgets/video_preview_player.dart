import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../core/constants.dart';
import '../services/video_storage_service.dart';

class VideoPreviewPlayer extends StatefulWidget {
  final String videoPath;
  final double height;
  final VoidCallback? onRemove;
  final bool autoPlay;
  final bool showControls;
  final bool forceDemoIfMissing;

  const VideoPreviewPlayer({
    super.key,
    required this.videoPath,
    this.height = 200,
    this.onRemove,
    this.autoPlay = false,
    this.showControls = true,
    this.forceDemoIfMissing = false,
  });
  
  /// Static method to save a video file and get a persistent path
  static Future<String?> savePersistentVideo(String videoPath) async {
    if (videoPath.startsWith('http')) {
      return null; // Cannot save network videos
    }
    
    try {
      final videoFile = File(videoPath);
      if (await videoFile.exists()) {
        final service = VideoStorageService();
        await service.init();
        return await service.saveVideo(
          videoFile, 
          metadata: {
            'date': DateTime.now().toIso8601String(),
            'source': 'training',
          },
        );
      }
    } catch (e) {
      debugPrint('Error saving persistent video: $e');
    }
    return null;
  }

  @override
  State<VideoPreviewPlayer> createState() => _VideoPreviewPlayerState();
}

class _VideoPreviewPlayerState extends State<VideoPreviewPlayer> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  bool _isInitialized = false;
  bool _hasError = false;
  bool _isMockVideo = false;
  String? _savedVideoPath;
  final VideoStorageService _videoStorageService = VideoStorageService();

  @override
  void initState() {
    super.initState();
    _initializeVideoPlayer();
  }

  /// Check if the path is within app's persistent storage
  Future<bool> _isPathInAppStorage(String filePath) async {
    try {
      // Get app document directory
      final appDocDir = await getApplicationDocumentsDirectory();
      final appTempDir = await getTemporaryDirectory();
      
      // Check if path contains either directories
      return filePath.contains(appDocDir.path) || 
             (filePath.contains('/documents/') || filePath.contains('/Documents/')) ||
             filePath.contains(appTempDir.path);
    } catch (e) {
      debugPrint('Error checking path: $e');
      return false;
    }
  }

  /// Check if file exists with various iOS path interpretations
  Future<File?> _resolveVideoFile(String videoPath) async {
    try {
      // First try the direct path
      final directFile = File(videoPath);
      if (await directFile.exists()) {
        debugPrint('File exists at direct path: $videoPath');
        return directFile;
      }
      
      // Try lowercase path (iOS might use lowercase)
      final lowerCasePath = videoPath.replaceAll('/Documents/', '/documents/');
      final lowerCaseFile = File(lowerCasePath);
      if (await lowerCaseFile.exists()) {
        debugPrint('File exists at lowercase path: $lowerCasePath');
        return lowerCaseFile;
      }
      
      // Try uppercase path (iOS might use uppercase)
      final upperCasePath = videoPath.replaceAll('/documents/', '/Documents/');
      final upperCaseFile = File(upperCasePath);
      if (await upperCaseFile.exists()) {
        debugPrint('File exists at uppercase path: $upperCasePath');
        return upperCaseFile;
      }
      
      // Get app document directory and try to resolve relative path
      final appDocDir = await getApplicationDocumentsDirectory();
      final fileName = path.basename(videoPath);
      final appDirPath = path.join(appDocDir.path, 'videos', fileName);
      final appDirFile = File(appDirPath);
      
      if (await appDirFile.exists()) {
        debugPrint('File exists in app directory: $appDirPath');
        return appDirFile;
      }
      
      debugPrint('Could not resolve file: $videoPath');
      return null;
    } catch (e) {
      debugPrint('Error resolving video file: $e');
      return null;
    }
  }

  Future<void> _initializeVideoPlayer() async {
    try {
      // Check if this is a mock video or real file
      if (widget.videoPath.startsWith('http')) {
        _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(widget.videoPath));
        _isMockVideo = true;
      } else {
        debugPrint('Trying to load video from: ${widget.videoPath}');
        
        // Try to resolve the file with various path interpretations
        final videoFile = await _resolveVideoFile(widget.videoPath);
        final isAppStorage = await _isPathInAppStorage(widget.videoPath);
        
        if (videoFile != null && (await videoFile.exists())) {
          // Valid file exists
          _videoPlayerController = VideoPlayerController.file(videoFile);
          _savedVideoPath = videoFile.path;
          _isMockVideo = false;
          debugPrint('Using real video file: ${videoFile.path}');
          
          // If it's not in app storage, save it
          if (!isAppStorage) {
            _saveVideoToStorage(videoFile);
          }
        } else if (!widget.forceDemoIfMissing) {
          // The file doesn't exist but we don't want to use a demo
          // Try to check if there's a video in the metadata
          final allVideos = await _videoStorageService.getAllVideosMetadata();
          
          // Find the most recent training video
          final trainingVideos = allVideos.where((v) => 
            v['source'] == 'training' && v['path'] != null).toList();
          
          if (trainingVideos.isNotEmpty) {
            // Sort by date (newest first)
            trainingVideos.sort((a, b) => 
              (b['savedAt'] ?? '').compareTo(a['savedAt'] ?? ''));
            
            // Try to use the most recent video
            final recentVideoPath = trainingVideos.first['path'] as String?;
            if (recentVideoPath != null) {
              final recentFile = File(recentVideoPath);
              if (await recentFile.exists()) {
                _videoPlayerController = VideoPlayerController.file(recentFile);
                _savedVideoPath = recentVideoPath;
                _isMockVideo = false;
                debugPrint('Using recent training video: $recentVideoPath');
              } else {
                // Fallback to demo
                _useDemoVideo();
              }
            } else {
              // Fallback to demo
              _useDemoVideo();
            }
          } else {
            // Fallback to demo
            _useDemoVideo();
          }
        } else {
          // Fallback to demo
          _useDemoVideo();
        }
      }

      await _videoPlayerController.initialize();
      
      // Set video to loop
      await _videoPlayerController.setLooping(true);
      
      // Limit video duration to 20 seconds if it's longer
      if (_videoPlayerController.value.duration.inSeconds > 20) {
        await _videoPlayerController.seekTo(const Duration(seconds: 0));
      }

      if (mounted) {
        _chewieController = ChewieController(
          videoPlayerController: _videoPlayerController,
          autoPlay: widget.autoPlay,
          looping: true,
          showControls: widget.showControls,
          materialProgressColors: ChewieProgressColors(
            playedColor: AppColors.accent,
            handleColor: AppColors.accent,
            backgroundColor: Colors.grey[300]!,
            bufferedColor: Colors.grey[600]!,
          ),
          placeholder: const Center(child: CircularProgressIndicator()),
          autoInitialize: true,
          aspectRatio: _videoPlayerController.value.aspectRatio,
          errorBuilder: (context, errorMessage) {
            return Center(
              child: Text(
                'Error: $errorMessage',
                style: const TextStyle(color: Colors.white),
              ),
            );
          },
        );
        
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      setState(() {
        _hasError = true;
      });
      debugPrint('Video player error: $e');
    }
  }
  
  // Use a demo video
  void _useDemoVideo() {
    _isMockVideo = true;
    const sampleUrls = [
      'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4',
      'https://storage.googleapis.com/gtv-videos-bucket/sample/ForBiggerJoyrides.mp4',
      'https://storage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
    ];
    
    // Pick a sample video
    final sampleUrl = sampleUrls[DateTime.now().millisecond % sampleUrls.length];
    _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(sampleUrl));
    debugPrint('Using demo video: $sampleUrl');
  }
  
  // Save video to permanent storage
  Future<void> _saveVideoToStorage(File videoFile) async {
    try {
      // Only save if it's a real file (not a network URL)
      if (videoFile.existsSync()) {
        debugPrint('Saving video to permanent storage: ${videoFile.path}');
        
        // Save the video using VideoStorageService
        final savedPath = await _videoStorageService.saveVideo(
          videoFile,
          metadata: {
            'date': DateTime.now().toIso8601String(),
            'source': 'training',
          },
        );
        
        if (savedPath != null) {
          if (mounted) {
            setState(() {
              _savedVideoPath = savedPath;
            });
          }
          debugPrint('Video saved permanently at: $savedPath');
        }
      }
    } catch (e) {
      debugPrint('Error saving video: $e');
    }
  }

  // Get the properly saved video path
  String? get persistentVideoPath => _savedVideoPath;

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Container(
        height: widget.height,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.red, size: 40),
              SizedBox(height: 8),
              Text('Could not load video'),
            ],
          ),
        ),
      );
    }
    
    if (!_isInitialized) {
      return Container(
        height: widget.height,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
      child: Stack(
        children: [
          SizedBox(
            height: widget.height,
            child: Chewie(controller: _chewieController!),
          ),
          if (widget.onRemove != null)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: widget.onRemove,
                  iconSize: 20,
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(),
                  splashRadius: 20,
                ),
              ),
            ),
          if (_isMockVideo)
            Positioned(
              bottom: 10,
              left: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'DEMO VIDEO',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
} 