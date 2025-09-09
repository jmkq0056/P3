import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';
import '../../core/assets.dart';
import '../../core/constants.dart';
import '../../app.dart';
import '../../services/meal_service.dart';
import '../../models/meal_data.dart';
import '../../services/auth_service.dart';
import '../auth/screens/login_screen.dart';
import '../../widgets/custom_app_bar.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final MealService _mealService = MealService();
  final AuthService _authService = AuthService();
  final TextEditingController _heightController = TextEditingController(text: '194');
  String _selectedGender = 'male';
  bool _isLoading = true;
  bool _isLoggingOut = false;
  
  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }
  
  @override
  void dispose() {
    _heightController.dispose();
    super.dispose();
  }
  
  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
    });
    
    await _mealService.init();
    
    // Add debug information
    _mealService.debugStorageInfo();
    
    final profile = _mealService.getNutritionProfile();
    
    if (profile != null) {
      setState(() {
        _heightController.text = profile.heightCm.toString();
        _selectedGender = profile.gender;
      });
    }
    
    setState(() {
      _isLoading = false;
    });
  }
  
  Future<void> _saveUserProfile() async {
    // Hide keyboard when save button is pressed
    FocusScope.of(context).unfocus();
    
    final currentProfile = _mealService.getNutritionProfile();
    if (currentProfile == null) {
      debugPrint('ERROR: No current profile found');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No profile found. Please restart the app.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    final height = double.tryParse(_heightController.text) ?? 194.0;
    
    debugPrint('SAVING PROFILE: Height: ${height}cm, Gender: $_selectedGender');
    debugPrint('Current profile ID: ${currentProfile.id}');
    
    final updatedProfile = NutritionProfile(
      id: currentProfile.id,
      heightCm: height,
      weight: currentProfile.weight,
      age: currentProfile.age,
      gender: _selectedGender,
      activityLevel: currentProfile.activityLevel,
      goal: currentProfile.goal,
      customCalorieGoal: currentProfile.customCalorieGoal,
    );
    
    try {
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20, 
                height: 20, 
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
              ),
              SizedBox(width: 16),
              Text('Saving profile...'),
            ],
          ),
          duration: Duration(seconds: 2),
        ),
      );
      
      await _mealService.updateNutritionProfile(updatedProfile);
      
      // Verify the update was successful by reloading
      await _mealService.init();
      final verifyProfile = _mealService.getNutritionProfile();
      
      if (verifyProfile != null && 
          verifyProfile.heightCm == height && 
          verifyProfile.gender == _selectedGender) {
        debugPrint('SUCCESS: Profile saved and verified');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        debugPrint('WARNING: Profile saved but verification failed');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile may not have saved correctly. Please check and try again.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      debugPrint('ERROR saving profile: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving profile: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  // Handle user logout
  Future<void> _logout() async {
    setState(() {
      _isLoggingOut = true;
    });
    
    try {
      await _authService.signOut();
      
      if (mounted) {
        // Navigate to login screen and clear all routes
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false, // This removes all previous routes
        );
      }
    } catch (e) {
      print('Error logging out: $e');
      
      if (mounted) {
        setState(() {
          _isLoggingOut = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error logging out: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _logout();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Settings',
      ),
      body: Column(
        children: [
          // New theme toggle bar at the top of settings
          _buildThemeToggleBar(context),
          // Rest of settings in a ListView
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppDimensions.s16),
              children: [
                // User Profile section
                _buildSettingSection(
                  context: context,
                  title: 'User Profile',
                  children: [
                    // Height field
                    Padding(
                      padding: const EdgeInsets.all(AppDimensions.s16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(AppDimensions.s8),
                            decoration: BoxDecoration(
                              color: AppColors.weight.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                            ),
                            child: FaIcon(
                              FontAwesomeIcons.rulerVertical,
                              size: AppDimensions.iconMedium,
                              color: AppColors.weight,
                            ),
                          ),
                          const SizedBox(width: AppDimensions.s16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Height',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: AppDimensions.s8),
                                TextField(
                                  controller: _heightController,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    suffixText: 'cm',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Gender selection
                    Padding(
                      padding: const EdgeInsets.all(AppDimensions.s16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(AppDimensions.s8),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                            ),
                            child: FaIcon(
                              FontAwesomeIcons.venusMars,
                              size: AppDimensions.iconMedium,
                              color: AppColors.accent,
                            ),
                          ),
                          const SizedBox(width: AppDimensions.s16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Gender',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: AppDimensions.s12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _selectedGender = 'male';
                                          });
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: AppDimensions.s12,
                                            horizontal: AppDimensions.s16,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _selectedGender == 'male'
                                                ? AppColors.accent
                                                : AppColors.accent.withOpacity(0.1),
                                            borderRadius: const BorderRadius.horizontal(
                                              left: Radius.circular(AppDimensions.radiusMedium),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              FaIcon(
                                                FontAwesomeIcons.mars,
                                                size: AppDimensions.iconSmall,
                                                color: _selectedGender == 'male'
                                                    ? Colors.white
                                                    : AppColors.accent,
                                              ),
                                              const SizedBox(width: AppDimensions.s8),
                                              Text(
                                                'Male',
                                                style: TextStyle(
                                                  color: _selectedGender == 'male'
                                                      ? Colors.white
                                                      : AppColors.accent,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _selectedGender = 'female';
                                          });
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: AppDimensions.s12,
                                            horizontal: AppDimensions.s16,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _selectedGender == 'female'
                                                ? AppColors.accent
                                                : AppColors.accent.withOpacity(0.1),
                                            borderRadius: const BorderRadius.horizontal(
                                              right: Radius.circular(AppDimensions.radiusMedium),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              FaIcon(
                                                FontAwesomeIcons.venus,
                                                size: AppDimensions.iconSmall,
                                                color: _selectedGender == 'female'
                                                    ? Colors.white
                                                    : AppColors.accent,
                                              ),
                                              const SizedBox(width: AppDimensions.s8),
                                              Text(
                                                'Female',
                                                style: TextStyle(
                                                  color: _selectedGender == 'female'
                                                      ? Colors.white
                                                      : AppColors.accent,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
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
                    
                    // Save button
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.s16,
                        vertical: AppDimensions.s8,
                      ),
                      child: Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(top: AppDimensions.s8),
                        child: ElevatedButton(
                          onPressed: _isLoggingOut ? null : _saveUserProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              vertical: AppDimensions.s16,
                              horizontal: AppDimensions.s24,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                            ),
                            elevation: 2,
                          ),
                          child: _isLoggingOut 
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Save Changes',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                        ),
                      ),
                    ),
                  ],
                ),
                
               
                
                const SizedBox(height: AppDimensions.s24),
                
                // Language setting
                _buildSettingSection(
                  context: context,
                  title: 'Language',
                  children: [
                    _buildLanguageSelector(context),
                  ],
                ),
                
                const SizedBox(height: AppDimensions.s24),
                
                // Preferences
                _buildSettingSection(
                  context: context,
                  title: 'Preferences',
                  children: [
                    _buildSwitchSetting(
                      context: context,
                      title: 'Halal Filter',
                      subtitle: 'Only show halal food options',
                      icon: AppAssets.iconHalal,
                      color: AppColors.success,
                      value: true,
                      onChanged: (value) {
                        // This would save the preference
                      },
                    ),
                    _buildSwitchSetting(
                      context: context,
                      title: 'Notifications',
                      subtitle: 'Get reminders for your goals',
                      icon: FontAwesomeIcons.bell,
                      color: AppColors.accent,
                      value: true,
                      onChanged: (value) {
                        // This would save the preference
                      },
                    ),
                  ],
                ),
                
                const SizedBox(height: AppDimensions.s24),
                
                // Data management
                _buildSettingSection(
                  context: context,
                  title: 'Data Management',
                  children: [
                    _buildDebugSection(),
                  ],
                ),
                
                const SizedBox(height: AppDimensions.s24),
                
                // About section
                _buildSettingSection(
                  context: context,
                  title: 'About',
                  children: [
                    _buildActionSetting(
                      context: context,
                      title: 'Version',
                      subtitle: '1.0.0',
                      icon: FontAwesomeIcons.circleInfo,
                      color: AppColors.accent,
                      onTap: () {
                        // Show app info
                      },
                    ),
                  ],
                ),
                
                const SizedBox(height: AppDimensions.s24),
                
                // Account section
                _buildSettingSection(
                  context: context,
                  title: 'Account',
                  children: [
                    // Logout button
                    _buildActionSetting(
                      context: context,
                      title: 'Logout',
                      subtitle: 'Sign out of your account',
                      icon: FontAwesomeIcons.rightFromBracket,
                      color: AppColors.error,
                      onTap: _isLoggingOut ? () {} : _showLogoutConfirmation,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingSection({
    required BuildContext context,
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: AppDimensions.s12),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildThemeToggleBar(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    // Wait for theme provider to initialize
    if (!themeProvider.isInitialized) {
      return Container(
        padding: const EdgeInsets.all(16.0),
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    
    return Container(
      margin: const EdgeInsets.all(AppDimensions.s16),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10.0),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: FaIcon(
                  AppAssets.iconTheme,
                  size: 24,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(width: 16.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'App Theme',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      themeProvider.getEffectiveThemeName(context),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              // Theme mode selection buttons
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildThemeModeButton(
                      context: context,
                      icon: Icons.brightness_auto,
                      isSelected: themeProvider.themeMode == ThemeMode.system,
                      onTap: () => themeProvider.setThemeMode(ThemeMode.system),
                      tooltip: 'System',
                    ),
                    _buildThemeModeButton(
                      context: context,
                      icon: Icons.light_mode,
                      isSelected: themeProvider.themeMode == ThemeMode.light,
                      onTap: () => themeProvider.setThemeMode(ThemeMode.light),
                      tooltip: 'Light',
                    ),
                    _buildThemeModeButton(
                      context: context,
                      icon: Icons.dark_mode,
                      isSelected: themeProvider.themeMode == ThemeMode.dark,
                      onTap: () => themeProvider.setThemeMode(ThemeMode.dark),
                      tooltip: 'Dark',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildThemeModeButton({
    required BuildContext context,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6.0),
        child: Container(
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: isSelected 
                ? AppColors.accent.withOpacity(0.2)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6.0),
          ),
          child: Icon(
            icon,
            size: 20,
            color: isSelected 
                ? AppColors.accent
                : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageSelector(BuildContext context) {
    // Mock language state
    const String currentLanguage = 'English';
    
    return InkWell(
      onTap: () {
        _showLanguageSelector(context);
      },
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.s16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppDimensions.s8),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              ),
              child: FaIcon(
                AppAssets.iconLanguage,
                size: AppDimensions.iconMedium,
                color: AppColors.accent,
              ),
            ),
            const SizedBox(width: AppDimensions.s16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Language',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppDimensions.s4),
                  Text(
                    currentLanguage,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                  ),
                ],
              ),
            ),
            FaIcon(
              FontAwesomeIcons.chevronRight,
              size: AppDimensions.iconSmall,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchSetting({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.s16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppDimensions.s8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
            ),
            child: FaIcon(
              icon,
              size: AppDimensions.iconMedium,
              color: color,
            ),
          ),
          const SizedBox(width: AppDimensions.s16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppDimensions.s4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: color,
          ),
        ],
      ),
    );
  }

  Widget _buildActionSetting({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.s16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppDimensions.s8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              ),
              child: FaIcon(
                icon,
                size: AppDimensions.iconMedium,
                color: color,
              ),
            ),
            const SizedBox(width: AppDimensions.s16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppDimensions.s4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                  ),
                ],
              ),
            ),
            FaIcon(
              FontAwesomeIcons.chevronRight,
              size: AppDimensions.iconSmall,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguageSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusLarge),
        ),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(AppDimensions.s16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Select Language',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppDimensions.s16),
              _buildLanguageOption(context, 'English', true),
              _buildLanguageOption(context, 'Danish', false),
              const SizedBox(height: AppDimensions.s16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLanguageOption(BuildContext context, String language, bool isSelected) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AppDimensions.s12,
          horizontal: AppDimensions.s16,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                language,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
              ),
            ),
            if (isSelected)
              FaIcon(
                FontAwesomeIcons.check,
                size: AppDimensions.iconSmall,
                color: AppColors.accent,
              ),
          ],
        ),
      ),
    );
  }

  void _showResetConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset App?'),
        content: const Text('This will delete all your data and reset the app to default settings. This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showResetSuccess(context);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _showResetSuccess(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Lottie reset animation or placeholder
            Lottie.asset(
              AppAssets.lottieReset,
              width: 150,
              height: 150,
              repeat: false,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 100,
                  width: 100,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    size: 60,
                    color: AppColors.success,
                  ),
                );
              },
            ),
            const SizedBox(height: AppDimensions.s16),
            Text(
              'Reset Complete',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppDimensions.s8),
            Text(
              'Your app has been reset to default settings.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildDebugSection() {
    return Column(
      children: [
        // Storage status info
        Container(
          padding: const EdgeInsets.all(AppDimensions.s16),
          margin: const EdgeInsets.all(AppDimensions.s16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
            border: Border.all(color: Colors.grey.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Storage Debug Info',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppDimensions.s8),
              Text(
                'This section helps debug storage issues',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
        
        // Debug actions
        _buildActionSetting(
          context: context,
          title: 'Show Storage Status',
          subtitle: 'View current storage method and authentication',
          icon: FontAwesomeIcons.info,
          color: Colors.blue,
          onTap: () {
            _mealService.debugStorageInfo();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Check console/logs for debug information'),
                backgroundColor: Colors.blue,
              ),
            );
          },
        ),
        
        const Divider(),
        
        _buildActionSetting(
          context: context,
          title: 'Force Enable Firebase',
          subtitle: 'Switch to Firebase storage (for debugging)',
          icon: FontAwesomeIcons.cloud,
          color: Colors.orange,
          onTap: () {
            _showForceFirebaseDialog();
          },
        ),
        
        const Divider(),
        
        _buildActionSetting(
          context: context,
          title: 'Reset App Data',
          subtitle: 'Delete all data and reset settings',
          icon: FontAwesomeIcons.rotate,
          color: AppColors.error,
          onTap: () {
            _showResetConfirmation(context);
          },
        ),
      ],
    );
  }
  
  void _showForceFirebaseDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Force Enable Firebase'),
        content: const Text(
          'This will force the app to use Firebase storage. This is for debugging purposes only. '
          'Are you sure you want to continue?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              
              try {
                // Show loading
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Row(
                      children: [
                        SizedBox(
                          width: 20, 
                          height: 20, 
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
                        ),
                        SizedBox(width: 16),
                        Text('Enabling Firebase...'),
                      ],
                    ),
                    duration: Duration(seconds: 3),
                  ),
                );
                
                await _mealService.forceEnableFirestore();
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Firebase enabled! Restart the app to see changes.'),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 5),
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error enabling Firebase: $e'),
                    backgroundColor: Colors.red,
                    duration: const Duration(seconds: 5),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Enable Firebase'),
          ),
        ],
      ),
    );
  }
} 