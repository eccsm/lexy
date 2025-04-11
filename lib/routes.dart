import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'features/auth/login_screen.dart';
import 'features/categories/categories_screen.dart';
import 'features/categories/category_detail_screen.dart';
import 'features/notes/note_detail_screen.dart';
import 'features/notes/note_edit_screen.dart';
import 'features/notes/notes_list_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/recording/recording_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/subscription/subscription_screen.dart';
import 'features/auth/services/user_profile_service.dart';

GoRouter createRouter(Ref ref) {
  // Check if the user is logged in
  final currentUserProfile = ref.watch(currentUserProfileProvider);
  
  // Redirect to login if not logged in (except for login page)
  String? redirectIfNotLoggedIn(BuildContext context, GoRouterState state) {
    if (currentUserProfile.isLoading) return null; // Still loading, don't redirect
    
    final isLoggedIn = currentUserProfile.value != null;
    final isLoggingIn = state.uri.path == '/login';
    
    // If not logged in and not on login page, redirect to login
    if (!isLoggedIn && !isLoggingIn) {
      return '/login';
    }
    
    // If logged in and on login page, redirect to notes
    if (isLoggedIn && isLoggingIn) {
      return '/notes';
    }
    
    return null; // No redirection needed
  }
  
  return GoRouter(
    initialLocation: '/notes',
    redirect: redirectIfNotLoggedIn,
    routes: [
      // Notes list (main screen)
      GoRoute(
        path: '/notes',
        builder: (context, state) => const NotesListScreen(),
      ),
      
      // Note details
      GoRoute(
        path: '/notes/:id',
        builder: (context, state) {
          final noteId = state.pathParameters['id'] ?? '';
          return NoteDetailScreen(noteIdStr: noteId);
        },
      ),
      
      // Edit note
      GoRoute(
        path: '/notes/:id/edit',
        builder: (context, state) {
          final noteId = state.pathParameters['id'] ?? '';
          return NoteEditScreen(noteId: noteId);
        },
      ),
      
      // Recording screen
      GoRoute(
        path: '/record',
        builder: (context, state) => const RecordingScreen(),
      ),
      
      // Profile screen
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      
      // Categories screen
      GoRoute(
        path: '/categories',
        builder: (context, state) => const CategoriesScreen(),
      ),
      
      // Category details
      GoRoute(
        path: '/categories/:id',
        builder: (context, state) {
          final categoryId = int.parse(state.pathParameters['id'] ?? '0');
          return CategoryDetailScreen(categoryId: categoryId);
        },
      ),
      
      // Settings screen
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      
      // Subscription screen
      GoRoute(
        path: '/subscription',
        builder: (context, state) => const SubscriptionScreen(),
      ),
      
      // Login screen
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
    ],
    
    // Error page
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.uri.toString()}'),
      ),
    ),
  );
}