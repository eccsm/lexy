import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/auth/auth_controller.dart';


// Theme mode provider
final themeModeProvider = StateProvider<ThemeMode>((ref) {
  return ThemeMode.system; // Default to system theme
});

// Authentication state provider
final authStateProvider = StreamProvider<User?>((ref) {
  final authController = ref.watch(authControllerProvider);
  return authController.authStateChanges;
});

// User provider
final userProvider = FutureProvider<User?>((ref) async {
  final authController = ref.watch(authControllerProvider);
  return authController.currentUser;
});

// Sync status provider
final syncStatusProvider = StateProvider<bool>((ref) {
  return false; // Not syncing by default
});

// Selected category filter provider
final selectedCategoryFilterProvider = StateProvider<int?>((ref) {
  return null; // No category filter by default
});

// Sort option provider
final sortOptionProvider = StateProvider<NoteSortOption>((ref) {
  return NoteSortOption.newest; // Default sort by newest
});

// Enum for sort options
enum NoteSortOption {
  newest,
  oldest,
  alphabetical,
  recentlyUpdated,
}