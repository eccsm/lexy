import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../providers.dart';
import '../../shared/widgets/app_bar.dart';
import '../../shared/widgets/custom_button.dart';
import '../notes/notes_controller.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isSyncing = false;
  PackageInfo? _packageInfo;

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _packageInfo = info;
      });
    }
  }

  Future<void> _syncNotes() async {
    setState(() {
      _isSyncing = true;
    });
    
    try {
      await ref.read(notesControllerProvider).syncNotes();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notes synced successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to sync notes: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSyncing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final sortOption = ref.watch(sortOptionProvider);
    
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Settings',
        showBackButton: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Theme settings
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Appearance',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<ThemeMode>(
                    decoration: const InputDecoration(
                      labelText: 'Theme',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.palette),
                    ),
                    value: themeMode,
                    items: const [
                      DropdownMenuItem(
                        value: ThemeMode.system,
                        child: Text('System Default'),
                      ),
                      DropdownMenuItem(
                        value: ThemeMode.light,
                        child: Text('Light'),
                      ),
                      DropdownMenuItem(
                        value: ThemeMode.dark,
                        child: Text('Dark'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        ref.read(themeModeProvider.notifier).state = value;
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Notes settings
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Notes',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<NoteSortOption>(
                    decoration: const InputDecoration(
                      labelText: 'Default Sort Order',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.sort),
                    ),
                    value: sortOption,
                    items: const [
                      DropdownMenuItem(
                        value: NoteSortOption.newest,
                        child: Text('Newest First'),
                      ),
                      DropdownMenuItem(
                        value: NoteSortOption.oldest,
                        child: Text('Oldest First'),
                      ),
                      DropdownMenuItem(
                        value: NoteSortOption.alphabetical,
                        child: Text('Alphabetical'),
                      ),
                      DropdownMenuItem(
                        value: NoteSortOption.recentlyUpdated,
                        child: Text('Recently Updated'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        ref.read(sortOptionProvider.notifier).state = value;
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Sync settings
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sync',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Sync your notes with the cloud to access them on multiple devices.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  CustomButton(
                    onPressed: _isSyncing ? null : _syncNotes,
                    text: _isSyncing ? 'Syncing...' : 'Sync Now',
                    isLoading: _isSyncing,
                    icon: Icons.sync,
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // App info
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'About',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    title: const Text('Version'),
                    subtitle: Text(_packageInfo?.version ?? 'Loading...'),
                    leading: const Icon(Icons.info_outline),
                  ),
                  const Divider(),
                  ListTile(
                    title: const Text('Privacy Policy'),
                    leading: const Icon(Icons.privacy_tip_outlined),
                    onTap: () => _launchUrl('https://your-website.com/privacy'),
                  ),
                  const Divider(),
                  ListTile(
                    title: const Text('Terms of Service'),
                    leading: const Icon(Icons.description_outlined),
                    onTap: () => _launchUrl('https://your-website.com/terms'),
                  ),
                  const Divider(),
                  ListTile(
                    title: const Text('Contact Support'),
                    leading: const Icon(Icons.support_agent),
                    onTap: () => _launchUrl('mailto:support@your-app.com'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not launch $urlString'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}