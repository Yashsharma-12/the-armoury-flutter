import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme_notifier.dart'; // ✅ Ensure this path points to your theme_notifier.dart

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final Color arsenalRed = const Color(0xFFEF0107);

  // State variables
  bool _notificationsEnabled = true;
  bool _matchStartAlert = true;
  bool _goalAlerts = false;
  bool _isSpoilerModeOn = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  // Load saved preferences from disk
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications') ?? true;
      _matchStartAlert = prefs.getBool('kickoff') ?? true;
      _goalAlerts = prefs.getBool('goals') ?? false;
      _isSpoilerModeOn = prefs.getBool('spoilers') ?? false;
    });
  }

  // Save and Sync with Firebase Topics
  Future<void> _updateSubscription(String topic, bool value, String prefKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(prefKey, value);

    if (value && _notificationsEnabled) {
      await FirebaseMessaging.instance.subscribeToTopic(topic);
    } else {
      await FirebaseMessaging.instance.unsubscribeFromTopic(topic);
    }
  }

  // ✅ Updated Toggle Theme to use ThemeService
  void _handleThemeChange(bool isDark) {
    ThemeService.toggleTheme(isDark ? ThemeMode.dark : ThemeMode.light);
    // Note: themeNotifier.value change will automatically trigger a rebuild 
    // because main.dart is listening to it.
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Listen to the global themeNotifier
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentMode, _) {
        bool isDarkMode = currentMode == ThemeMode.dark;

        return Scaffold(
          // ✅ Use dynamic background color based on theme
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: arsenalRed,
            foregroundColor: Colors.white,
            title: const Text(
              "Settings",
              style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'ClearfaceGothic'),
            ),
            elevation: 0,
          ),
          body: ListView(
            children: [
              _buildSectionHeader("Appearance"),
              SwitchListTile(
                activeThumbColor: arsenalRed,
                title: Text(
                  "Dark Mode",
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                subtitle: Text(
                  isDarkMode ? "Dark Theme Active" : "Light Theme Active",
                  style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
                ),
                value: isDarkMode,
                onChanged: (val) => _handleThemeChange(val),
                secondary: Icon(isDarkMode ? Icons.dark_mode : Icons.light_mode, color: arsenalRed),
              ),
              const Divider(),

              _buildSectionHeader("Notifications"),
              _buildSwitchTile(
                "Push Notifications",
                "Enable all app notifications",
                _notificationsEnabled,
                (val) async {
                  setState(() => _notificationsEnabled = val);
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('notifications', val);
                  if (!val) {
                    await FirebaseMessaging.instance.unsubscribeFromTopic('kickoff_alerts');
                    await FirebaseMessaging.instance.unsubscribeFromTopic('goal_alerts');
                  } else {
                    if (_matchStartAlert) await FirebaseMessaging.instance.subscribeToTopic('kickoff_alerts');
                    if (_goalAlerts) await FirebaseMessaging.instance.subscribeToTopic('goal_alerts');
                  }
                },
              ),
              if (_notificationsEnabled) ...[
                _buildSwitchTile(
                  "Kick-off Alerts",
                  "Notify match start updates",
                  _matchStartAlert,
                  (val) {
                    setState(() => _matchStartAlert = val);
                    _updateSubscription('kickoff_alerts', val, 'kickoff');
                  },
                ),
                _buildSwitchTile(
                  "Goal Alerts",
                  "Live score updates",
                  _goalAlerts,
                  (val) {
                    setState(() => _goalAlerts = val);
                    _updateSubscription('goal_alerts', val, 'goals');
                  },
                ),
              ],
              const Divider(),

              _buildSectionHeader("Fan Experience"),
              _buildSwitchTile(
                "Spoiler Mode",
                "Blur scores on home screen",
                _isSpoilerModeOn,
                (val) async {
                  setState(() => _isSpoilerModeOn = val);
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('spoilers', val);
                },
              ),
              const Divider(),

              _buildSectionHeader("About"),
              ListTile(
                title: Text(
                  "App Version",
                  style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                ),
                subtitle: const Text("1.0.0 (Gooner Edition)"),
                trailing: const Icon(Icons.info_outline),
              ),
              ListTile(
                title: Text(
                  "Clear Cache",
                  style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                ),
                subtitle: const Text("Free up space used by images"),
                trailing: const Icon(Icons.delete_outline),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Cache Cleared!"), backgroundColor: Colors.black87),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: arsenalRed,
          fontSize: 14,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, bool value, Function(bool) onChanged) {
    return SwitchListTile(
      activeThumbColor: arsenalRed,
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: Theme.of(context).textTheme.bodyLarge?.color,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 13, color: Theme.of(context).textTheme.bodySmall?.color),
      ),
      value: value,
      onChanged: onChanged,
    );
  }
}