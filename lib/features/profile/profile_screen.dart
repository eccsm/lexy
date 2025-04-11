import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:voicenotes/database/models/user_profile.dart';

import '../../providers.dart';
import '../../shared/widgets/app_bar.dart';
import '../../shared/widgets/custom_button.dart';
import '../auth/auth_controller.dart';
import '../auth/services/user_profile_service.dart';
import '../subscription/subscription_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(authControllerProvider);
    final userProfileAsync = ref.watch(currentUserProfileProvider);
    final themeMode = ref.watch(themeModeProvider);
    final isPremium = ref.watch(isPremiumProvider);
    
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
              
              return userProfileAsync.when(
                data: (userProfile) {
                  return _buildProfileContent(
                    context, 
                    ref, 
                    user,
                    userProfile, 
                    themeMode,
                    isPremium,
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(
                  child: Text('Error loading profile: $error'),
                ),
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
  
  Widget _buildProfileContent(
    BuildContext context, 
    WidgetRef ref, 
    dynamic user,
    UserProfile? userProfile,
    ThemeMode themeMode,
    bool isPremium,
  ) {
    final authProvider = userProfile?.authProvider ?? AuthProvider.email;
    final authProviderName = _getAuthProviderDisplayName(authProvider);
    
    return Column(
      children: [
        // User avatar and info
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Column(
            children: [
              // User avatar with premium badge if applicable
              Stack(
                children: [
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
                  
                  // Premium badge
                  if (isPremium)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.amber,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.star,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Display name
              Text(
                userProfile?.displayName ?? 'VoiceNotes User',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 8),
              
              // Email
              Text(
                userProfile?.email ?? '',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              
              const SizedBox(height: 8),
              
              // Signed in with
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Signed in with ',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  _getAuthProviderIcon(authProvider),
                  const SizedBox(width: 4),
                  Text(
                    authProviderName,
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        const Divider(),
        
        // Subscription section
        _buildSubscriptionSection(context, isPremium, userProfile),
        
        const SizedBox(height: 24),
        
        // Settings section
        _buildSettingsSection(context, ref, themeMode),
        
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
  }
  
  Widget _buildSubscriptionSection(
    BuildContext context, 
    bool isPremium,
    UserProfile? userProfile,
  ) {
    final subscriptionDetails = userProfile != null 
        ? {
            'tier': userProfile.subscriptionTier == SubscriptionTier.premium ? 'Premium' : 'Free',
            'period': userProfile.subscriptionPeriod == SubscriptionPeriod.monthly
                ? 'Monthly'
                : userProfile.subscriptionPeriod == SubscriptionPeriod.yearly
                    ? 'Yearly'
                    : 'None',
            'status': userProfile.isSubscriptionActive ? 'Active' : 'Inactive',
            'expiryDate': userProfile.formattedExpiryDate,
          }
        : {
            'tier': 'Free',
            'period': 'None',
            'status': 'N/A',
            'expiryDate': 'N/A',
          };
    
    return Column(
      children: [
        ListTile(
          leading: Icon(
            isPremium ? Icons.star : Icons.star_border,
            color: isPremium ? Colors.amber : null,
          ),
          title: Text(isPremium ? 'Premium Subscription' : 'Free Account'),
          subtitle: Text(
            isPremium 
                ? '${subscriptionDetails['period']} plan - Expires: ${subscriptionDetails['expiryDate']}'
                : 'Upgrade to access premium features',
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push('/subscription'),
        ),
        
        if (!isPremium)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: CustomButton(
              onPressed: () => context.push('/subscription'),
              text: 'Upgrade to Premium',
              icon: Icons.star,
              color: Colors.indigo,
            ),
          ),
      ],
    );
  }
  
  Widget _buildSettingsSection(
    BuildContext context, 
    WidgetRef ref,
    ThemeMode themeMode,
  ) {
    return Column(
      children: [
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
      ],
    );
  }
  
  Widget _getAuthProviderIcon(AuthProvider provider) {
    switch (provider) {
      case AuthProvider.google:
        return Image.asset(
          'assets/images/google_logo.png',
          height: 16,
          width: 16,
        );
      case AuthProvider.apple:
        return const Icon(Icons.apple, size: 16);
      case AuthProvider.meta:
        return Image.asset(
          'assets/images/meta_logo.png',
          height: 16,
          width: 16,
        );
      case AuthProvider.email:
      return const Icon(Icons.email, size: 16);
    }
  }
  
  String _getAuthProviderDisplayName(AuthProvider provider) {
    switch (provider) {
      case AuthProvider.google:
        return 'Google';
      case AuthProvider.apple:
        return 'Apple';
      case AuthProvider.meta:
        return 'Meta';
      case AuthProvider.email:
      return 'Email';
    }
  }
}