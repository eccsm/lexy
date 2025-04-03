import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers.dart';
import '../../shared/widgets/app_bar.dart';
import '../../shared/widgets/custom_button.dart';
import '../auth/auth_controller.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(authControllerProvider);
    final themeMode = ref.watch(themeModeProvider);
    
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Profile',
        showBackButton: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: userAsync.when(
            data: (user) {
              if (user == null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('You are not signed in'),
                      const SizedBox(height: 16),
                      CustomButton(
                        onPressed: () => context.go('/login'),
                        text: 'Sign In',
                      ),
                    ],
                  ),
                );
              }
              
              return Column(
                children: [
                  // User avatar
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Theme.of(context).primaryColor.withValues(
                      red: Theme.of(context).primaryColor.r,
                      green: Theme.of(context).primaryColor.g,
                      blue: Theme.of(context).primaryColor.b,
                      alpha: 0.2,
                    ),
                    child: user.photoURL != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(50),
                            child: Image.network(
                              user.photoURL!,
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Icon(
                            Icons.person,
                            size: 50,
                            color: Theme.of(context).primaryColor,
                          ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Display name
                  Text(
                    user.displayName ?? 'VoiceNotes User',
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Email
                  Text(
                    user.email ?? '',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  
                  const SizedBox(height: 48),
                  
                  // Theme switcher
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.palette),
                      title: const Text('Theme'),
                      trailing: DropdownButton<ThemeMode>(
                        value: themeMode,
                        underline: const SizedBox(),
                        items: const [
                          DropdownMenuItem(
                            value: ThemeMode.system,
                            child: Text('System'),
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
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Categories Button
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.category),
                      title: const Text('Manage Categories'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/categories'),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Settings Button
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.settings),
                      title: const Text('Settings'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/settings'),
                    ),
                  ),
                  
                  const Spacer(),
                  
                  // Logout button
                  CustomButton(
                    onPressed: () async {
                      await ref.read(authControllerProvider.notifier).signOut();
                      if (context.mounted) {
                        context.go('/login');
                      }
                    },
                    text: 'Log Out',
                    icon: Icons.exit_to_app,
                    color: Colors.red,
                  ),
                  
                  const SizedBox(height: 16),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(
              child: Text('Error: ${error.toString()}'),
            ),
          ),
        ),
      ),
    );
  }
}