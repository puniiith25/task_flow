import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme.dart';
import '../../core/router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/notification_provider.dart';
import '../../services/notification_service.dart';
import '../../widgets/avatar_widget.dart';
import '../auth/avatar_selection_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _dailyReminderEnabled = true;
  bool _taskReminderEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadNotificationSettings();
  }

  Future<void> _loadNotificationSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _dailyReminderEnabled = prefs.getBool('daily_reminder_enabled') ?? true;
      _taskReminderEnabled = prefs.getBool('task_reminder_enabled') ?? true;
    });
  }

  Future<void> _toggleDailyReminder(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('daily_reminder_enabled', value);
    setState(() {
      _dailyReminderEnabled = value;
    });

    if (value) {
      await NotificationService().scheduleDailyCheckIn();
    } else {
      await NotificationService().cancelDailyCheckIn();
    }
  }

  Future<void> _toggleTaskReminders(bool value) async {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('task_reminder_enabled', value);
    setState(() {
      _taskReminderEnabled = value;
    });

    // If task reminders are disabled, cancel all scheduled task due notifications
    if (!value) {
      for (var task in taskProvider.tasks) {
        await NotificationService().cancelTaskNotification(task.id);
      }
    } else {
      // Re-schedule future pending tasks
      for (var task in taskProvider.tasks) {
        if (!task.completed && task.dueDate.isAfter(DateTime.now())) {
          await NotificationService().scheduleTaskNotification(task);
        }
      }
    }
  }

  void _logout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    final notifProvider = Provider.of<NotificationProvider>(context, listen: false);
    
    // Clear in-memory caches
    taskProvider.clear();
    notifProvider.clear();
    
    // Sign out from Auth provider (triggers real Firebase signout)
    await authProvider.signOut();
    
    // Redirect cleanly to login screen and clear navigation history
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, AppRouter.login, (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final userEmail = authProvider.userEmail ?? "user@taskflow.com";

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          children: [
            Text(
              'Settings',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 24),

            // Profile summary card
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Stack(
                      children: [
                        AvatarWidget(
                          avatarString: authProvider.profileImageUrl,
                          radius: 30,
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const AvatarSelectionScreen(isEditMode: true),
                                ),
                              );
                            },
                            child: CircleAvatar(
                              radius: 10,
                              backgroundColor: AppTheme.primarySeedColor,
                              child: const Icon(
                                Icons.edit_rounded,
                                size: 10,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userEmail,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Firebase Cloud Sync Active',
                            style: TextStyle(
                              color: AppTheme.secondaryColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Theme Preferences section
            _buildSectionHeader('Appearance'),
            SwitchListTile(
              secondary: Icon(
                themeProvider.isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                color: AppTheme.primarySeedColor,
              ),
              title: const Text('Dark Mode', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Toggle between dark and light themes'),
              value: themeProvider.isDarkMode,
              onChanged: (val) => themeProvider.toggleTheme(val),
            ),
            const Divider(),

            // Notification preferences
            _buildSectionHeader('Notifications'),
            SwitchListTile(
              secondary: const Icon(Icons.alarm_rounded, color: AppTheme.primarySeedColor),
              title: const Text('Daily Summary Reminder', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Receive a task check-in alert every morning at 9:00 AM'),
              value: _dailyReminderEnabled,
              onChanged: _toggleDailyReminder,
            ),
            SwitchListTile(
              secondary: const Icon(Icons.notifications_active_rounded, color: AppTheme.primarySeedColor),
              title: const Text('Task Due Reminders', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Trigger local alerts at task scheduled due dates'),
              value: _taskReminderEnabled,
              onChanged: _toggleTaskReminders,
            ),
            const Divider(),

            // Account settings section
            _buildSectionHeader('Account Actions'),
            ListTile(
              leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
              title: const Text(
                'Log Out',
                style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
              ),
              subtitle: const Text('Disconnect this device session'),
              onTap: _logout,
            ),
            const SizedBox(height: 48),
            
            // Footer credits
            Center(
              child: Text(
                'TaskFlow v1.0.0 (Firebase Sync Mode)',
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppTheme.primarySeedColor,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}
