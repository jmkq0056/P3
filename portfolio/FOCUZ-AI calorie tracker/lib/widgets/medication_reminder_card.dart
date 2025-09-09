import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../core/constants.dart';
import '../app_theme.dart';

/// A card widget that displays medication or supplement reminders
///
/// This widget shows either the next upcoming medication/supplement or a summary
/// of medications taken for the day.
class MedicationReminderCard extends StatelessWidget {
  final String title;
  final bool allTaken;
  final TimeOfDay? nextDose;
  final String? medicationName;
  final String? dosage;
  final VoidCallback onTap;

  const MedicationReminderCard({
    super.key,
    required this.title,
    required this.allTaken,
    this.nextDose,
    this.medicationName,
    this.dosage,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Determine color based on status
    final Color statusColor = allTaken 
        ? AppTheme.secondaryColor2 // Mint Green for all taken
        : nextDose != null
            ? AppTheme.secondaryColor1 // Coral for upcoming dose
            : AppTheme.primaryColor; // Primary Violet for default

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
              // Title and icon
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
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
                      allTaken 
                          ? FontAwesomeIcons.check 
                          : FontAwesomeIcons.pills,
                      color: statusColor,
                      size: AppDimensions.iconMedium,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: AppDimensions.s12),
              
              // Status content
              if (allTaken)
                _buildAllTakenContent(context)
              else if (nextDose != null && medicationName != null)
                _buildNextDoseContent(context)
              else
                _buildNoMedicationsContent(context),
                
              const SizedBox(height: AppDimensions.s8),
              
              // "Tap to view" hint
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.touch_app,
                    size: 12,
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Tap to view details',
                    style: TextStyle(
                      fontSize: 10,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // Helper to build "all taken" content
  Widget _buildAllTakenContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Success message
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.s12, 
            vertical: AppDimensions.s8
          ),
          decoration: BoxDecoration(
            color: AppTheme.secondaryColor2.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle,
                color: AppTheme.secondaryColor2,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'All medications taken!',
                style: TextStyle(
                  color: AppTheme.secondaryColor2,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: AppDimensions.s8),
        
        Text(
          'Great job staying on top of your health routine today.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      ],
    );
  }
  
  // Helper to build next dose content
  Widget _buildNextDoseContent(BuildContext context) {
    final formattedTime = '${nextDose!.hour.toString().padLeft(2, '0')}:${nextDose!.minute.toString().padLeft(2, '0')}';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Next dose time
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.s12, 
            vertical: AppDimensions.s8
          ),
          decoration: BoxDecoration(
            color: AppTheme.secondaryColor1.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.access_time,
                color: AppTheme.secondaryColor1,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'Next dose at $formattedTime',
                style: TextStyle(
                  color: AppTheme.secondaryColor1,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: AppDimensions.s8),
        
        // Medication details
        Row(
          children: [
            const Icon(
              FontAwesomeIcons.prescription,
              size: 14,
              color: AppTheme.primaryColor,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '$medicationName ${dosage != null ? '- $dosage' : ''}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  // Helper to build no medications content
  Widget _buildNoMedicationsContent(BuildContext context) {
    return Text(
      'No medications or supplements scheduled for today.',
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
        fontStyle: FontStyle.italic,
      ),
    );
  }
} 