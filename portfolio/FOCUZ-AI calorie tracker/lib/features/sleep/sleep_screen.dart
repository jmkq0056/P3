import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:lottie/lottie.dart';
import 'package:intl/intl.dart';
import '../../core/assets.dart';
import '../../core/constants.dart';
import '../../models/health_data.dart';
import '../../services/health_service.dart';
import '../dashboard/dashboard_screen.dart'; // Import to access AppState
import 'dart:math' as math;

class SleepScreen extends StatefulWidget {
  const SleepScreen({super.key});

  @override
  State<SleepScreen> createState() => _SleepScreenState();
}

class _SleepScreenState extends State<SleepScreen> {
  final HealthService _healthService = HealthService();
  final AppState _appState = AppState(); // Add reference to global app state
  bool _isLoading = true;
  
  // Sleep data
  List<SleepEntry> _sleepEntries = [];
  SleepEntry? _currentSleep;
  
  // For adding new sleep entry
  late DateTime _bedTime;
  late DateTime _wakeTime;
  String _bedTimeDay = 'today'; // 'yesterday' or 'today'
  String _wakeTimeDay = 'today'; // 'yesterday' or 'today'
  final int _quality = 3;
  final TextEditingController _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeService();
    
    // Initialize with default times
    final now = DateTime.now();
    _bedTime = DateTime(now.year, now.month, now.day, 23, 0);
    _wakeTime = DateTime(now.year, now.month, now.day, 7, 0);
  }
  
  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }
  
  Future<void> _initializeService() async {
    setState(() {
      _isLoading = true;
    });
    
    await _healthService.init();
    _loadSleepData();
  }
  
  void _loadSleepData() {
    setState(() {
      _sleepEntries = _healthService.getAllSleepEntries();
      _sleepEntries.sort((a, b) => b.date.compareTo(a.date));
      
      // Set current sleep to latest entry
      _currentSleep = _sleepEntries.isNotEmpty ? _sleepEntries.first : null;
      
      _isLoading = false;
    });
  }
  
  Future<void> _addSleepEntry(DateTime date, DateTime bedTime, DateTime wakeTime, int quality, String? note) async {
    // Make sure the dates are on the same or consecutive days
    DateTime adjustedBedTime = bedTime;
    DateTime adjustedWakeTime = wakeTime;
    
    // Ensure proper date handling - if wake time is earlier in the day than bed time,
    // it means the person woke up the next day
    if (wakeTime.hour < bedTime.hour || (wakeTime.hour == bedTime.hour && wakeTime.minute < bedTime.minute)) {
      // Keep the bedTime as is, but ensure wakeTime is on the next day
      adjustedWakeTime = DateTime(
        bedTime.year,
        bedTime.month,
        bedTime.day + 1,
        wakeTime.hour,
        wakeTime.minute,
      );
    } else {
      // Both times are on the same day
      adjustedWakeTime = DateTime(
        bedTime.year,
        bedTime.month,
        bedTime.day,
        wakeTime.hour,
        wakeTime.minute,
      );
    }
    
    final entry = SleepEntry(
      date: date,
      bedTime: adjustedBedTime,
      wakeTime: adjustedWakeTime,
      quality: quality,
      note: note?.isNotEmpty == true ? note : null,
    );
    
    await _healthService.addSleepEntry(entry);
    _loadSleepData();
    _appState.notifyDataChanged(); // Notify that data has changed
  }
  
  Future<void> _deleteSleepEntry(String id) async {
    await _healthService.deleteSleepEntry(id);
    _loadSleepData();
    _appState.notifyDataChanged(); // Notify that data has changed
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sleep Tracking'),
        actions: [
          IconButton(
            icon: FaIcon(
              AppAssets.iconCalendar,
              size: AppDimensions.iconMedium,
            ),
            onPressed: () {
              // Show date picker
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimensions.s16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Today's sleep overview
                  _buildSleepOverview(),
                  const SizedBox(height: AppDimensions.s32),
                  
                  // Sleep log
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Sleep Log',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      TextButton.icon(
                        onPressed: () {
                          _showAddSleepDialog();
                        },
                        icon: FaIcon(
                          AppAssets.iconAdd,
                          size: AppDimensions.iconSmall,
                        ),
                        label: const Text('Add'),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.s16),
                  _buildSleepLog(),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showAddSleepDialog();
        },
        icon: FaIcon(
          AppAssets.iconSleep,
          size: AppDimensions.iconMedium,
        ),
        label: const Text('Log Sleep'),
        backgroundColor: AppColors.sleep,
      ),
    );
  }

  Widget _buildSleepOverview() {
    // If no sleep data yet, show empty state
    if (_currentSleep == null) {
      return Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
          boxShadow: [
            BoxShadow(
              color: AppColors.sleep.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        padding: const EdgeInsets.all(AppDimensions.s20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'No Sleep Data Yet',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Container(
                  padding: const EdgeInsets.all(AppDimensions.s8),
                  decoration: BoxDecoration(
                    color: AppColors.sleep.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                  ),
                  child: FaIcon(
                    AppAssets.iconSleep,
                    size: AppDimensions.iconLarge,
                    color: AppColors.sleep,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.s24),
            Center(
              child: Lottie.asset(
                AppAssets.lottieSleep,
                height: 150,
                width: 200,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.nightlight_round,
                    size: 80,
                    color: AppColors.sleep.withOpacity(0.3),
                  );
                },
              ),
            ),
            const SizedBox(height: AppDimensions.s16),
            Text(
              'Log your sleep to see stats',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }
    
    // Display latest sleep data
    final hours = _currentSleep!.durationInHours;
    final formattedBedTime = DateFormat('HH:mm').format(_currentSleep!.bedTime);
    final formattedWakeTime = DateFormat('HH:mm').format(_currentSleep!.wakeTime);
    
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: AppColors.sleep.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Sleep stats section
          Padding(
            padding: const EdgeInsets.all(AppDimensions.s20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Last Night\'s Sleep',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppDimensions.s8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              hours.toStringAsFixed(1),
                              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.sleep,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Text(
                                ' hours',
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(AppDimensions.s8),
                      decoration: BoxDecoration(
                        color: AppColors.sleep.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                      ),
                      child: FaIcon(
                        AppAssets.iconSleep,
                        size: AppDimensions.iconLarge,
                        color: AppColors.sleep,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.s24),
                
                // Sleep visualization
                Container(
                  height: 140,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.sleep.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Lottie.asset(
                          AppAssets.lottieSleep,
                          fit: BoxFit.contain,
                          height: 120,
                          repeat: true,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.nightlight_round,
                              size: 60,
                              color: AppColors.sleep.withOpacity(0.3),
                            );
                          },
                        ),
                      ),
                      // Sleep time indicator
                      Positioned(
                        bottom: 10,
                        left: 20,
                        right: 20,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Bed Time',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                  ),
                                ),
                                Text(
                                  formattedBedTime,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Wake Time',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                  ),
                                ),
                                Text(
                                  formattedWakeTime,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Sleep quality section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: AppDimensions.s16),
            decoration: BoxDecoration(
              color: AppColors.sleep.withOpacity(0.08),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(AppDimensions.radiusLarge),
                bottomRight: Radius.circular(AppDimensions.radiusLarge),
              ),
            ),
            child: Column(
              children: [
                Text(
                  'Sleep Quality',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppDimensions.s4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return Icon(
                      index < _currentSleep!.quality ? Icons.star : Icons.star_border,
                      color: AppColors.sleep,
                      size: 24,
                    );
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSleepLog() {
    if (_sleepEntries.isEmpty) {
      return Container(
        height: 150,
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.nightlight_round,
                size: 48,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
              ),
              const SizedBox(height: AppDimensions.s16),
              Text(
                'No sleep logs yet',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _sleepEntries.length,
      itemBuilder: (context, index) {
        final sleep = _sleepEntries[index];
        final formattedDate = DateFormat('E, MMM d').format(sleep.date);
        final formattedBedTime = DateFormat('HH:mm').format(sleep.bedTime);
        final formattedWakeTime = DateFormat('HH:mm').format(sleep.wakeTime);
        
        return Dismissible(
          key: Key(sleep.id),
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: AppDimensions.s16),
            color: Colors.red,
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          direction: DismissDirection.endToStart,
          confirmDismiss: (direction) async {
            return await showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Delete Entry'),
                content: const Text('Are you sure you want to delete this sleep log?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Delete'),
                  ),
                ],
              ),
            );
          },
          onDismissed: (direction) {
            _deleteSleepEntry(sleep.id);
          },
          child: Card(
            margin: const EdgeInsets.only(bottom: AppDimensions.s8),
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.s16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppColors.sleep.withOpacity(0.1),
                        child: FaIcon(
                          AppAssets.iconSleep,
                          size: AppDimensions.iconMedium,
                          color: AppColors.sleep,
                        ),
                      ),
                      const SizedBox(width: AppDimensions.s12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              formattedDate,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Row(
                              children: List.generate(5, (i) {
                                return Icon(
                                  i < sleep.quality ? Icons.star : Icons.star_border,
                                  color: AppColors.sleep,
                                  size: 16,
                                );
                              }),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${sleep.durationInHours.toStringAsFixed(1)} hrs',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.sleep,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.s12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bed Time',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                          Text(
                            formattedBedTime,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Wake Time',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                          Text(
                            formattedWakeTime,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (sleep.note != null) ...[
                    const SizedBox(height: AppDimensions.s8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppDimensions.s8),
                      decoration: BoxDecoration(
                        color: AppColors.sleep.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                      ),
                      child: Text(
                        sleep.note!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  
  void _showAddSleepDialog() {
    _noteController.clear();
    
    // Reset to default values
    final now = DateTime.now();
    _bedTime = DateTime(now.year, now.month, now.day, 23, 0);
    _wakeTime = DateTime(now.year, now.month, now.day, 7, 0);
    _bedTimeDay = 'yesterday';
    _wakeTimeDay = 'today';
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          // Get actual dates based on selected day
          final today = DateTime.now();
          final yesterday = today.subtract(const Duration(days: 1));
          
          // Adjust bedTime based on selected day
          final actualBedTime = _bedTimeDay == 'yesterday'
              ? DateTime(yesterday.year, yesterday.month, yesterday.day, _bedTime.hour, _bedTime.minute)
              : DateTime(today.year, today.month, today.day, _bedTime.hour, _bedTime.minute);
          
          // Adjust wakeTime based on selected day
          final actualWakeTime = _wakeTimeDay == 'yesterday'
              ? DateTime(yesterday.year, yesterday.month, yesterday.day, _wakeTime.hour, _wakeTime.minute)
              : DateTime(today.year, today.month, today.day, _wakeTime.hour, _wakeTime.minute);
          
          // Calculate sleep duration
          Duration sleepDuration;
          if (actualWakeTime.isBefore(actualBedTime)) {
            // Handle negative duration (for example, bed yesterday and wake today)
            sleepDuration = actualWakeTime.add(const Duration(days: 1)).difference(actualBedTime);
          } else {
            sleepDuration = actualWakeTime.difference(actualBedTime);
          }
          
          final hours = sleepDuration.inHours;
          final minutes = sleepDuration.inMinutes % 60;
          
          return AlertDialog(
            title: const Text('Log Sleep'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sleep time selection with 24-hour format
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.sleep.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                      border: Border.all(color: AppColors.sleep.withOpacity(0.2)),
                    ),
                    child: Column(
                      children: [
                        // Sleep duration summary
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          decoration: BoxDecoration(
                            color: AppColors.sleep.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                          ),
                          child: Column(
                            children: [
                              Text(
                                'Sleep Duration',
                                style: TextStyle(
                                  color: AppColors.sleep,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$hours h $minutes min',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.sleep,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Bed Time selector with date
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'When did you go to bed?',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.sleep,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                // Yesterday/Today selector for bedtime
                                Expanded(
                                  flex: 2,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.sleep.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                                    ),
                                    child: DropdownButton<String>(
                                      value: _bedTimeDay,
                                      isExpanded: true,
                                      underline: const SizedBox(),
                                      items: [
                                        DropdownMenuItem(
                                          value: 'yesterday',
                                          child: Text('Yesterday (${DateFormat('MMM d').format(yesterday)})'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'today',
                                          child: Text('Today (${DateFormat('MMM d').format(today)})'),
                                        ),
                                      ],
                                      onChanged: (value) {
                                        if (value != null) {
                                          setState(() {
                                            _bedTimeDay = value;
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Time picker for bedtime
                                Expanded(
                                  flex: 1,
                                  child: InkWell(
                                    onTap: () async {
                                      final time = await showTimePicker(
                                        context: context,
                                        initialTime: TimeOfDay.fromDateTime(_bedTime),
                                        builder: (BuildContext context, Widget? child) {
                                          return MediaQuery(
                                            data: MediaQuery.of(context).copyWith(
                                              alwaysUse24HourFormat: true,
                                            ),
                                            child: child!,
                                          );
                                        },
                                      );
                                      if (time != null) {
                                        setState(() {
                                          _bedTime = DateTime(
                                            _bedTime.year,
                                            _bedTime.month,
                                            _bedTime.day,
                                            time.hour,
                                            time.minute,
                                          );
                                        });
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: AppColors.sleep,
                                        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                                      ),
                                      child: Text(
                                        DateFormat('HH:mm').format(_bedTime),
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Wake Time selector with date
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'When did you wake up?',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.sleep,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                // Yesterday/Today selector for wake time
                                Expanded(
                                  flex: 2,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.sleep.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                                    ),
                                    child: DropdownButton<String>(
                                      value: _wakeTimeDay,
                                      isExpanded: true,
                                      underline: const SizedBox(),
                                      items: [
                                        DropdownMenuItem(
                                          value: 'yesterday',
                                          child: Text('Yesterday (${DateFormat('MMM d').format(yesterday)})'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'today',
                                          child: Text('Today (${DateFormat('MMM d').format(today)})'),
                                        ),
                                      ],
                                      onChanged: (value) {
                                        if (value != null) {
                                          setState(() {
                                            _wakeTimeDay = value;
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Time picker for wake time
                                Expanded(
                                  flex: 1,
                                  child: InkWell(
                                    onTap: () async {
                                      final time = await showTimePicker(
                                        context: context,
                                        initialTime: TimeOfDay.fromDateTime(_wakeTime),
                                        builder: (BuildContext context, Widget? child) {
                                          return MediaQuery(
                                            data: MediaQuery.of(context).copyWith(
                                              alwaysUse24HourFormat: true,
                                            ),
                                            child: child!,
                                          );
                                        },
                                      );
                                      if (time != null) {
                                        setState(() {
                                          _wakeTime = DateTime(
                                            _wakeTime.year,
                                            _wakeTime.month,
                                            _wakeTime.day,
                                            time.hour,
                                            time.minute,
                                          );
                                        });
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: AppColors.sleep,
                                        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                                      ),
                                      child: Text(
                                        DateFormat('HH:mm').format(_wakeTime),
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: AppDimensions.s16),
                  
                  // Notes
                  TextField(
                    controller: _noteController,
                    decoration: const InputDecoration(
                      labelText: 'Notes (optional)',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  // Get actual dates based on selected day
                  final today = DateTime.now();
                  final yesterday = today.subtract(const Duration(days: 1));
                  
                  // Create actual bedTime with the correct date
                  final actualBedTime = _bedTimeDay == 'yesterday'
                      ? DateTime(yesterday.year, yesterday.month, yesterday.day, _bedTime.hour, _bedTime.minute)
                      : DateTime(today.year, today.month, today.day, _bedTime.hour, _bedTime.minute);
                  
                  // Create actual wakeTime with the correct date
                  final actualWakeTime = _wakeTimeDay == 'yesterday'
                      ? DateTime(yesterday.year, yesterday.month, yesterday.day, _wakeTime.hour, _wakeTime.minute)
                      : DateTime(today.year, today.month, today.day, _wakeTime.hour, _wakeTime.minute);
                  
                  // Calculate duration (handle case where wake time is before bed time)
                  Duration sleepDuration;
                  if (actualWakeTime.isBefore(actualBedTime)) {
                    // If wake time is before bed time, assume it's the next day
                    sleepDuration = actualWakeTime.add(const Duration(days: 1)).difference(actualBedTime);
                  } else {
                    sleepDuration = actualWakeTime.difference(actualBedTime);
                  }
                  
                  if (sleepDuration.inMinutes <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Sleep duration must be positive')),
                    );
                    return;
                  }
                  
                  if (sleepDuration.inHours > 24) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Sleep duration cannot exceed 24 hours')),
                    );
                    return;
                  }
                  
                  // Use the actual date for the sleep entry
                  _addSleepEntry(
                    actualWakeTime.toLocal(), 
                    actualBedTime,
                    actualWakeTime,
                    3,
                    _noteController.text.trim()
                  );
                  
                  Navigator.of(context).pop();
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }
} 