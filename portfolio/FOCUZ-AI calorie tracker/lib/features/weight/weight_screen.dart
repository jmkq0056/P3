import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:lottie/lottie.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/assets.dart';
import '../../core/constants.dart';
import '../../models/health_data.dart';
import '../../services/health_service.dart';
import '../dashboard/dashboard_screen.dart'; // Import to access AppState
import 'dart:math' as Math;

class WeightScreen extends StatefulWidget {
  const WeightScreen({super.key});

  @override
  State<WeightScreen> createState() => _WeightScreenState();
}

class _WeightScreenState extends State<WeightScreen> {
  final HealthService _healthService = HealthService();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final AppState _appState = AppState(); // Add reference to global app state
  
  // Weight data
  double _currentWeight = 0;
  double _startWeight = 0;
  double _goalWeight = 75.0; // This could be made configurable in settings
  List<WeightEntry> _weightEntries = [];
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _initializeService();
  }
  
  @override
  void dispose() {
    _weightController.dispose();
    _noteController.dispose();
    super.dispose();
  }
  
  Future<void> _initializeService() async {
    setState(() {
      _isLoading = true;
    });
    
    await _healthService.init();
    _loadWeightData();
  }
  
  void _loadWeightData() {
    setState(() {
      _weightEntries = _healthService.getAllWeightEntries();
      
      // Sort entries by date, newest first
      _weightEntries.sort((a, b) => b.date.compareTo(a.date));
      
      // Set current weight to latest entry, or default
      _currentWeight = _weightEntries.isNotEmpty ? _weightEntries.first.weight : 80.0;
      
      // Set start weight to oldest entry or default
      _startWeight = _weightEntries.isNotEmpty ? 
          _weightEntries.reduce((a, b) => a.date.isBefore(b.date) ? a : b).weight : 85.0;
      
      _isLoading = false;
    });
  }
  
  Future<void> _addWeightEntry(double weight, String? note) async {
    final entry = WeightEntry(
      date: DateTime.now(),
      weight: weight,
      note: note?.isNotEmpty == true ? note : null,
    );
    
    await _healthService.addWeightEntry(entry);
    _loadWeightData();
    _appState.notifyDataChanged(); // Notify that data has changed
  }
  
  Future<void> _deleteWeightEntry(String id) async {
    await _healthService.deleteWeightEntry(id);
    _loadWeightData();
    _appState.notifyDataChanged(); // Notify that data has changed
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weight Tracking'),
        actions: [
          IconButton(
            icon: FaIcon(
              AppAssets.iconCalendar,
              size: AppDimensions.iconMedium,
            ),
            onPressed: () {
              // Show calendar
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
                  // Current weight card
                  _buildCurrentWeightCard(),
                  const SizedBox(height: AppDimensions.s32),
                  
                  // Weight history chart
                  Text(
                    'Weight History',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppDimensions.s16),
                  _buildWeightChart(),
                  const SizedBox(height: AppDimensions.s32),
                  
                  // Weight log
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Weight Log',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      TextButton.icon(
                        onPressed: () {
                          _showAddWeightDialog();
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
                  _buildWeightLogList(),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showAddWeightDialog();
        },
        icon: FaIcon(
          AppAssets.iconWeight,
          size: AppDimensions.iconMedium,
        ),
        label: const Text('Log Weight'),
        backgroundColor: AppColors.weight,
      ),
    );
  }

  Widget _buildCurrentWeightCard() {
    final progress = _startWeight > _goalWeight 
        ? (_startWeight - _currentWeight) / (_startWeight - _goalWeight)
        : (_currentWeight - _startWeight) / (_goalWeight - _startWeight);
    final formattedProgress = (progress * 100).toInt().clamp(0, 100);
    
    final weightToGo = (_currentWeight - _goalWeight).abs().toStringAsFixed(1);
    
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: AppColors.weight.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Weight display section
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
                          'Current Weight',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppDimensions.s8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              _currentWeight.toStringAsFixed(1),
                              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.weight,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Text(
                                ' kg',
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
                        color: AppColors.weight.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                      ),
                      child: FaIcon(
                        AppAssets.iconWeight,
                        size: AppDimensions.iconLarge,
                        color: AppColors.weight,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.s24),
                
                // Progress slider with animation
                SizedBox(
                  height: 150,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Progress indicator
                      SizedBox(
                        width: 120,
                        height: 120,
                        child: CircularProgressIndicator(
                          value: progress.clamp(0.0, 1.0),
                          strokeWidth: 12,
                          backgroundColor: AppColors.weight.withOpacity(0.2),
                          color: AppColors.weight,
                        ),
                      ),
                      
                      // Progress percentage
                      Text(
                        '$formattedProgress%',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.weight,
                        ),
                      ),
                      
                      // Weight slider
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: SliderTheme(
                          data: SliderThemeData(
                            activeTrackColor: AppColors.weight,
                            inactiveTrackColor: AppColors.weight.withOpacity(0.2),
                            thumbColor: AppColors.weight,
                            trackHeight: 8,
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 12,
                            ),
                          ),
                          child: Slider(
                            value: _currentWeight,
                            min: _goalWeight - 20,
                            max: Math.max(_startWeight + 10, 130.0),
                            onChanged: (value) {
                              setState(() {
                                _currentWeight = double.parse(value.toStringAsFixed(1));
                              });
                            },
                            onChangeEnd: (value) {
                              // Ask user if they want to save this weight
                              _showQuickAddDialog(value);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Goal indicator
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppDimensions.s16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Start',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                          Text(
                            '${_startWeight.toStringAsFixed(1)} kg',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Goal',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                '${_goalWeight.toStringAsFixed(1)} kg',
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 4),
                              InkWell(
                                onTap: _showEditGoalDialog,
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding: const EdgeInsets.all(4.0),
                                  child: Icon(
                                    Icons.edit,
                                    size: 16,
                                    color: AppColors.weight.withOpacity(0.8),
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
              ],
            ),
          ),
          
          // Quick stats
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: AppDimensions.s16),
            decoration: BoxDecoration(
              color: AppColors.weight.withOpacity(0.08),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(AppDimensions.radiusLarge),
                bottomRight: Radius.circular(AppDimensions.radiusLarge),
              ),
            ),
            child: Column(
              children: [
                Text(
                  _getWeightTrendText(),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: _getWeightTrendColor(),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppDimensions.s4),
                Text(
                  '$weightToGo kg to goal',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeightChart() {
    if (_weightEntries.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        ),
        child: Center(
          child: Text(
            'No weight data yet',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ),
      );
    }
    
    // Sort entries by date, oldest first for the chart
    final sortedEntries = List<WeightEntry>.from(_weightEntries)
      ..sort((a, b) => a.date.compareTo(b.date));
    
    // Find min and max weight values for scaling
    final double minWeight = sortedEntries.map((e) => e.weight).reduce((a, b) => a < b ? a : b) - 1;
    final double maxWeight = sortedEntries.map((e) => e.weight).reduce((a, b) => a > b ? a : b) + 1;
    
    return Container(
      height: 220,
      padding: const EdgeInsets.all(AppDimensions.s16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${sortedEntries.length} Entries',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                _getWeightChangeText(sortedEntries),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: _getWeightTrendColor(),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.s16),
          
          // Chart
          Expanded(
            child: _buildLineChart(sortedEntries, minWeight, maxWeight),
          ),
        ],
      ),
    );
  }
  
  Widget _buildLineChart(List<WeightEntry> entries, double minWeight, double maxWeight) {
    // Use FL Chart instead of custom painter for better visualization
    return LineChart(
      LineChartData(
        minX: 0,
        maxX: entries.length.toDouble() - 1,
        minY: minWeight,
        maxY: maxWeight,
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    fontSize: 10,
                  ),
                );
              },
              interval: 5,
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                // Calculate interval for dates (handle case when entries.length is too small)
                final interval = entries.length < 4 ? 1 : (entries.length ~/ 3);
                
                if ((entries.length >= 4 && value.toInt() % interval == 0) || 
                    value.toInt() == entries.length - 1 || 
                    value.toInt() == 0) {
                  final index = value.toInt();
                  if (index < entries.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        DateFormat('MMM d').format(entries[index].date),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          fontSize: 10,
                        ),
                      ),
                    );
                  }
                }
                return const SizedBox();
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(entries.length, (index) {
              return FlSpot(index.toDouble(), entries[index].weight);
            }),
            isCurved: true,
            color: AppColors.weight,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: AppColors.weight,
                  strokeWidth: 1,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.weight.withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeightLogList() {
    if (_weightEntries.isEmpty) {
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
                Icons.scale_outlined,
                size: 48,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
              ),
              const SizedBox(height: AppDimensions.s16),
              Text(
                'No weight entries yet',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
              const SizedBox(height: AppDimensions.s8),
              Text(
                'Tap the button below to add your weight',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
      itemCount: _weightEntries.length,
      itemBuilder: (context, index) {
        final entry = _weightEntries[index];
        final previousWeight = index < _weightEntries.length - 1 ? _weightEntries[index + 1].weight : null;
        
        return Dismissible(
          key: Key(entry.id),
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
                content: const Text('Are you sure you want to delete this weight entry?'),
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
            _deleteWeightEntry(entry.id);
          },
          child: Card(
            margin: const EdgeInsets.only(bottom: AppDimensions.s8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.weight.withOpacity(0.1),
                child: FaIcon(
                  AppAssets.iconWeight,
                  size: AppDimensions.iconMedium,
                  color: AppColors.weight,
                ),
              ),
              title: Text(
                '${entry.weight.toStringAsFixed(1)} kg',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formatDate(entry.date),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (entry.note != null)
                    Text(
                      entry.note!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
              trailing: previousWeight != null
                  ? _buildWeightDifference(entry.weight, previousWeight)
                  : null,
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildWeightDifference(double current, double previous) {
    final difference = current - previous;
    final isGain = difference > 0;
    final color = isGain ? Colors.red : Colors.green;
    final icon = isGain ? Icons.arrow_upward : Icons.arrow_downward;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 2),
          Text(
            '${difference.abs().toStringAsFixed(1)} kg',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddWeightDialog() {
    _weightController.text = _currentWeight.toStringAsFixed(1);
    _noteController.clear();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Weight Entry'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _weightController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Weight (kg)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppDimensions.s16),
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final weightText = _weightController.text.trim();
              if (weightText.isNotEmpty) {
                try {
                  final weight = double.parse(weightText);
                  _addWeightEntry(weight, _noteController.text.trim());
                  Navigator.of(context).pop();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a valid weight')),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
  
  void _showQuickAddDialog(double weight) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save Weight'),
        content: Text('Would you like to save ${weight.toStringAsFixed(1)} kg as your current weight?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () {
              _addWeightEntry(weight, 'Logged from slider');
              Navigator.of(context).pop();
            },
            child: const Text('Yes'),
          ),
        ],
      ),
    );
  }
  
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return 'Today, ${DateFormat('h:mm a').format(date)}';
    } else if (date.year == yesterday.year && date.month == yesterday.month && date.day == yesterday.day) {
      return 'Yesterday, ${DateFormat('h:mm a').format(date)}';
    } else {
      return DateFormat('MMM d, yyyy - h:mm a').format(date);
    }
  }
  
  String _getWeightTrendText() {
    if (_weightEntries.length < 2) return 'No trend data yet';
    
    final change = _weightEntries[0].weight - _weightEntries[1].weight;
    final isGain = change > 0;
    
    if (change.abs() < 0.1) return 'Weight stable';
    return isGain ? 'Gained ${change.toStringAsFixed(1)} kg' : 'Lost ${change.abs().toStringAsFixed(1)} kg';
  }
  
  Color _getWeightTrendColor() {
    if (_weightEntries.length < 2) return Colors.grey;
    
    final change = _weightEntries[0].weight - _weightEntries[1].weight;
    final isGain = change > 0;
    
    final goalIsLower = _goalWeight < _startWeight;
    final trendIsGood = goalIsLower ? !isGain : isGain;
    
    if (change.abs() < 0.1) return Colors.blue;
    return trendIsGood ? Colors.green : Colors.red;
  }
  
  String _getWeightChangeText(List<WeightEntry> entries) {
    if (entries.length < 2) return 'No change';
    
    final firstWeight = entries.first.weight;
    final lastWeight = entries.last.weight;
    final change = firstWeight - lastWeight;
    
    if (change > 0) {
      return '↑ ${change.toStringAsFixed(1)} kg';
    } else if (change < 0) {
      return '↓ ${change.abs().toStringAsFixed(1)} kg';
    } else {
      return 'No change';
    }
  }

  void _showEditGoalDialog() {
    final TextEditingController goalController = TextEditingController(text: _goalWeight.toStringAsFixed(1));
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Weight Goal'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: goalController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Goal Weight (kg)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppDimensions.s16),
            Text(
              'Set a realistic target for your weight journey.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontStyle: FontStyle.italic,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final goalText = goalController.text.trim();
              if (goalText.isNotEmpty) {
                try {
                  final goal = double.parse(goalText);
                  if (goal > 0 && goal < 300) {
                    setState(() {
                      _goalWeight = goal;
                    });
                    Navigator.of(context).pop();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter a valid weight between 0-300 kg')),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a valid weight')),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
} 