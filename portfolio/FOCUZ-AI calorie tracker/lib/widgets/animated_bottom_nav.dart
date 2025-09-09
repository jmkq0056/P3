import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../core/constants.dart';
import '../core/assets.dart';

class AnimatedBottomNav extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;

  const AnimatedBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    // Get safe area bottom padding to adjust for different devices
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          // Adjust height dynamically based on device's safe area
          height: 65 + (bottomPadding > 0 ? bottomPadding : 16),
          // Use safe area padding if available, or default to standard padding
          padding: EdgeInsets.only(
            bottom: bottomPadding > 0 ? bottomPadding : 8, 
            top: 4
          ),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).bottomNavigationBarTheme.backgroundColor?.withOpacity(0.85),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 8,
                spreadRadius: 1,
                offset: const Offset(0, 0),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                context: context,
                icon: AppAssets.iconDashboard,
                label: 'Home',  // Shorter text
                index: 0,
              ),
              _buildNavItem(
                context: context,
                icon: AppAssets.iconTraining,
                label: 'Training',
                index: 1,
              ),
              _buildNavItem(
                context: context,
                icon: AppAssets.iconMeals,
                label: 'Meals',
                index: 2,
              ),
              _buildNavItem(
                context: context,
                icon: AppAssets.iconMetrics,
                label: 'Metrics',
                index: 3,
              ),
              _buildNavItem(
                context: context,
                icon: AppAssets.iconSettings,
                label: 'Settings',
                index: 4,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required int index,
  }) {
    final isSelected = selectedIndex == index;
    final color = isSelected
        ? Theme.of(context).bottomNavigationBarTheme.selectedItemColor
        : Theme.of(context).bottomNavigationBarTheme.unselectedItemColor;

    // Fixed width to ensure all items are the same size
    return SizedBox(
      width: 60,
      child: GestureDetector(
        onTap: () => onItemSelected(index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: AppDurations.short,
          padding: const EdgeInsets.symmetric(vertical: 2),
          decoration: BoxDecoration(
            color: isSelected
                ? color?.withOpacity(0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedScale(
                scale: isSelected ? 1.15 : 1.0,
                duration: AppDurations.short,
                child: FaIcon(
                  icon,
                  color: color,
                  size: 22,
                ),
              ),
              const SizedBox(height: 2),
              // Always render text but with conditional opacity
              // This prevents layout shifts
              AnimatedOpacity(
                opacity: isSelected ? 1.0 : 0.0,
                duration: AppDurations.short,
                child: SizedBox(
                  height: 16,
                  child: Text(
                    label,
                    style: TextStyle(
                      color: color,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 