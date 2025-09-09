import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../core/constants.dart';
import '../app_theme.dart';

/// A card widget that displays a summary of habit tracking progress
/// 
/// This widget is designed to be used in the dashboard to provide a quick overview
/// of the user's habit tracking progress.
class HabitSummaryCard extends StatelessWidget {
  final String habitName;
  final int completedDays;
  final int totalDays;
  final IconData icon;
  final VoidCallback onTap;

  const HabitSummaryCard({
    super.key,
    required this.habitName,
    required this.completedDays,
    required this.totalDays,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate completion percentage
    final double completionPercent = totalDays > 0 
        ? completedDays / totalDays 
        : 0.0;
    
    // Determine color based on completion status
    final Color statusColor = _getStatusColor(completionPercent);
    
    // Check if dark mode is active
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          side: BorderSide(
            color: statusColor.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.s16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Habit name and icon
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      habitName,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(AppDimensions.s8),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: FaIcon(
                      icon,
                      color: statusColor,
                      size: AppDimensions.iconMedium,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: AppDimensions.s12),
              
              // Progress indicator
              LinearProgressIndicator(
                value: completionPercent,
                backgroundColor: isDarkMode 
                    ? Colors.grey.shade800 
                    : Colors.grey.shade200,
                color: statusColor,
                borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
              ),
              
              const SizedBox(height: AppDimensions.s8),
              
              // Completion text
              Text(
                '$completedDays/$totalDays days completed',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              
              const SizedBox(height: AppDimensions.s4),
              
              // Status message
              Text(
                _getStatusMessage(completionPercent),
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // Helper to get color based on completion percentage
  Color _getStatusColor(double percent) {
    if (percent >= 0.8) {
      return AppTheme.secondaryColor2; // Mint Green for excellent progress
    } else if (percent >= 0.5) {
      return AppTheme.primaryColor; // Primary violet for good progress
    } else {
      return AppTheme.secondaryColor1; // Coral for needs attention
    }
  }
  
  // Helper to get status message based on completion percentage
  String _getStatusMessage(double percent) {
    if (percent >= 0.8) {
      return 'Excellent progress!';
    } else if (percent >= 0.5) {
      return 'Good progress';
    } else if (percent >= 0.25) {
      return 'Keep going!';
    } else {
      return 'Just getting started';
    }
  }
} 