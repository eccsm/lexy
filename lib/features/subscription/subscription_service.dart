// lib/features/subscription/subscription_service.dart
import 'dart:async';
import 'dart:io';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:logger/logger.dart';
import 'package:voicenotes/database/models/user_profile.dart';

import '../auth/auth_controller.dart';
import '../auth/services/user_profile_service.dart';

// Define product IDs for different subscription plans
class SubscriptionProductIds {
  static const String monthlyPremium = 'voice_notes_premium_monthly';
  static const String yearlyPremium = 'voice_notes_premium_yearly';
  
  static List<String> get all => [monthlyPremium, yearlyPremium];
}

class SubscriptionService {
  final InAppPurchase _inAppPurchase;
  final UserProfileService _userProfileService;
  final AuthController _authController;
  final Logger _logger = Logger();
  
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  List<ProductDetails> _products = [];
  bool _isAvailable = false;
  
  SubscriptionService({
    required InAppPurchase inAppPurchase,
    required UserProfileService userProfileService,
    required AuthController authController,
  })  : _inAppPurchase = inAppPurchase,
        _userProfileService = userProfileService,
        _authController = authController {
    _initializeStore();
  }
  
  bool get isStoreAvailable => _isAvailable;
  List<ProductDetails> get products => _products;
  
  Future<void> _initializeStore() async {
    try {
      _isAvailable = await _inAppPurchase.isAvailable();
      if (!_isAvailable) {
        _logger.w('Store is not available');
        return;
      }
      
      // Load product details
      await loadProducts();
      
      // Listen for purchase updates
      _setupPurchaseSubscription();
      
      _logger.i('Store initialized successfully');
    } catch (e) {
      _logger.e('Error initializing store: $e');
      _isAvailable = false;
    }
  }
  
  Future<List<ProductDetails>> loadProducts() async {
    try {
      final ProductDetailsResponse response = 
          await _inAppPurchase.queryProductDetails(SubscriptionProductIds.all.toSet());
      
      if (response.notFoundIDs.isNotEmpty) {
        _logger.w('Some products were not found: ${response.notFoundIDs}');
      }
      
      _products = response.productDetails;
      _logger.i('Products loaded: ${_products.length}');
      
      return _products;
    } catch (e) {
      _logger.e('Error loading products: $e');
      return [];
    }
  }
  
  void _setupPurchaseSubscription() {
    _subscription = _inAppPurchase.purchaseStream.listen(
      (List<PurchaseDetails> purchaseDetails) {
        _handlePurchaseUpdates(purchaseDetails);
      },
      onDone: () {
        _subscription?.cancel();
      },
      onError: (error) {
        _logger.e('Error in purchase stream: $error');
      },
    );
  }
  
  Future<void> _handlePurchaseUpdates(List<PurchaseDetails> purchaseDetails) async {
    for (final purchase in purchaseDetails) {
      if (purchase.status == PurchaseStatus.pending) {
        _logger.i('Purchase pending: ${purchase.productID}');
      } else if (purchase.status == PurchaseStatus.error) {
        _logger.e('Purchase error: ${purchase.error}');
        _handlePurchaseError(purchase);
      } else if (purchase.status == PurchaseStatus.purchased ||
                 purchase.status == PurchaseStatus.restored) {
        _logger.i('Purchase completed: ${purchase.productID}');
        await _handleSuccessfulPurchase(purchase);
      }
      
      // Complete the purchase regardless of status to avoid duplicate transactions
      if (purchase.pendingCompletePurchase) {
        await _inAppPurchase.completePurchase(purchase);
      }
    }
  }
  
  void _handlePurchaseError(PurchaseDetails purchase) {
    // Handle purchase errors
    // You could implement retry logic or error reporting here
  }
  
  Future<void> _handleSuccessfulPurchase(PurchaseDetails purchase) async {
    final user = _authController.currentUser;
    if (user == null) {
      _logger.e('No authenticated user for purchase');
      return;
    }
    
    try {
      // Update user's subscription status based on the purchased product
      final DateTime now = DateTime.now();
      DateTime? expiryDate;
      SubscriptionPeriod period;
      
      if (purchase.productID == SubscriptionProductIds.monthlyPremium) {
        expiryDate = DateTime(now.year, now.month + 1, now.day);
        period = SubscriptionPeriod.monthly;
      } else if (purchase.productID == SubscriptionProductIds.yearlyPremium) {
        expiryDate = DateTime(now.year + 1, now.month, now.day);
        period = SubscriptionPeriod.yearly;
      } else {
        _logger.w('Unknown product ID: ${purchase.productID}');
        return;
      }
      
      // Update user's subscription in Firestore
      await _userProfileService.updateSubscription(
        uid: user.uid,
        tier: SubscriptionTier.premium,
        period: period,
        expiryDate: expiryDate,
      );
      
      _logger.i('Subscription updated for user ${user.uid}');
    } catch (e) {
      _logger.e('Error updating subscription status: $e');
    }
  }
  
  // Start a purchase flow for a specific product
  Future<bool> purchaseSubscription(ProductDetails product) async {
    if (!_isAvailable) {
      _logger.w('Store is not available');
      return false;
    }
    
    final user = _authController.currentUser;
    if (user == null) {
      _logger.e('No authenticated user for purchase');
      return false;
    }
    
    try {
      final PurchaseParam purchaseParam = PurchaseParam(
        productDetails: product,
        applicationUserName: user.uid,
      );
      
      // Start the purchase flow
      if (Platform.isIOS) {
        return await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
      } else {
        return await _inAppPurchase.buyConsumable(purchaseParam: purchaseParam);
      }
    } catch (e) {
      _logger.e('Error starting purchase: $e');
      return false;
    }
  }
  
  // Restore previous purchases
  Future<bool> restorePurchases() async {
    if (!_isAvailable) {
      _logger.w('Store is not available');
      return false;
    }
    
    try {
      await _inAppPurchase.restorePurchases();
      return true;
    } catch (e) {
      _logger.e('Error restoring purchases: $e');
      return false;
    }
  }
  
  // Cancel subscription
  Future<bool> cancelSubscription() async {
    // Note: In most cases, cancellation is handled via the app store
    // This method is just for updating the local state
    
    final user = _authController.currentUser;
    if (user == null) {
      _logger.e('No authenticated user for cancellation');
      return false;
    }
    
    try {
      await _userProfileService.updateSubscription(
        uid: user.uid,
        tier: SubscriptionTier.free,
        period: SubscriptionPeriod.none,
        expiryDate: null,
      );
      
      _logger.i('Subscription cancelled for user ${user.uid}');
      return true;
    } catch (e) {
      _logger.e('Error cancelling subscription: $e');
      return false;
    }
  }
  
  void dispose() {
    _subscription?.cancel();
  }
}