import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../core/assets.dart';

/// A consistent app bar implementation for use across the app.
/// 
/// This widget handles both regular AppBar and SliverAppBar cases and always
/// shows the app logo in the right corner for consistent branding.
/// 
/// Only supports a single icon next to the logo.
/// 
/// IMPORTANT: The ThemeToggle should not be placed in the app bar.
/// Instead, add it as the first element in the body of the Settings screen.
/// 
/// Usage:
/// 
/// 1. Regular AppBar:
/// ```dart
/// appBar: CustomAppBar(
///   title: 'Screen Title',
///   showBackButton: true, // Optional: shows back button
///   icon: Icons.refresh, // Optional: single icon next to logo
///   onIconPressed: () {}, // Optional: action for the icon
/// ),
/// ```
/// 
/// 2. SliverAppBar:
/// ```dart
/// CustomScrollView(
///   slivers: [
///     CustomAppBar.sliver(
///       title: 'Screen Title',
///       floating: true,
///       icon: Icons.refresh,
///       onIconPressed: () {},
///     ),
///     // Other sliver widgets...
///   ],
/// )
/// ```
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final IconData? icon;
  final VoidCallback? onIconPressed;
  final PreferredSizeWidget? bottom;
  final double logoHeight;
  final bool showBackButton;
  final bool floating;
  final bool pinned;
  final bool isSliver;
  
  const CustomAppBar({
    super.key,
    required this.title,
    this.icon,
    this.onIconPressed,
    this.bottom,
    this.logoHeight = 85.0,
    this.showBackButton = false,
    this.floating = false,
    this.pinned = false,
    this.isSliver = false,
  });
  
  /// Factory constructor to create a sliver app bar
  factory CustomAppBar.sliver({
    required String title,
    IconData? icon,
    VoidCallback? onIconPressed,
    PreferredSizeWidget? bottom,
    double logoHeight = 85.0,
    bool showBackButton = false,
    bool floating = true,
    bool pinned = false,
  }) {
    return CustomAppBar(
      title: title,
      icon: icon,
      onIconPressed: onIconPressed,
      bottom: bottom,
      logoHeight: logoHeight,
      showBackButton: showBackButton,
      floating: floating,
      pinned: pinned,
      isSliver: true,
    );
  }
  
  @override
  Size get preferredSize => bottom == null
      ? const Size.fromHeight(kToolbarHeight)
      : Size.fromHeight(kToolbarHeight + bottom!.preferredSize.height);
  
  @override
  Widget build(BuildContext context) {
    // Determine which logo to use based on theme
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final String logoAsset = isDarkMode 
        ? AppAssets.splashFocuzLogoDark 
        : AppAssets.splashFocuzLogo;
    
    // Create the logo widget
    final Widget logoWidget = Padding(
      padding: const EdgeInsets.only(right: 16.0),
      child: Image.asset(
        logoAsset,
        height: logoHeight,
        fit: BoxFit.contain,
      ),
    );
    
    // Build action buttons - logo is always there, icon is optional
    final List<Widget> actionButtons = [
      if (icon != null)
        IconButton(
          icon: FaIcon(icon!),
          onPressed: onIconPressed,
        ),
      logoWidget,
    ];
    
    // Create the leading widget if needed
    Widget? leadingWidget;
    if (showBackButton) {
      leadingWidget = IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.of(context).pop(),
      );
    }
    
    // Common parameters for both AppBar types
    final Map<String, dynamic> appBarParams = {
      'leading': leadingWidget,
      'title': Text(
        title,
        style: const TextStyle(
          fontSize: 22.0,
        ),
      ),
      'titleSpacing': 5.0,
      'actions': actionButtons,
      'bottom': bottom,
    };
    
    // Return appropriate app bar type
    if (isSliver) {
      return SliverAppBar(
        floating: floating,
        pinned: pinned,
        leading: appBarParams['leading'],
        title: appBarParams['title'],
        titleSpacing: appBarParams['titleSpacing'],
        actions: appBarParams['actions'],
        bottom: appBarParams['bottom'],
      );
    } else {
      return AppBar(
        leading: appBarParams['leading'],
        title: appBarParams['title'],
        titleSpacing: appBarParams['titleSpacing'],
        actions: appBarParams['actions'],
        bottom: appBarParams['bottom'],
      );
    }
  }
} 