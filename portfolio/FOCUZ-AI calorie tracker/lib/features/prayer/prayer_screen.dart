import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../models/prayer_data.dart';
import '../../services/prayer_service.dart';
import '../../widgets/custom_app_bar.dart';
import 'dart:math' as math;

class PrayerScreen extends StatefulWidget {
  const PrayerScreen({super.key});

  @override
  State<PrayerScreen> createState() => _PrayerScreenState();
}

class _PrayerScreenState extends State<PrayerScreen>
    with TickerProviderStateMixin {
  final PrayerService _prayerService = PrayerService();
  
  PrayerTimes? _currentPrayerTimes;
  PrayerRecord? _currentPrayerRecord;
  List<PrayerRecord> _prayerHistory = [];
  int _currentStreak = 0;
  bool _isLoading = true;
  
  // Add selected date state management
  DateTime _selectedDate = DateTime.now();
  
  late AnimationController _countdownController;
  late AnimationController _progressController;
  
  @override
  void initState() {
    super.initState();
    
    _countdownController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _initializePrayerData();
  }
  
  @override
  void dispose() {
    _countdownController.dispose();
    _progressController.dispose();
    super.dispose();
  }
  
  Future<void> _initializePrayerData() async {
    setState(() => _isLoading = true);
    
    try {
      // Since PrayerService is a singleton, check if it's already initialized
      debugPrint('🕌 Prayer Screen: Checking Prayer Service initialization...');
      
      // Initialize the service (will skip if already initialized)
      await _prayerService.init();
      debugPrint('✅ Prayer Service ready for Prayer Screen');
      
      // Check for immediate current values from service
      final immediateCurrentTimes = _prayerService.currentPrayerTimes;
      final immediateCurrentRecord = _prayerService.currentPrayerRecord;
      
      if (immediateCurrentTimes != null) {
        debugPrint('🚀 Prayer Screen: Found immediate prayer times');
        setState(() => _currentPrayerTimes = immediateCurrentTimes);
      }
      
      if (immediateCurrentRecord != null) {
        debugPrint('🚀 Prayer Screen: Found immediate prayer record');
        setState(() => _currentPrayerRecord = immediateCurrentRecord);
      }
      
      // Set up stream listeners to get current state
      _prayerService.currentPrayerTimesStream.listen((prayerTimes) {
        if (mounted) {
          setState(() => _currentPrayerTimes = prayerTimes);
        }
      });
      
      _prayerService.currentPrayerRecordStream.listen((prayerRecord) {
        if (mounted) {
          setState(() => _currentPrayerRecord = prayerRecord);
          _progressController.forward();
        }
      });
      
      // Try to get current prayer times immediately if not already available
      if (_currentPrayerTimes == null) {
        final currentTimes = await _prayerService.getCurrentPrayerTimes();
        if (currentTimes != null && mounted) {
          setState(() => _currentPrayerTimes = currentTimes);
        }
      }
      
      // Load prayer history
      await _loadPrayerHistory();
      
      // Calculate current streak
      _currentStreak = await _prayerService.getCurrentPrayerStreak();
      
    } catch (e) {
      debugPrint('Error initializing prayer data in Prayer Screen: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading prayer data: $e'),
            backgroundColor: AppColors.error,
            action: SnackBarAction(
              label: 'RETRY',
              textColor: Colors.white,
              onPressed: () => _initializePrayerData(),
            ),
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  Future<void> _loadPrayerHistory() async {
    try {
      final history = await _prayerService.getPrayerRecords(
        startDate: DateTime.now().subtract(const Duration(days: 30)),
        endDate: DateTime.now(),
      );
      
      setState(() => _prayerHistory = history);
    } catch (e) {
      debugPrint('Error loading prayer history: $e');
    }
  }
  
  Future<void> _markPrayerCompleted(PrayerType prayerType) async {
    try {
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Text('Saving ${prayerType.displayName}...'),
            ],
          ),
          backgroundColor: AppColors.prayer,
          duration: const Duration(seconds: 1),
        ),
      );
      
      await _prayerService.markPrayerCompleted(prayerType);
      
      // Refresh prayer history to show updated data
      await _loadPrayerHistory();
      
      // Show success confirmation
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text('${prayerType.displayName} saved successfully'),
              ],
            ),
            backgroundColor: AppColors.prayerCompleted,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error marking prayer completed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text('Failed to save: $e')),
              ],
            ),
            backgroundColor: AppColors.error,
            action: SnackBarAction(
              label: 'RETRY',
              textColor: Colors.white,
              onPressed: () => _markPrayerCompleted(prayerType),
            ),
          ),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: CustomAppBar(title: 'Prayer Times'),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppColors.prayer),
              SizedBox(height: AppDimensions.s16),
              Text('Loading prayer times...'),
            ],
          ),
        ),
      );
    }
    
    return Scaffold(
      appBar: CustomAppBar(
        title: _isSameDay(_selectedDate, DateTime.now()) 
            ? 'My Daily Salah Journey'
            : 'Salah Journey - ${DateFormat('MMM d, yyyy').format(_selectedDate)}',
        icon: Icons.calendar_today,
        onIconPressed: _showDatePicker,
      ),
      body: CustomScrollView(
        slivers: [
          // Sacred Rhythm - Show for current date (today)
          if (_isSameDay(_selectedDate, DateTime.now()))
            SliverToBoxAdapter(
              child: _buildTodaysSacredRhythm(),
            ),
          
          // Selected Date Prayer Card - Show for historical dates (not today)
          if (!_isSameDay(_selectedDate, DateTime.now()))
            SliverToBoxAdapter(
              child: _buildSelectedDatePrayerCard(),
            ),
          
          // Prayer History Section - Only show for today or multi-day ranges
          if (_isSameDay(_selectedDate, DateTime.now()))
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.s16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'My Daily Sunnah & Fard Journey',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.prayer,
                        ),
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.bar_chart,
                            color: AppColors.prayer,
                          ),
                          onPressed: _showPrayerStatistics,
                          tooltip: 'View Statistics',
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.calendar_month,
                            color: AppColors.prayer,
                          ),
                          onPressed: _showDatePicker,
                          tooltip: 'Select Date Range',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          
          // Prayer Records List - Only show today's card
          if (_isSameDay(_selectedDate, DateTime.now()))
            _buildTodaysPrayerCard(),
          
          // Iman Insights Section - Only show for today
          if (_isSameDay(_selectedDate, DateTime.now()))
            SliverToBoxAdapter(
              child: _buildImanInsights(),
            ),
          
          // Bottom padding
          const SliverToBoxAdapter(
            child: SizedBox(height: AppDimensions.s32),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTodaysSacredRhythm() {
    return Container(
      margin: const EdgeInsets.all(AppDimensions.s16),
      padding: const EdgeInsets.all(AppDimensions.s20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Section title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppDimensions.s8),
                decoration: BoxDecoration(
                  color: AppColors.prayer.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const FaIcon(
                  FontAwesomeIcons.mosque,
                  color: AppColors.prayer,
                  size: AppDimensions.iconMedium,
                ),
              ),
              const SizedBox(width: AppDimensions.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _isSameDay(_selectedDate, DateTime.now()) ? 'Today\'s Sacred Rhythm' : 'Sacred Rhythm',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.prayer,
                      ),
                    ),
                    Text(
                      DateFormat('EEEE, MMMM d').format(_selectedDate),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              // Add "Back to Today" button when viewing historical data
              if (!_isSameDay(_selectedDate, DateTime.now()))
                IconButton(
                  onPressed: _goBackToToday,
                  icon: const Icon(Icons.today, color: AppColors.prayer),
                  tooltip: 'Back to Today',
                ),
            ],
          ),
          
          const SizedBox(height: AppDimensions.s16),
          
          // Central countdown (only show for today) or loading state
          if (_currentPrayerTimes == null)
            _buildLoadingState()
          else if (_isSameDay(_selectedDate, DateTime.now())) 
            _buildGuidingLightCountdown()
          else
            _buildHistoricalDayOverview(),
          
          const SizedBox(height: AppDimensions.s16),
          
          // Prayer timeline (show loading if prayer times not available)
          if (_currentPrayerTimes != null)
            _buildCelestialPath()
          else
            _buildLoadingPrayerTimeline(),
        ],
      ),
    );
  }
  
  Widget _buildGuidingLightCountdown() {
    final now = DateTime.now();
    final nextPrayer = _currentPrayerTimes!.getNextPrayer(now);
    final timeUntilNext = nextPrayer.time.difference(now);
    
    // Calculate progress until next prayer
    final currentPrayer = _currentPrayerTimes!.getCurrentPrayer(now);
    final currentPrayerTime = _currentPrayerTimes!.getPrayerTime(currentPrayer);
    
    // Calculate the total duration between current prayer and next prayer
    final totalDuration = nextPrayer.time.difference(currentPrayerTime);
    final elapsed = now.difference(currentPrayerTime);
    
    // Calculate progress as a percentage (0.0 to 1.0)
    double progress = 0.0;
    if (totalDuration.inMinutes > 0) {
      progress = elapsed.inMinutes / totalDuration.inMinutes;
      progress = progress.clamp(0.0, 1.0);
    }
    
    return Center(
      child: StreamBuilder<DateTime>(
        stream: Stream.periodic(const Duration(seconds: 1), (_) => DateTime.now()),
        builder: (context, snapshot) {
          final currentTime = snapshot.data ?? now;
          final currentTimeUntilNext = nextPrayer.time.difference(currentTime);
          
          // Recalculate progress for real-time updates
          final currentElapsed = currentTime.difference(currentPrayerTime);
          double currentProgress = 0.0;
          if (totalDuration.inMinutes > 0) {
            currentProgress = currentElapsed.inMinutes / totalDuration.inMinutes;
            currentProgress = currentProgress.clamp(0.0, 1.0);
          }
          
          return AnimatedBuilder(
            animation: _countdownController,
            builder: (context, child) {
              return CircularPercentIndicator(
                radius: 80.0,
                lineWidth: 12.0,
                percent: currentProgress,
                center: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Next prayer icon
                    Container(
                      padding: const EdgeInsets.all(AppDimensions.s8),
                      decoration: BoxDecoration(
                        color: AppColors.prayerUpcoming.withOpacity(
                          0.2 + (_countdownController.value * 0.1)
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: FaIcon(
                        _getPrayerIcon(nextPrayer.prayer),
                        color: AppColors.prayerUpcoming,
                        size: 24,
                      ),
                    ),
                    
                    const SizedBox(height: AppDimensions.s8),
                    
                    // Next prayer name
                    Text(
                      nextPrayer.prayer.displayName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.prayer,
                      ),
                    ),
                    
                    // Countdown time
                    Text(
                      _formatCountdown(currentTimeUntilNext.isNegative ? Duration.zero : currentTimeUntilNext),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.prayerUpcoming,
                      ),
                    ),
                  ],
                ),
                progressColor: AppColors.prayer,
                backgroundColor: AppColors.prayer.withOpacity(0.1),
                circularStrokeCap: CircularStrokeCap.round,
              );
            },
          );
        },
      ),
    );
  }
  
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        children: [
          CircularPercentIndicator(
            radius: 80.0,
            lineWidth: 12.0,
            percent: 0.0,
            center: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppDimensions.s8),
                  decoration: BoxDecoration(
                    color: AppColors.prayer.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: AppColors.prayer,
                      strokeWidth: 2,
                    ),
                  ),
                ),
                const SizedBox(height: AppDimensions.s8),
                Text(
                  'Loading...',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.prayer,
                  ),
                ),
                Text(
                  'Prayer times',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.prayer.withOpacity(0.7),
                  ),
                ),
              ],
            ),
            progressColor: AppColors.prayer,
            backgroundColor: AppColors.prayer.withOpacity(0.1),
            circularStrokeCap: CircularStrokeCap.round,
          ),
        ],
      ),
    );
  }
  
  Widget _buildLoadingPrayerTimeline() {
    return SizedBox(
      height: 120,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              color: AppColors.prayer,
              strokeWidth: 2,
            ),
            const SizedBox(height: AppDimensions.s8),
            Text(
              'Loading prayer times...',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.prayer,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCelestialPath() {
    final prayers = PrayerType.values;
    final now = DateTime.now();
    
    // Find the prayer record for the selected date
    final selectedRecord = _prayerHistory.firstWhere(
      (record) => _isSameDay(record.date, _selectedDate),
      orElse: () => PrayerRecord(
        id: '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
        date: _selectedDate,
        prayers: {},
      ),
    );
    
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: prayers.length,
        itemBuilder: (context, index) {
          final prayer = prayers[index];
          final prayerTime = _currentPrayerTimes!.getPrayerTime(prayer);
          final isCompleted = selectedRecord.prayers[prayer]?.fardPerformed ?? false;
          final isPast = _isSameDay(_selectedDate, DateTime.now()) ? prayerTime.isBefore(now) : true; // All prayers are "past" for historical dates
          final isCurrent = _isSameDay(_selectedDate, DateTime.now()) ? _currentPrayerTimes!.getCurrentPrayer(now) == prayer : false;
          
          return Container(
            width: 100,
            margin: const EdgeInsets.symmetric(horizontal: AppDimensions.s8),
            child: GestureDetector(
              onTap: () => _showPrayerDetailsDialog(prayer),
              child: Card(
                elevation: isCurrent ? 8 : 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                  side: BorderSide(
                    color: isCurrent 
                        ? AppColors.prayer
                        : isCompleted 
                            ? AppColors.prayerCompleted
                            : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppDimensions.s12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Prayer icon with status
                      Stack(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(AppDimensions.s8),
                            decoration: BoxDecoration(
                              color: isCompleted
                                  ? AppColors.prayerCompleted.withOpacity(0.2)
                                  : isCurrent
                                      ? AppColors.prayer.withOpacity(0.2)
                                      : isPast && !_isSameDay(_selectedDate, DateTime.now())
                                          ? AppColors.prayer.withOpacity(0.1)
                                          : isPast
                                              ? AppColors.prayerMissed.withOpacity(0.2)
                                              : AppColors.prayer.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: FaIcon(
                              _getPrayerIcon(prayer),
                              color: isCompleted
                                  ? AppColors.prayerCompleted
                                  : isCurrent
                                      ? AppColors.prayer
                                      : isPast && !_isSameDay(_selectedDate, DateTime.now())
                                          ? AppColors.prayer
                                          : isPast
                                              ? AppColors.prayerMissed
                                              : AppColors.prayer,
                              size: 20,
                            ),
                          ),
                          
                          // Completion checkmark
                          if (isCompleted)
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: AppColors.prayerCompleted,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 1),
                                ),
                                child: const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 10,
                                ),
                              ),
                            ),
                        ],
                      ),
                      
                      const SizedBox(height: AppDimensions.s8),
                      
                      // Prayer name
                      Text(
                        prayer.displayName,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isCompleted
                              ? AppColors.prayerCompleted
                              : isCurrent
                                  ? AppColors.prayer
                                  : null,
                        ),
                      ),
                      
                      // Prayer time
                      Text(
                        DateFormat('HH:mm').format(prayerTime),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildTodaysPrayerCard() {
    // Find today's prayer record
    final today = DateTime.now();
    final todayRecord = _prayerHistory.firstWhere(
      (record) => _isSameDay(record.date, today),
      orElse: () => PrayerRecord(
        id: '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}',
        date: today,
        prayers: {},
      ),
    );
    
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: AppDimensions.s16,
          vertical: AppDimensions.s8,
        ),
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          ),
          child: ExpansionTile(
            title: Row(
              children: [
                // Date
                Expanded(
                  child: Text(
                    'Today - ${DateFormat('EEEE, MMM d').format(today)}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                
                // Completion percentage
                CircularPercentIndicator(
                  radius: 25.0,
                  lineWidth: 4.0,
                  percent: _safePercentage(todayRecord.completionPercentage),
                  center: Text(
                    '${_safePercentageToInt(todayRecord.completionPercentage)}%',
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                  progressColor: todayRecord.allFardCompleted 
                      ? AppColors.prayerCompleted 
                      : AppColors.prayer,
                  backgroundColor: AppColors.prayer.withOpacity(0.1),
                  circularStrokeCap: CircularStrokeCap.round,
                ),
              ],
            ),
            subtitle: Text(
              '${todayRecord.prayers.values.where((p) => p.fardPerformed).length}/5 prayers completed',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(AppDimensions.s16),
                child: Column(
                  children: PrayerType.values.map((prayerType) {
                    final entry = todayRecord.prayers[prayerType];
                    if (entry == null) {
                      // Create a placeholder entry if no data exists
                      final prayerTime = _currentPrayerTimes?.getPrayerTime(prayerType) ?? DateTime.now();
                      final placeholderEntry = PrayerEntry(
                        type: prayerType,
                        scheduledTime: prayerTime,
                        fardPerformed: false,
                        sunnahs: {},
                      );
                      return _buildPrayerEntryRow(placeholderEntry, today);
                    }
                    
                    return _buildPrayerEntryRow(entry, today);
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildSelectedDatePrayerCard() {
    // Find the prayer record for the selected date
    final selectedRecord = _prayerHistory.firstWhere(
      (record) => _isSameDay(record.date, _selectedDate),
      orElse: () => PrayerRecord(
        id: '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
        date: _selectedDate,
        prayers: {},
      ),
    );
    
    return Container(
      margin: const EdgeInsets.all(AppDimensions.s16),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.s20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with date and back button
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppDimensions.s8),
                    decoration: BoxDecoration(
                      color: AppColors.prayer.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const FaIcon(
                      FontAwesomeIcons.mosque,
                      color: AppColors.prayer,
                      size: AppDimensions.iconMedium,
                    ),
                  ),
                  const SizedBox(width: AppDimensions.s12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Prayer Record',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.prayer,
                          ),
                        ),
                        Text(
                          DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _goBackToToday,
                    icon: const Icon(Icons.today, color: AppColors.prayer),
                    tooltip: 'Back to Today',
                  ),
                ],
              ),
              
              const SizedBox(height: AppDimensions.s20),
              
              // Completion overview
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(AppDimensions.s16),
                      decoration: BoxDecoration(
                        color: selectedRecord.allFardCompleted 
                            ? AppColors.prayerCompleted.withOpacity(0.1)
                            : AppColors.prayer.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                      ),
                      child: Row(
                        children: [
                          CircularPercentIndicator(
                            radius: 30.0,
                            lineWidth: 6.0,
                            percent: _safePercentage(selectedRecord.completionPercentage),
                            center: Text(
                              '${_safePercentageToInt(selectedRecord.completionPercentage)}%',
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: selectedRecord.allFardCompleted 
                                    ? AppColors.prayerCompleted 
                                    : AppColors.prayer,
                              ),
                            ),
                            progressColor: selectedRecord.allFardCompleted 
                                ? AppColors.prayerCompleted 
                                : AppColors.prayer,
                            backgroundColor: AppColors.prayer.withOpacity(0.1),
                            circularStrokeCap: CircularStrokeCap.round,
                          ),
                          const SizedBox(width: AppDimensions.s16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  selectedRecord.allFardCompleted 
                                      ? 'All prayers completed! 🎉'
                                      : 'Prayer Progress',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: selectedRecord.allFardCompleted 
                                        ? AppColors.prayerCompleted 
                                        : AppColors.prayer,
                                  ),
                                ),
                                Text(
                                  '${selectedRecord.prayers.values.where((p) => p.fardPerformed).length}/5 prayers completed',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: AppDimensions.s20),
              
              // Prayer timeline for selected date
              if (_currentPrayerTimes != null)
                _buildCelestialPath(),
              
              const SizedBox(height: AppDimensions.s20),
              
              // Prayer entries for the selected date
              Text(
                'Prayer Details',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.prayer,
                ),
              ),
              
              const SizedBox(height: AppDimensions.s12),
              
              // List of prayers for this date
              ...PrayerType.values.map((prayerType) {
                final entry = selectedRecord.prayers[prayerType];
                if (entry == null) {
                  // Create a placeholder entry if no data exists
                  final prayerTime = _currentPrayerTimes?.getPrayerTime(prayerType) ?? DateTime.now();
                  final placeholderEntry = PrayerEntry(
                    type: prayerType,
                    scheduledTime: prayerTime,
                    fardPerformed: false,
                    sunnahs: {},
                  );
                  return _buildPrayerEntryRow(placeholderEntry, _selectedDate);
                }
                return _buildPrayerEntryRow(entry, _selectedDate);
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildDailyDevotionCard(PrayerRecord record) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppDimensions.s16,
        vertical: AppDimensions.s8,
      ),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        ),
        child: ExpansionTile(
          title: Row(
            children: [
              // Date
              Expanded(
                child: Text(
                  DateFormat('EEEE, MMM d').format(record.date),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              
              // Completion percentage
              CircularPercentIndicator(
                radius: 25.0,
                lineWidth: 4.0,
                percent: _safePercentage(record.completionPercentage),
                center: Text(
                  '${_safePercentageToInt(record.completionPercentage)}%',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                ),
                progressColor: record.allFardCompleted 
                    ? AppColors.prayerCompleted 
                    : AppColors.prayer,
                backgroundColor: AppColors.prayer.withOpacity(0.1),
                circularStrokeCap: CircularStrokeCap.round,
              ),
            ],
          ),
          subtitle: Text(
            '${record.prayers.values.where((p) => p.fardPerformed).length}/5 prayers completed',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(AppDimensions.s16),
              child: Column(
                children: PrayerType.values.map((prayerType) {
                  final entry = record.prayers[prayerType];
                  if (entry == null) return const SizedBox.shrink();
                  
                  return _buildPrayerEntryRow(entry, record.date);
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPrayerEntryRow(PrayerEntry entry, DateTime date) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.s8),
      child: Row(
        children: [
          // Prayer icon and name
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppDimensions.s8),
                  decoration: BoxDecoration(
                    color: entry.fardPerformed
                        ? AppColors.prayerCompleted.withOpacity(0.2)
                        : AppColors.prayer.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: FaIcon(
                    _getPrayerIcon(entry.type),
                    color: entry.fardPerformed
                        ? AppColors.prayerCompleted
                        : AppColors.prayer,
                    size: 16,
                  ),
                ),
                const SizedBox(width: AppDimensions.s8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.type.displayName,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        DateFormat('HH:mm').format(entry.scheduledTime),
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
          
          const SizedBox(width: AppDimensions.s8),
          
          // Fard status toggle
          GestureDetector(
            onTap: () async {
              try {
                // Show loading feedback
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text('Updating ${entry.type.displayName}...'),
                      ],
                    ),
                    backgroundColor: AppColors.prayer,
                    duration: const Duration(milliseconds: 800),
                  ),
                );
                
                await _prayerService.toggleFardPrayer(entry.type, date: date);
                await _loadPrayerHistory();
                
                // Show success feedback
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.white, size: 16),
                          const SizedBox(width: 8),
                          Text('${entry.type.displayName} updated'),
                        ],
                      ),
                      backgroundColor: AppColors.prayerCompleted,
                      duration: const Duration(seconds: 1),
                    ),
                  );
                }
              } catch (e) {
                debugPrint('Error updating Fard prayer: $e');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.error, color: Colors.white, size: 16),
                          const SizedBox(width: 8),
                          Expanded(child: Text('Failed to update: $e')),
                        ],
                      ),
                      backgroundColor: AppColors.error,
                      action: SnackBarAction(
                        label: 'RETRY',
                        textColor: Colors.white,
                        onPressed: () async {
                          try {
                            await _prayerService.toggleFardPrayer(entry.type, date: date);
                            await _loadPrayerHistory();
                          } catch (retryError) {
                            debugPrint('Retry failed: $retryError');
                          }
                        },
                      ),
                    ),
                  );
                }
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.s8,
                vertical: AppDimensions.s4,
              ),
              decoration: BoxDecoration(
                color: entry.fardPerformed
                    ? AppColors.prayerCompleted
                    : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    entry.fardPerformed ? Icons.check : Icons.close,
                    color: entry.fardPerformed ? Colors.white : Colors.grey.shade600,
                    size: 14,
                  ),
                  const SizedBox(width: AppDimensions.s4),
                  Text(
                    'Fard',
                    style: TextStyle(
                      color: entry.fardPerformed ? Colors.white : Colors.grey.shade600,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(width: AppDimensions.s8),
          
          // Sunnah toggles
          Expanded(
            flex: 3,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: entry.sunnahs.entries.map((sunnah) {
                  return Padding(
                    padding: const EdgeInsets.only(right: AppDimensions.s4),
                    child: GestureDetector(
                      onTap: () async {
                        try {
                          // Show loading feedback
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text('Updating ${_getSunnahDisplayName(sunnah.key)}...'),
                                ],
                              ),
                              backgroundColor: AppColors.prayer,
                              duration: const Duration(milliseconds: 600),
                            ),
                          );
                          
                          await _prayerService.toggleSunnahPrayer(entry.type, sunnah.key, date: date);
                          await _loadPrayerHistory();
                          
                          // Show success feedback
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    const Icon(Icons.check_circle, color: Colors.white, size: 16),
                                    const SizedBox(width: 8),
                                    Text('${_getSunnahDisplayName(sunnah.key)} updated'),
                                  ],
                                ),
                                backgroundColor: AppColors.prayerUpcoming,
                                duration: const Duration(milliseconds: 800),
                              ),
                            );
                          }
                        } catch (e) {
                          debugPrint('Error updating Sunnah prayer: $e');
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    const Icon(Icons.error, color: Colors.white, size: 16),
                                    const SizedBox(width: 8),
                                    Expanded(child: Text('Failed to update Sunnah: $e')),
                                  ],
                                ),
                                backgroundColor: AppColors.error,
                                action: SnackBarAction(
                                  label: 'RETRY',
                                  textColor: Colors.white,
                                  onPressed: () async {
                                    try {
                                      await _prayerService.toggleSunnahPrayer(entry.type, sunnah.key, date: date);
                                      await _loadPrayerHistory();
                                    } catch (retryError) {
                                      debugPrint('Retry failed: $retryError');
                                    }
                                  },
                                ),
                              ),
                            );
                          }
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDimensions.s8,
                          vertical: AppDimensions.s4,
                        ),
                        decoration: BoxDecoration(
                          color: sunnah.value
                              ? AppColors.prayerUpcoming
                              : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                        ),
                        child: Text(
                          _getSunnahDisplayName(sunnah.key),
                          style: TextStyle(
                            color: sunnah.value ? Colors.white : Colors.grey.shade600,
                            fontSize: 9,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          
          const SizedBox(width: AppDimensions.s8),
          
          // Edit button
          GestureDetector(
            onTap: () => _showPrayerHistoryEditDialog(entry, date),
            child: Container(
              padding: const EdgeInsets.all(AppDimensions.s8),
              decoration: BoxDecoration(
                color: AppColors.prayer.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.edit,
                size: 16,
                color: AppColors.prayer,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildImanInsights() {
    return Container(
      margin: const EdgeInsets.all(AppDimensions.s16),
      padding: const EdgeInsets.all(AppDimensions.s20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppDimensions.s8),
                decoration: BoxDecoration(
                  color: AppColors.prayer.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const FaIcon(
                  FontAwesomeIcons.chartLine,
                  color: AppColors.prayer,
                  size: AppDimensions.iconMedium,
                ),
              ),
              const SizedBox(width: AppDimensions.s12),
              Text(
                'Iman Insights',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.prayer,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppDimensions.s24),
          
          // Prayer streak
          Center(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppDimensions.s16),
                  decoration: BoxDecoration(
                    color: AppColors.prayerCompleted.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Column(
                    children: [
                      const FaIcon(
                        FontAwesomeIcons.fire,
                        color: AppColors.prayerCompleted,
                        size: 32,
                      ),
                      const SizedBox(height: AppDimensions.s8),
                      Text(
                        '$_currentStreak',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.prayerCompleted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimensions.s8),
                Text(
                  'Current Prayer Streak',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  _currentStreak == 1 ? 'day' : 'days',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: AppDimensions.s24),
          
          // Additional metrics could go here
          Text(
            'Keep up the excellent work! Your dedication to prayer is inspiring.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
  
  void _showPrayerDetailsDialog(PrayerType prayerType) {
    // Find the prayer record for the selected date
    final selectedRecord = _prayerHistory.firstWhere(
      (record) => _isSameDay(record.date, _selectedDate),
      orElse: () => PrayerRecord(
        id: '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
        date: _selectedDate,
        prayers: {},
      ),
    );
    
    final entry = selectedRecord.prayers[prayerType];
    final prayerTime = _currentPrayerTimes?.getPrayerTime(prayerType);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
                _getPrayerIcon(prayerType),
                color: AppColors.prayer,
                size: AppDimensions.iconMedium,
              ),
            ),
            const SizedBox(width: AppDimensions.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(prayerType.displayName),
                  Text(
                    DateFormat('MMM d, yyyy').format(_selectedDate),
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
            if (prayerTime != null)
              Text('Time: ${DateFormat('HH:mm').format(prayerTime)}'),
            
            const SizedBox(height: AppDimensions.s16),
            
            if (entry != null) ...[
              Text(
                'Status: ${entry.fardPerformed ? 'Completed' : 'Not completed'}',
                style: TextStyle(
                  color: entry.fardPerformed 
                      ? AppColors.prayerCompleted 
                      : AppColors.prayerMissed,
                  fontWeight: FontWeight.w500,
                ),
              ),
              
              if (entry.timeMarked != null)
                Text(
                  'Marked at: ${DateFormat('HH:mm').format(entry.timeMarked!)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ] else ...[
              Text(
                'Status: No data available',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          // Only show "Mark as Prayed" button for today and if not completed
          if (_isSameDay(_selectedDate, DateTime.now()) && entry != null && !entry.fardPerformed)
            ElevatedButton(
              onPressed: () async {
                await _markPrayerCompleted(prayerType);
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.prayerCompleted,
                foregroundColor: Colors.white,
              ),
              child: const Text('Mark as Prayed'),
            ),
        ],
      ),
    );
  }
  
  void _showPrayerHistoryEditDialog(PrayerEntry entry, DateTime date) {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          // Find the current entry from the updated prayer history
          final currentRecord = _prayerHistory.firstWhere(
            (record) => record.date.year == date.year && 
                        record.date.month == date.month && 
                        record.date.day == date.day,
            orElse: () => PrayerRecord(
              id: '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
              date: date,
              prayers: {entry.type: entry},
            ),
          );
          final currentEntry = currentRecord.prayers[entry.type] ?? entry;
          
          return AlertDialog(
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
                    _getPrayerIcon(currentEntry.type),
                    color: AppColors.prayer,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppDimensions.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${currentEntry.type.displayName} Prayer',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        DateFormat('EEEE, MMM d').format(date),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Fard Prayer Toggle
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppDimensions.s12),
                      decoration: BoxDecoration(
                        color: currentEntry.fardPerformed
                            ? AppColors.prayerCompleted.withOpacity(0.1)
                            : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                        border: Border.all(
                          color: currentEntry.fardPerformed
                              ? AppColors.prayerCompleted
                              : Colors.grey.shade300,
                        ),
                      ),
                      child: Row(
                        children: [
                          Checkbox(
                            value: currentEntry.fardPerformed,
                            onChanged: (value) async {
                              try {
                                if (value != null) {
                                  await _prayerService.markPrayerCompleted(currentEntry.type, date: date, completed: value);
                                }
                                // Refresh the dialog and main list
                                await _loadPrayerHistory();
                                setDialogState(() {});
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error updating prayer: $e'),
                                    backgroundColor: AppColors.error,
                                  ),
                                );
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
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: currentEntry.fardPerformed
                                        ? AppColors.prayerCompleted
                                        : null,
                                  ),
                                ),
                                Text(
                                  'Scheduled: ${DateFormat('HH:mm').format(currentEntry.scheduledTime)}',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                  ),
                                ),
                                if (currentEntry.timeMarked != null)
                                  Text(
                                    'Marked: ${DateFormat('HH:mm').format(currentEntry.timeMarked!)}',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.prayerCompleted,
                                      fontSize: 10,
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
                    ..._buildHistorySunnahToggles(currentEntry, date, setDialogState),
                  ],
                ),
              ),
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
                      content: Text('${currentEntry.type.displayName} prayer updated for ${DateFormat('MMM d').format(date)}'),
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
          );
        },
      ),
    );
  }
  
  List<Widget> _buildHistorySunnahToggles(PrayerEntry entry, DateTime date, StateSetter setDialogState) {
    final sunnahOptions = _getHistorySunnahOptions(entry.type);
    
    return sunnahOptions.map((sunnah) {
      final isCompleted = entry.sunnahs[sunnah.key] ?? false;
      
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(vertical: AppDimensions.s4),
        child: Row(
          children: [
            Checkbox(
              value: isCompleted,
              onChanged: (value) async {
                try {
                  await _prayerService.toggleSunnahPrayer(entry.type, sunnah.key, date: date);
                  // Refresh the dialog and main list
                  await _loadPrayerHistory();
                  setDialogState(() {});
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error updating Sunnah: $e'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
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
  
  List<({String key, String displayName, String? description})> _getHistorySunnahOptions(PrayerType prayerType) {
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
  
  String _formatCountdown(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours.toString().padLeft(2, '0')}:${(duration.inMinutes % 60).toString().padLeft(2, '0')}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}';
    } else {
      return '${duration.inMinutes.toString().padLeft(2, '0')}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}';
    }
  }
  
  String _getSunnahDisplayName(String key) {
    switch (key) {
      case 'beforeFajr':
        return 'Before';
      case 'beforeDhuhr':
        return 'Before';
      case 'afterDhuhr':
        return 'After';
      case 'beforeAsr':
        return 'Before';
      case 'afterMaghrib':
        return 'After';
      case 'afterIsha':
        return 'After';
      case 'witr':
        return 'Witr';
      default:
        return key;
    }
  }
  
  Future<void> _showDatePicker() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
              child: const Icon(
                Icons.calendar_month,
                color: AppColors.prayer,
              ),
            ),
            const SizedBox(width: AppDimensions.s12),
            const Expanded(
              child: Text('Select Date'),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Quick date options
            ListTile(
              leading: const Icon(Icons.today, color: AppColors.prayer),
              title: const Text('Today'),
              onTap: () async {
                Navigator.of(context).pop();
                final today = DateTime.now();
                await _loadPrayerHistoryForDateRange(
                  startDate: today,
                  endDate: today.add(const Duration(days: 1)),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.date_range, color: AppColors.prayer),
              title: const Text('Pick specific date'),
              onTap: () async {
                Navigator.of(context).pop();
                await _showSpecificDatePicker();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _showSpecificDatePicker() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.prayer,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      await _loadPrayerHistoryForDateRange(
        startDate: picked,
        endDate: picked.add(const Duration(days: 1)),
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isSameDay(picked, DateTime.now())
                  ? 'Showing today\'s prayers'
                  : 'Showing prayers for ${DateFormat('EEEE, MMM d, yyyy').format(picked)}'
            ),
            backgroundColor: AppColors.prayer,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }
  
  Future<void> _loadPrayerHistoryForDateRange({DateTime? startDate, DateTime? endDate}) async {
    try {
      setState(() => _isLoading = true);
      
      final history = await _prayerService.getPrayerRecords(
        startDate: startDate ?? DateTime.now().subtract(const Duration(days: 30)),
        endDate: endDate ?? DateTime.now(),
      );
      
      debugPrint('📅 Loaded ${history.length} prayer records for date range');
      
      // If we're loading a specific single date, update the selected date
      if (startDate != null && endDate != null) {
        final daysDifference = endDate.difference(startDate).inDays;
        if (daysDifference <= 1) {
          // Single day selection
          setState(() {
            _selectedDate = startDate;
            _prayerHistory = history;
            _isLoading = false;
          });
          
          // Load prayer times for the selected date if not today
          if (!_isSameDay(startDate, DateTime.now())) {
            final prayerTimes = await _prayerService.getPrayerTimesForDate(_selectedDate);
            if (prayerTimes != null) {
              setState(() {
                _currentPrayerTimes = prayerTimes;
              });
            }
          }
          return;
        }
      }
      
      // Multiple days or default range
      setState(() {
        _prayerHistory = history;
        _isLoading = false;
        // Reset to today view for multi-day ranges
        _selectedDate = DateTime.now();
      });
    } catch (e) {
      debugPrint('❌ Error loading prayer history for date range: $e');
      setState(() => _isLoading = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading prayer history: $e'),
            backgroundColor: AppColors.error,
            action: SnackBarAction(
              label: 'RETRY',
              textColor: Colors.white,
              onPressed: () => _loadPrayerHistoryForDateRange(
                startDate: startDate,
                endDate: endDate,
              ),
            ),
          ),
        );
      }
    }
  }
  
  void _showPrayerStatistics() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
              child: const Icon(
                Icons.bar_chart,
                color: AppColors.prayer,
              ),
            ),
            const SizedBox(width: AppDimensions.s12),
            const Text('Prayer Statistics'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: _buildPrayerChart(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showDatePicker();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.prayer,
              foregroundColor: Colors.white,
            ),
            child: const Text('View Specific Date'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPrayerChart() {
    if (_prayerHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bar_chart,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: AppDimensions.s16),
            Text(
              'No prayer data available',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: AppDimensions.s8),
            Text(
              'Start tracking your prayers to see statistics',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    // Calculate prayer completion percentages for each prayer type
    final Map<PrayerType, double> prayerStats = {};
    final Map<PrayerType, Color> prayerColors = {
      PrayerType.fajr: const Color(0xFF4CAF50),    // Green - Dawn
      PrayerType.dhuhr: const Color(0xFFFF9800),   // Orange - Noon
      PrayerType.asr: const Color(0xFF2196F3),     // Blue - Afternoon  
      PrayerType.maghrib: const Color(0xFF9C27B0), // Purple - Sunset
      PrayerType.isha: const Color(0xFF3F51B5),    // Indigo - Night
    };
    
    for (final prayerType in PrayerType.values) {
      int completed = 0;
      int total = 0;
      
      for (final record in _prayerHistory) {
        final entry = record.prayers[prayerType];
        if (entry != null) {
          total++;
          if (entry.fardPerformed) {
            completed++;
          }
        }
      }
      
      prayerStats[prayerType] = total > 0 ? (completed / total) * 100 : 0;
    }

    return Column(
      children: [
        // Chart Title
        Padding(
          padding: const EdgeInsets.all(AppDimensions.s16),
          child: Text(
            'Prayer Completion Statistics (Last ${_prayerHistory.length} days)',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.prayer,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        
        // Bar Chart
        Expanded(
          child: BarChart(
            BarChartData(
              maxY: 100,
              minY: 0,
              barGroups: PrayerType.values.asMap().entries.map((entry) {
                final index = entry.key;
                final prayerType = entry.value;
                final percentage = prayerStats[prayerType] ?? 0;
                
                return BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: percentage,
                      color: prayerColors[prayerType],
                      width: 30,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(4),
                      ),
                    ),
                  ],
                );
              }).toList(),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 25,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        '${value.toInt()}%',
                        style: Theme.of(context).textTheme.bodySmall,
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final prayerType = PrayerType.values[value.toInt()];
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            FaIcon(
                              _getPrayerIcon(prayerType),
                              size: 16,
                              color: prayerColors[prayerType],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              prayerType.displayName,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontSize: 10,
                                color: prayerColors[prayerType],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
              gridData: FlGridData(
                show: true,
                horizontalInterval: 25,
                verticalInterval: 1,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: Colors.grey.shade300,
                    strokeWidth: 1,
                  );
                },
                getDrawingVerticalLine: (value) {
                  return FlLine(
                    color: Colors.grey.shade300,
                    strokeWidth: 0.5,
                  );
                },
              ),
              borderData: FlBorderData(show: false),
            ),
          ),
        ),
        
        // Statistics Summary
        Padding(
          padding: const EdgeInsets.all(AppDimensions.s16),
          child: Wrap(
            spacing: AppDimensions.s16,
            runSpacing: AppDimensions.s8,
            children: PrayerType.values.map((prayerType) {
              final percentage = prayerStats[prayerType] ?? 0;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: prayerColors[prayerType],
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: AppDimensions.s8),
                  Text(
                    '${prayerType.displayName}: ${percentage.toStringAsFixed(1)}%',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
  
  void _goBackToToday() {
    setState(() {
      _selectedDate = DateTime.now();
    });
    _loadPrayerHistory();
  }
  
  Widget _buildHistoricalDayOverview() {
    // Find the prayer record for the selected date
    final selectedRecord = _prayerHistory.firstWhere(
      (record) => _isSameDay(record.date, _selectedDate),
      orElse: () => PrayerRecord(
        id: '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
        date: _selectedDate,
        prayers: {},
      ),
    );
    
    final completedPrayers = selectedRecord.prayers.values.where((p) => p.fardPerformed).length;
    final totalPrayers = 5;
    final completionPercentage = completedPrayers / totalPrayers;
    
    return Center(
      child: Column(
        children: [
          CircularPercentIndicator(
            radius: 60.0,
            lineWidth: 8.0,
            percent: completionPercentage,
            center: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$completedPrayers/$totalPrayers',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.prayer,
                  ),
                ),
                Text(
                  'Prayers',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.prayer,
                  ),
                ),
              ],
            ),
            progressColor: selectedRecord.allFardCompleted 
                ? AppColors.prayerCompleted 
                : AppColors.prayer,
            backgroundColor: AppColors.prayer.withOpacity(0.1),
            circularStrokeCap: CircularStrokeCap.round,
          ),
          const SizedBox(height: AppDimensions.s8),
          Text(
            selectedRecord.allFardCompleted 
                ? 'All prayers completed! 🎉'
                : 'Historical prayer data',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: selectedRecord.allFardCompleted 
                  ? AppColors.prayerCompleted 
                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
  
  /// Helper method to check if two dates are the same day
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }
  
  /// Helper method to safely convert percentage to int, handling Infinity and NaN
  int _safePercentageToInt(double percentage) {
    if (percentage.isNaN || percentage.isInfinite) {
      return 0;
    }
    final result = (percentage * 100);
    if (result.isNaN || result.isInfinite) {
      return 0;
    }
    return result.clamp(0.0, 100.0).toInt();
  }
  
  /// Helper method to safely handle percentage values for CircularPercentIndicator
  double _safePercentage(double percentage) {
    if (percentage.isNaN || percentage.isInfinite) {
      return 0.0;
    }
    return percentage.clamp(0.0, 1.0);
  }
} 