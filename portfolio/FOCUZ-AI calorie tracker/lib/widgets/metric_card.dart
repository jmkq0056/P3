import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../app_theme.dart';
import '../core/constants.dart';

class MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final Widget? subtitleWidget;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final Widget? progressIndicator;
  final bool isToggleClickable;

  const MetricCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    this.subtitleWidget,
    required this.icon,
    required this.color,
    required this.onTap,
    this.progressIndicator,
    this.isToggleClickable = false,
  }) : assert(subtitle == null || subtitleWidget == null, 'Cannot provide both subtitle and subtitleWidget');

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppDurations.medium,
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned(
              right: -15,
              top: -15,
              child: Opacity(
                opacity: 0.15,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppDimensions.s16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                            ),
                      ),
                      FaIcon(
                        icon,
                        color: color,
                        size: AppDimensions.iconMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.s8),
                  if (progressIndicator != null) ...[
                    progressIndicator!,
                    const SizedBox(height: AppDimensions.s8),
                  ],
                  Text(
                    value,
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: AppDimensions.s4),
                    Text(
                      subtitle!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                          ),
                    ),
                  ],
                  if (subtitleWidget != null) ...[
                    const SizedBox(height: AppDimensions.s4),
                    isToggleClickable 
                        ? subtitleWidget!
                        : IgnorePointer(child: subtitleWidget!),
                  ],
                ],
              ),
            ),
            // Hover effect overlay
            Positioned.fill(
              child: Material(
                color: Colors.transparent,
                child: isToggleClickable && subtitleWidget != null
                    ? Stack(
                        children: [
                          Positioned.fill(
                            child: InkWell(
                              splashColor: color.withOpacity(0.1),
                              highlightColor: color.withOpacity(0.05),
                              onTap: onTap,
                            ),
                          ),
                          // Add a positioned widget to create an exclusion zone
                          // This will prevent the card's tap from triggering when tapping the toggle
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            height: 30, // Approximate height for the toggle area
                            child: GestureDetector(
                              behavior: HitTestBehavior.translucent,
                              onTap: () {}, // Empty callback to absorb taps
                            ),
                          ),
                        ],
                      )
                    : InkWell(
                        splashColor: color.withOpacity(0.1),
                        highlightColor: color.withOpacity(0.05),
                        onTap: onTap,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 