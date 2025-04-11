// lib/features/subscription/subscription_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../auth/auth_controller.dart';
import '../auth/services/user_profile_service.dart';
import 'subscription_service.dart';

// Provider for the SubscriptionService
final subscriptionServiceProvider = Provider<SubscriptionService>((ref) {
  final userProfileService = ref.watch(userProfileServiceProvider);
  final authController = ref.watch(authControllerProvider.notifier);
  
  final service = SubscriptionService(
    inAppPurchase: InAppPurchase.instance,
    userProfileService: userProfileService,
    authController: authController,
  );
  
  // Handle disposal
  ref.onDispose(() {
    service.dispose();
  });
  
  return service;
});

// Provider for available products
final productsProvider = FutureProvider<List<ProductDetails>>((ref) async {
  final subscriptionService = ref.watch(subscriptionServiceProvider);
  return subscriptionService.loadProducts();
});

// Provider to check if a user is premium
final isPremiumProvider = Provider<bool>((ref) {
  final userProfile = ref.watch(currentUserProfileProvider).value;
  return userProfile?.isPremium ?? false;
});

// Provider to check if subscription is active
final isSubscriptionActiveProvider = Provider<bool>((ref) {
  final userProfile = ref.watch(currentUserProfileProvider).value;
  return userProfile?.isSubscriptionActive ?? false;
});

// Provider to get current subscription details
final subscriptionDetailsProvider = Provider((ref) {
  final userProfile = ref.watch(currentUserProfileProvider).value;
  
  if (userProfile == null || !userProfile.isPremium) {
    return {
      'tier': 'Free',
      'status': 'N/A',
      'period': 'N/A',
      'expiryDate': 'N/A',
    };
  }
  
  return {
    'tier': 'Premium',
    'status': userProfile.subscriptionStatus,
    'period': userProfile.subscriptionPeriod.toString().split('.').last,
    'expiryDate': userProfile.formattedExpiryDate,
  };
});