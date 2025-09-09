import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:focuz/app.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// A widget that provides a theme toggle button for app bars
class ThemeToggleWidget extends StatelessWidget {
  final bool showLabel;
  
  const ThemeToggleWidget({
    super.key,
    this.showLabel = false,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    // Wait for theme provider to initialize
    if (!themeProvider.isInitialized) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
    
    final isDark = themeProvider.themeMode == ThemeMode.dark || 
               (themeProvider.isSystemMode && 
                MediaQuery.of(context).platformBrightness == Brightness.dark);
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showLabel)
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Text(
              themeProvider.getEffectiveThemeName(context),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        IconButton(
          icon: Icon(
            isDark
                ? Icons.light_mode
                : Icons.dark_mode,
            size: 20,
          ),
          tooltip: 'Toggle theme',
          onPressed: () {
            themeProvider.toggleTheme();
          },
        ),
      ],
    );
  }
}

/// A popup menu for more detailed theme mode selection (system/light/dark)
class ThemeMenuButton extends StatelessWidget {
  const ThemeMenuButton({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    // Wait for theme provider to initialize
    if (!themeProvider.isInitialized) {
      return const SizedBox(
        width: 40,
        height: 40,
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    
    return PopupMenuButton<ThemeMode>(
      tooltip: 'Select theme mode',
      position: PopupMenuPosition.under,
      icon: const Icon(Icons.palette_outlined),
      initialValue: themeProvider.themeMode,
      onSelected: (ThemeMode mode) {
        themeProvider.setThemeMode(mode);
      },
      itemBuilder: (context) => [
        PopupMenuItem<ThemeMode>(
          value: ThemeMode.system,
          child: Row(
            children: [
              const Icon(Icons.settings_suggest_outlined),
              const SizedBox(width: 8),
              const Text('System'),
              const SizedBox(width: 8),
              if (themeProvider.isSystemMode)
                const Icon(Icons.check, size: 16),
            ],
          ),
        ),
        PopupMenuItem<ThemeMode>(
          value: ThemeMode.light,
          child: Row(
            children: [
              const Icon(Icons.light_mode_outlined),
              const SizedBox(width: 8),
              const Text('Light'),
              const SizedBox(width: 8),
              if (themeProvider.themeMode == ThemeMode.light)
                const Icon(Icons.check, size: 16),
            ],
          ),
        ),
        PopupMenuItem<ThemeMode>(
          value: ThemeMode.dark,
          child: Row(
            children: [
              const Icon(Icons.dark_mode_outlined),
              const SizedBox(width: 8),
              const Text('Dark'),
              const SizedBox(width: 8),
              if (themeProvider.themeMode == ThemeMode.dark)
                const Icon(Icons.check, size: 16),
            ],
          ),
        ),
      ],
    );
  }
} 