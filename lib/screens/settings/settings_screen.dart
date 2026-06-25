import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/notification_service.dart';

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

    final notifService = NotificationService();
    if (value) {
      // Re-schedule daily check-in reminder at 9:00 AM
      await notifService.scheduleDailyReminder(
        id: 999,
        hour: 9,
        minute: 0,
        title: 'TaskFlow Check-in',
        body: 'Start your day by reviewing your scheduled tasks!',
      );
    } else {
      // Cancel the daily reminder (its ID is 999)
      final localPlugin = notifService;
      await localPlugin.cancelTaskReminder('999'); // Cancel using hash matching ID 999
    }
  }

  Future<void> _toggleTaskReminders(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('task_reminder_enabled', value);
    setState(() {
      _taskReminderEnabled = value;
    });
  }

  void _logout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    // Provider will automatically clear task streams upon logging out
    await authProvider.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final userEmail = authProvider.user?.email ?? "test@test.com";

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
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: AppTheme.primarySeedColor,
                      child: Text(
                        userEmail.substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
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
                            'Offline Local Storage Mode',
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
              subtitle: const Text('Receive a task check-in alert every morning'),
              value: _dailyReminderEnabled,
              onChanged: _toggleDailyReminder,
            ),
            SwitchListTile(
              secondary: const Icon(Icons.notifications_active_rounded, color: AppTheme.primarySeedColor),
              title: const Text('Task Due Reminders', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Trigger alarms at task scheduled due dates'),
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
                'TaskFlow v1.0.0 (Clean Architecture)',
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
