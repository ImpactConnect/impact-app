import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;
import '../providers/theme_provider.dart';
import '../services/storage_manager.dart';
import '../widgets/bottom_nav_bar.dart';
import 'help_support_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _appSize = '...';
  String _cacheSize = '...';
  bool _isLoading = true;
  final String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _loadInfo();
  }

  Future<void> _loadInfo() async {
    final storageInfo = await StorageManager.getStorageInfo();
    if (mounted) {
      setState(() {
        _appSize = StorageManager.formatSize(storageInfo['appSize']!);
        _cacheSize = StorageManager.formatSize(storageInfo['cacheSize']!);
        _isLoading = false;
      });
    }
  }

  Future<void> _showClearCacheDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text(
          'This will clear all cached data. Downloaded content will not be affected. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('CLEAR'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await StorageManager.clearCache();
      await _loadInfo();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cache cleared successfully')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return WillPopScope(
      onWillPop: () async {
        Navigator.pushReplacementNamed(context, '/home');
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Settings'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                children: [
                  // Appearance Section
                  _buildSectionHeader('APPEARANCE'),
                  ListTile(
                    leading: const Icon(Icons.dark_mode),
                    title: const Text('Dark Mode'),
                    subtitle: const Text('Toggle dark theme'),
                    trailing: Switch(
                      value: themeProvider.themeMode == ThemeMode.dark,
                      onChanged: (value) => themeProvider.toggleTheme(),
                    ),
                  ),
                  _buildDivider(),

                  // Storage Section
                  _buildSectionHeader('STORAGE'),
                  ListTile(
                    leading: const Icon(Icons.storage),
                    title: const Text('App Storage'),
                    subtitle: Text('App Size: $_appSize'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.cached),
                    title: const Text('Cache'),
                    subtitle: Text('Cache Size: $_cacheSize'),
                    trailing: TextButton(
                      onPressed: _showClearCacheDialog,
                      child: const Text('CLEAR'),
                    ),
                  ),
                  _buildDivider(),

                  // Help & Support
                  _buildSectionHeader('HELP & SUPPORT'),
                  ListTile(
                    leading: const Icon(Icons.help_outline),
                    title: const Text('Help Center'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const HelpSupportScreen(),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.mail_outline),
                    title: const Text('Contact Support'),
                    onTap: () => _launchURL('mailto:support@yourchurch.com'),
                  ),
                  _buildDivider(),

                  // About Section
                  _buildSectionHeader('ABOUT'),
                  ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: const Text('About'),
                    subtitle: Text('Version $_appVersion'),
                    onTap: _showAboutDialog,
                  ),
                  ListTile(
                    leading: const Icon(Icons.policy_outlined),
                    title: const Text('Privacy Policy'),
                    onTap: () => _launchURL('https://yourchurch.com/privacy'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.description_outlined),
                    title: const Text('Terms of Service'),
                    onTap: () => _launchURL('https://yourchurch.com/terms'),
                  ),
                ],
              ),
        bottomNavigationBar: const BottomNavBar(currentIndex: 3),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1, indent: 16, endIndent: 16);
  }

  Future<void> _launchURL(String urlString) async {
    final url = Uri.parse(urlString);
    if (await url_launcher.canLaunchUrl(url)) {
      await url_launcher.launchUrl(url);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch URL')),
        );
      }
    }
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AboutDialog(
        applicationName: 'Church Mobile',
        applicationVersion: 'Version $_appVersion',
        applicationIcon: const Icon(Icons.church, size: 50),
        children: const [
          Text(
            'Church Mobile is your comprehensive church companion app, '
            'designed to enhance your spiritual journey with features like '
            'Bible study, sermons, events, and more.',
          ),
        ],
      ),
    );
  }
}
