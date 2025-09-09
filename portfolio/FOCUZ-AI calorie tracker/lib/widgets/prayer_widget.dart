import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../core/constants.dart';
import '../models/prayer_data.dart';
import '../services/prayer_service.dart';
import '../features/prayer/prayer_screen.dart';
import 'dart:math' as math;

class PrayerWidget extends StatefulWidget {
  const PrayerWidget({super.key});

  @override
  State<PrayerWidget> createState() => _PrayerWidgetState();
}

// Add enum for widget states
enum PrayerWidgetState {
  initializing,
  loading,
  loaded,
  error,
  timeout
}

class _PrayerWidgetState extends State<PrayerWidget>
    with TickerProviderStateMixin {
  final PrayerService _prayerService = PrayerService();
  
  PrayerTimes? _currentPrayerTimes;
  PrayerRecord? _currentPrayerRecord;
  late AnimationController _glowController;
  late AnimationController _pulseController;
  
  // Add state management
  PrayerWidgetState _widgetState = PrayerWidgetState.initializing;
  String? _errorMessage;
  bool _isInitializing = false;
  
  // Stream subscriptions for proper disposal
  StreamSubscription<PrayerTimes?>? _prayerTimesSubscription;
  StreamSubscription<PrayerRecord?>? _prayerRecordSubscription;
  
  // Timeout handling
  Timer? _initializationTimeout;
  static const Duration _initTimeout = Duration(seconds: 10);
  
  @override
  void initState() {
    super.initState();
    
    // Initialize animation controllers
    _glowController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    
    _initializePrayerData();
  }
  
  @override
  void dispose() {
    _glowController.dispose();
    _pulseController.dispose();
    _prayerTimesSubscription?.cancel();
    _prayerRecordSubscription?.cancel();
    _initializationTimeout?.cancel();
    super.dispose();
  }
  
  Future<void> _initializePrayerData() async {
    // Prevent multiple simultaneous initialization attempts
    if (_isInitializing) {
      debugPrint('🔄 Prayer widget: Already initializing, skipping duplicate request');
      return;
    }
    
    setState(() {
      _isInitializing = true;
      _widgetState = PrayerWidgetState.initializing;
      _errorMessage = null;
    });
    
    // Cancel existing subscriptions
    await _prayerTimesSubscription?.cancel();
    await _prayerRecordSubscription?.cancel();
    _initializationTimeout?.cancel();
    
    // Set up timeout
    _initializationTimeout = Timer(_initTimeout, () {
      if (mounted && (_widgetState == PrayerWidgetState.initializing || _widgetState == PrayerWidgetState.loading)) {
        setState(() {
          _widgetState = PrayerWidgetState.timeout;
          _errorMessage = 'Loading timed out. Please check your internet connection.';
          _isInitializing = false;
        });
        debugPrint('⏰ Prayer widget: Initialization/loading timed out after ${_initTimeout.inSeconds} seconds');
      }
    });
    
    try {
      debugPrint('🕌 Initializing Prayer Service...');
      
      // Set loading state before initialization
      setState(() {
        _widgetState = PrayerWidgetState.loading;
      });
      
      await _prayerService.init();
      debugPrint('✅ Prayer Service initialized successfully');
      
      // Cancel timeout since initialization succeeded
      _initializationTimeout?.cancel();
      
      // Check for immediate current values from service
      final immediateCurrentTimes = _prayerService.currentPrayerTimes;
      final immediateCurrentRecord = _prayerService.currentPrayerRecord;
      
      if (immediateCurrentTimes != null) {
        debugPrint('🚀 Prayer Widget: Found immediate prayer times - Fajr: ${DateFormat('HH:mm').format(immediateCurrentTimes.fajr)}');
        setState(() {
          _currentPrayerTimes = immediateCurrentTimes;
          _widgetState = PrayerWidgetState.loaded;
          _errorMessage = null;
        });
      }
      
      if (immediateCurrentRecord != null) {
        debugPrint('🚀 Prayer Widget: Found immediate prayer record');
        setState(() {
          _currentPrayerRecord = immediateCurrentRecord;
        });
      }
      
      // Set up stream listeners AFTER successful initialization
      _prayerTimesSubscription = _prayerService.currentPrayerTimesStream.listen(
        (prayerTimes) {
          debugPrint('📅 Prayer Widget: Stream received prayer times: ${prayerTimes != null ? 'SUCCESS - ${DateFormat('HH:mm').format(prayerTimes.fajr)}' : 'NULL'}');
          if (mounted && prayerTimes != null) {
            setState(() {
              _currentPrayerTimes = prayerTimes;
              _widgetState = PrayerWidgetState.loaded;
              _errorMessage = null;
              debugPrint('✅ Prayer Widget: State changed to LOADED');
            });
          }
        },
        onError: (error) {
          debugPrint('❌ Prayer Widget: Prayer times stream error: $error');
          if (mounted) {
            setState(() {
              _widgetState = PrayerWidgetState.error;
              _errorMessage = 'Prayer times stream error: $error';
            });
          }
        },
      );
      
      _prayerRecordSubscription = _prayerService.currentPrayerRecordStream.listen(
        (prayerRecord) {
          debugPrint('📝 Prayer Widget: Stream received prayer record: ${prayerRecord != null ? 'SUCCESS' : 'NULL'}');
          if (mounted && prayerRecord != null) {
            setState(() {
              _currentPrayerRecord = prayerRecord;
            });
          }
        },
        onError: (error) {
          debugPrint('❌ Prayer Widget: Prayer record stream error: $error');
        },
      );
      
      // Force immediate check for current values in case we missed the stream emission
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted && _widgetState != PrayerWidgetState.loaded) {
          final currentTimes = _prayerService.currentPrayerTimes;
          final currentRecord = _prayerService.currentPrayerRecord;
          
          if (currentTimes != null) {
            debugPrint('🔄 Prayer Widget: Delayed check found prayer times - forcing loaded state');
            setState(() {
              _currentPrayerTimes = currentTimes;
              _currentPrayerRecord = currentRecord;
              _widgetState = PrayerWidgetState.loaded;
              _errorMessage = null;
            });
          }
        }
      });
      
    } catch (e) {
      debugPrint('❌ Error initializing prayer data: $e');
      _initializationTimeout?.cancel();
      
      if (mounted) {
        setState(() {
          _widgetState = PrayerWidgetState.error;
          _errorMessage = e.toString();
        });
        
        // Show error message to user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Prayer times error: $e'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'RETRY',
              textColor: Colors.white,
              onPressed: () => _retryInitialization(),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    }
  }
  
  void _retryInitialization() {
    debugPrint('🔄 Prayer widget: Retrying initialization...');
    _initializePrayerData();
  }
  
  void _onWidgetTap() {
    // Haptic feedback
    HapticFeedback.mediumImpact();
    
    // If in error or timeout state, retry initialization instead of navigating
    if (_widgetState == PrayerWidgetState.error || _widgetState == PrayerWidgetState.timeout) {
      _retryInitialization();
      return;
    }
    
    // Always navigate to prayer screen, even if prayer times aren't loaded yet
    // The prayer screen will handle loading state appropriately
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PrayerScreen(),
      ),
    );
  }
  
  void _onWidgetLongPress() {
    // Haptic feedback
    HapticFeedback.heavyImpact();
    
    // Show quick action overlay for current prayer
    if (_currentPrayerTimes != null) {
      _showQuickActionOverlay();
    }
  }
  
  void _showQuickActionOverlay() {
    final now = DateTime.now();
    final currentPrayer = _currentPrayerTimes!.getCurrentPrayer(now);
    final currentEntry = _currentPrayerRecord?.prayers[currentPrayer];
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppDimensions.s8),
                decoration: BoxDecoration(
                  color: AppColors.prayer.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: FaIcon(
                  _getPrayerIcon(currentPrayer),
                  color: AppColors.prayer,
                  size: AppDimensions.iconMedium,
                ),
              ),
              const SizedBox(width: AppDimensions.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(currentPrayer.displayName),
                    Text(
                      'Record your prayer',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Fard Prayer Toggle
              Container(
                padding: const EdgeInsets.all(AppDimensions.s12),
                decoration: BoxDecoration(
                  color: (currentEntry?.fardPerformed ?? false)
                      ? AppColors.prayerCompleted.withOpacity(0.1)
                      : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                  border: Border.all(
                    color: (currentEntry?.fardPerformed ?? false)
                        ? AppColors.prayerCompleted
                        : Colors.grey.shade300,
                  ),
                ),
                child: Row(
                  children: [
                    Checkbox(
                      value: currentEntry?.fardPerformed ?? false,
                      onChanged: (value) async {
                        if (value != null) {
                          await _prayerService.markPrayerCompleted(currentPrayer, completed: value);
                        }
                      },
                      activeColor: AppColors.prayerCompleted,
                    ),
                    const SizedBox(width: AppDimensions.s8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Fard Prayer',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: (currentEntry?.fardPerformed ?? false)
                                  ? AppColors.prayerCompleted
                                  : null,
                            ),
                          ),
                          Text(
                            'Obligatory prayer',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: AppDimensions.s16),
              
              // Sunnah Prayers Section
              Text(
                'Sunnah Prayers (Optional)',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.prayer,
                ),
              ),
              
              const SizedBox(height: AppDimensions.s8),
              
              // Dynamic Sunnah prayers based on prayer type
              ..._buildSunnahToggles(currentPrayer, currentEntry, setDialogState),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${currentPrayer.displayName} prayer updated'),
                    backgroundColor: AppColors.prayerCompleted,
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.prayer,
                foregroundColor: Colors.white,
              ),
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }
  
  List<Widget> _buildSunnahToggles(PrayerType prayerType, PrayerEntry? entry, StateSetter setDialogState) {
    final sunnahOptions = _getSunnahOptions(prayerType);
    
    return sunnahOptions.map((sunnah) {
      final isCompleted = entry?.sunnahs[sunnah.key] ?? false;
      
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppDimensions.s4),
        child: Row(
          children: [
            Checkbox(
              value: isCompleted,
              onChanged: (value) async {
                await _prayerService.toggleSunnahPrayer(prayerType, sunnah.key);
                // Note: We don't call setDialogState here because the stream will update
              },
              activeColor: AppColors.prayerUpcoming,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: AppDimensions.s8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sunnah.displayName,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: isCompleted ? AppColors.prayerUpcoming : null,
                    ),
                  ),
                  if (sunnah.description != null)
                    Text(
                      sunnah.description!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
  
  List<({String key, String displayName, String? description})> _getSunnahOptions(PrayerType prayerType) {
    switch (prayerType) {
      case PrayerType.fajr:
        return [
          (key: 'beforeFajr', displayName: 'Sunnah before Fajr', description: '2 Rakah before Fajr'),
        ];
      case PrayerType.dhuhr:
        return [
          (key: 'beforeDhuhr', displayName: 'Sunnah before Dhuhr', description: '4 Rakah before Dhuhr'),
          (key: 'afterDhuhr', displayName: 'Sunnah after Dhuhr', description: '2 Rakah after Dhuhr'),
        ];
      case PrayerType.asr:
        return [
          (key: 'beforeAsr', displayName: 'Sunnah before Asr', description: '4 Rakah before Asr (optional)'),
        ];
      case PrayerType.maghrib:
        return [
          (key: 'afterMaghrib', displayName: 'Sunnah after Maghrib', description: '2 Rakah after Maghrib'),
        ];
      case PrayerType.isha:
        return [
          (key: 'afterIsha', displayName: 'Sunnah after Isha', description: '2 Rakah after Isha'),
          (key: 'witr', displayName: 'Witr Prayer', description: '1-3 Rakah Witr (strongly recommended)'),
        ];
    }
  }
  
  @override
  Widget build(BuildContext context) {
    // Handle different states
    switch (_widgetState) {
      case PrayerWidgetState.loaded:
        if (_currentPrayerTimes != null) {
          return _buildLoadedWidget();
        }
        // If state is loaded but no prayer times, fall back to loading
        return _buildLoadingWidget();
      
      case PrayerWidgetState.error:
        return _buildErrorWidget();
      
      case PrayerWidgetState.timeout:
        return _buildTimeoutWidget();
      
      case PrayerWidgetState.initializing:
      case PrayerWidgetState.loading:
      default:
        return _buildLoadingWidget();
    }
  }
  
  Widget _buildLoadedWidget() {
    return GestureDetector(
      onTap: _onWidgetTap,
      onLongPress: _onWidgetLongPress,
      child: Container(
        height: 200,
        margin: const EdgeInsets.all(AppDimensions.s16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
          child: Stack(
            children: [
              // Background glow effect
              _buildGlowEffect(),
              
              // Main content
              Padding(
                padding: const EdgeInsets.all(AppDimensions.s20),
                child: Row(
                  children: [
                    // Left side: Prayer circle with countdown
                    Expanded(
                      flex: 3,
                      child: _buildPrayerCircle(),
                    ),
                    
                    const SizedBox(width: AppDimensions.s20),
                    
                    // Right side: Upcoming prayers
                    Expanded(
                      flex: 2,
                      child: _buildUpcomingPrayers(),
                    ),
                  ],
                ),
              ),
              
              // Top right corner: Islamic crescent icon
              Positioned(
                top: AppDimensions.s12,
                right: AppDimensions.s12,
                child: Container(
                  padding: const EdgeInsets.all(AppDimensions.s8),
                  decoration: BoxDecoration(
                    color: AppColors.prayer.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const FaIcon(
                    FontAwesomeIcons.mosque,
                    color: AppColors.prayer,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildLoadingWidget() {
    return GestureDetector(
      onTap: () {
        // Navigate to prayer screen even during loading - the prayer screen handles loading state
        debugPrint('🔄 Prayer widget tapped during loading - navigating to prayer screen...');
        HapticFeedback.mediumImpact();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const PrayerScreen(),
          ),
        );
      },
      child: Container(
        height: 200,
        margin: const EdgeInsets.all(AppDimensions.s16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Islamic crescent icon
            Container(
              padding: const EdgeInsets.all(AppDimensions.s8),
              decoration: BoxDecoration(
                color: AppColors.prayer.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const FaIcon(
                FontAwesomeIcons.mosque,
                color: AppColors.prayer,
                size: 24,
              ),
            ),
            const SizedBox(height: AppDimensions.s16),
            const CircularProgressIndicator(color: AppColors.prayer),
            const SizedBox(height: AppDimensions.s12),
            Text(
              _widgetState == PrayerWidgetState.initializing 
                  ? 'Initializing prayer service...'
                  : 'Loading prayer times...',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.prayer,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppDimensions.s8),
            Text(
              _widgetState == PrayerWidgetState.initializing
                  ? 'Setting up prayer times service'
                  : 'Getting your location for accurate times',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            if (_widgetState != PrayerWidgetState.initializing && !_isInitializing) ...[
              const SizedBox(height: AppDimensions.s12),
              Text(
                'Tap to open prayer details',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.prayer.withOpacity(0.7),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildErrorWidget() {
    return GestureDetector(
      onTap: _retryInitialization,
      child: Container(
        height: 200,
        margin: const EdgeInsets.all(AppDimensions.s16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
          border: Border.all(
            color: AppColors.error.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppDimensions.s8),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                color: AppColors.error,
                size: 32,
              ),
            ),
            const SizedBox(height: AppDimensions.s16),
            Text(
              'Prayer Times Error',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppDimensions.s8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppDimensions.s16),
              child: Text(
                _errorMessage ?? 'Unable to load prayer times',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: AppDimensions.s12),
            Text(
              'Tap to retry',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.error.withOpacity(0.8),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTimeoutWidget() {
    return GestureDetector(
      onTap: _retryInitialization,
      child: Container(
        height: 200,
        margin: const EdgeInsets.all(AppDimensions.s16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
          border: Border.all(
            color: AppColors.warning.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppDimensions.s8),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.access_time,
                color: AppColors.warning,
                size: 32,
              ),
            ),
            const SizedBox(height: AppDimensions.s16),
            Text(
              'Connection Timeout',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.warning,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppDimensions.s8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppDimensions.s16),
              child: Text(
                'Taking longer than usual. Check your internet connection.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: AppDimensions.s12),
            Text(
              'Tap to retry',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.warning.withOpacity(0.8),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildGlowEffect() {
    final now = DateTime.now();
    final nextPrayer = _currentPrayerTimes!.getNextPrayer(now);
    final timeUntilNext = nextPrayer.time.difference(now);
    
    // Calculate glow intensity based on proximity to next prayer
    final totalMinutesInDay = 24 * 60;
    final minutesUntilNext = timeUntilNext.inMinutes;
    final proximity = 1.0 - (minutesUntilNext / totalMinutesInDay).clamp(0.0, 1.0);
    
    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
            gradient: RadialGradient(
              center: const Alignment(-0.3, -0.3),
              radius: 1.0 + (_glowController.value * 0.2),
              colors: [
                AppColors.prayerGlow.withOpacity(0.1 + (proximity * 0.2)),
                AppColors.prayerGlow.withOpacity(0.05 + (proximity * 0.1)),
                Colors.transparent,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildPrayerCircle() {
    final now = DateTime.now();
    final currentPrayer = _currentPrayerTimes!.getCurrentPrayer(now);
    final nextPrayer = _currentPrayerTimes!.getNextPrayer(now);
    final timeUntilNext = nextPrayer.time.difference(now);
    
    // Calculate progress (time elapsed since current prayer started)
    final currentPrayerTime = _currentPrayerTimes!.getPrayerTime(currentPrayer);
    final totalPrayerDuration = nextPrayer.time.difference(currentPrayerTime);
    final elapsed = now.difference(currentPrayerTime);
    final progress = elapsed.inMinutes / totalPrayerDuration.inMinutes;
    
    // Check if current prayer is completed
    final isCurrentPrayerCompleted = _currentPrayerRecord?.prayers[currentPrayer]?.fardPerformed ?? false;
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Prayer circle with countdown
        Expanded(
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return LayoutBuilder(
                builder: (context, constraints) {
                  final size = math.min(constraints.maxWidth, constraints.maxHeight) * 0.9;
                  return AspectRatio(
                    aspectRatio: 1,
                    child: CircularPercentIndicator(
                      radius: size / 2,
                      lineWidth: 8.0,
                      percent: progress.clamp(0.0, 1.0),
                      center: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Current prayer icon
                          Container(
                            padding: const EdgeInsets.all(AppDimensions.s8),
                            decoration: BoxDecoration(
                              color: isCurrentPrayerCompleted 
                                  ? AppColors.prayerCompleted.withOpacity(0.2)
                                  : AppColors.prayer.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: FaIcon(
                              _getPrayerIcon(currentPrayer),
                              color: isCurrentPrayerCompleted 
                                  ? AppColors.prayerCompleted 
                                  : AppColors.prayer,
                              size: 20,
                            ),
                          ).animate(target: _pulseController.value)
                            .scale(begin: const Offset(1.0, 1.0), end: const Offset(1.1, 1.1)),
                          
                          const SizedBox(height: AppDimensions.s4),
                          
                          // Current prayer name
                          Text(
                            currentPrayer.displayName,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isCurrentPrayerCompleted 
                                  ? AppColors.prayerCompleted 
                                  : AppColors.prayer,
                            ),
                          ),
                        ],
                      ),
                      progressColor: isCurrentPrayerCompleted 
                          ? AppColors.prayerCompleted 
                          : AppColors.prayer,
                      backgroundColor: AppColors.prayer.withOpacity(0.1),
                      circularStrokeCap: CircularStrokeCap.round,
                    ),
                  );
                },
              );
            },
          ),
        ),
        
        const SizedBox(height: AppDimensions.s8),
        
        // Next prayer countdown
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Next: ${nextPrayer.prayer.displayName}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: AppDimensions.s4),
            Text(
              _formatDuration(timeUntilNext),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.prayerUpcoming,
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildUpcomingPrayers() {
    final now = DateTime.now();
    final upcomingPrayers = <({PrayerType type, DateTime time, bool completed})>[];
    
    // Get next 3 prayers
    for (final prayerType in PrayerType.values) {
      final prayerTime = _currentPrayerTimes!.getPrayerTime(prayerType);
      if (prayerTime.isAfter(now)) {
        final isCompleted = _currentPrayerRecord?.prayers[prayerType]?.fardPerformed ?? false;
        upcomingPrayers.add((type: prayerType, time: prayerTime, completed: isCompleted));
      }
    }
    
    // Sort by time and take next 3
    upcomingPrayers.sort((a, b) => a.time.compareTo(b.time));
    final nextThree = upcomingPrayers.take(3).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Upcoming',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.prayer,
          ),
        ),
        const SizedBox(height: AppDimensions.s12),
        
        ...nextThree.map((prayer) => Padding(
          padding: const EdgeInsets.only(bottom: AppDimensions.s8),
          child: Row(
            children: [
              // Prayer icon
              Container(
                padding: const EdgeInsets.all(AppDimensions.s4),
                decoration: BoxDecoration(
                  color: prayer.completed 
                      ? AppColors.prayerCompleted.withOpacity(0.2)
                      : AppColors.prayer.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: FaIcon(
                  _getPrayerIcon(prayer.type),
                  color: prayer.completed 
                      ? AppColors.prayerCompleted 
                      : AppColors.prayer,
                  size: 12,
                ),
              ),
              
              const SizedBox(width: AppDimensions.s8),
              
              // Prayer info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      prayer.type.displayName,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: prayer.completed 
                            ? AppColors.prayerCompleted 
                            : null,
                      ),
                    ),
                    Text(
                      DateFormat('HH:mm').format(prayer.time),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Completion indicator
              if (prayer.completed)
                const Icon(
                  Icons.check_circle,
                  color: AppColors.prayerCompleted,
                  size: 16,
                ),
            ],
          ),
        )).toList(),
        
        const SizedBox(height: AppDimensions.s8),
        
        // Tap hint
        Text(
          'Tap to view details',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            fontSize: 10,
          ),
        ),
      ],
    );
  }
  
  IconData _getPrayerIcon(PrayerType prayerType) {
    switch (prayerType) {
      case PrayerType.fajr:
        return FontAwesomeIcons.sun;
      case PrayerType.dhuhr:
        return FontAwesomeIcons.cloudSun;
      case PrayerType.asr:
        return FontAwesomeIcons.cloud;
      case PrayerType.maghrib:
        return FontAwesomeIcons.cloudMoon;
      case PrayerType.isha:
        return FontAwesomeIcons.moon;
    }
  }
  
  String _formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays}d ${duration.inHours % 24}h';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else {
      return '${duration.inMinutes}m';
    }
  }
} 