// lib/features/auth/models/user_profile.dart
import 'package:firebase_auth/firebase_auth.dart';

enum AuthProvider {
  email,
  google,
  apple,
  meta
}

enum SubscriptionTier {
  free,
  premium
}

enum SubscriptionPeriod {
  none,
  monthly,
  yearly
}

class UserProfile {
  final String uid;
  final String email;
  final String? displayName;
  final String? photoURL;
  final AuthProvider authProvider;
  final SubscriptionTier subscriptionTier;
  final SubscriptionPeriod subscriptionPeriod;
  final DateTime? subscriptionExpiryDate;
  final DateTime createdAt;
  final Map<String, dynamic>? metadata;

  UserProfile({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoURL,
    required this.authProvider,
    this.subscriptionTier = SubscriptionTier.free,
    this.subscriptionPeriod = SubscriptionPeriod.none,
    this.subscriptionExpiryDate,
    required this.createdAt,
    this.metadata,
  });

  // Factory constructor to create UserProfile from Firebase User
  factory UserProfile.fromFirebaseUser(User user, {
    AuthProvider authProvider = AuthProvider.email,
    SubscriptionTier subscriptionTier = SubscriptionTier.free,
    SubscriptionPeriod subscriptionPeriod = SubscriptionPeriod.none,
    DateTime? subscriptionExpiryDate,
    DateTime? createdAt,
    Map<String, dynamic>? metadata,
  }) {
    return UserProfile(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName,
      photoURL: user.photoURL,
      authProvider: authProvider,
      subscriptionTier: subscriptionTier,
      subscriptionPeriod: subscriptionPeriod,
      subscriptionExpiryDate: subscriptionExpiryDate,
      createdAt: createdAt ?? DateTime.now(),
      metadata: metadata,
    );
  }

  // Create a copy of UserProfile with updated fields
  UserProfile copyWith({
    String? displayName,
    String? photoURL,
    AuthProvider? authProvider,
    SubscriptionTier? subscriptionTier,
    SubscriptionPeriod? subscriptionPeriod,
    DateTime? subscriptionExpiryDate,
    Map<String, dynamic>? metadata,
  }) {
    return UserProfile(
      uid: this.uid,
      email: this.email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      authProvider: authProvider ?? this.authProvider,
      subscriptionTier: subscriptionTier ?? this.subscriptionTier,
      subscriptionPeriod: subscriptionPeriod ?? this.subscriptionPeriod,
      subscriptionExpiryDate: subscriptionExpiryDate ?? this.subscriptionExpiryDate,
      createdAt: this.createdAt,
      metadata: metadata ?? this.metadata,
    );
  }

  // Convert UserProfile to a Map for Firestore storage
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'authProvider': authProvider.toString(),
      'subscriptionTier': subscriptionTier.toString(),
      'subscriptionPeriod': subscriptionPeriod.toString(),
      'subscriptionExpiryDate': subscriptionExpiryDate?.millisecondsSinceEpoch,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'metadata': metadata,
    };
  }

  // Create UserProfile from a Firestore document
  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      uid: map['uid'] as String,
      email: map['email'] as String,
      displayName: map['displayName'] as String?,
      photoURL: map['photoURL'] as String?,
      authProvider: _stringToAuthProvider(map['authProvider'] as String),
      subscriptionTier: _stringToSubscriptionTier(map['subscriptionTier'] as String),
      subscriptionPeriod: _stringToSubscriptionPeriod(map['subscriptionPeriod'] as String),
      subscriptionExpiryDate: map['subscriptionExpiryDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['subscriptionExpiryDate'] as int)
          : null,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      metadata: map['metadata'] as Map<String, dynamic>?,
    );
  }

  // Helper methods for enum conversion
  static AuthProvider _stringToAuthProvider(String value) {
    return AuthProvider.values.firstWhere(
      (e) => e.toString() == value,
      orElse: () => AuthProvider.email,
    );
  }

  static SubscriptionTier _stringToSubscriptionTier(String value) {
    return SubscriptionTier.values.firstWhere(
      (e) => e.toString() == value,
      orElse: () => SubscriptionTier.free,
    );
  }

  static SubscriptionPeriod _stringToSubscriptionPeriod(String value) {
    return SubscriptionPeriod.values.firstWhere(
      (e) => e.toString() == value,
      orElse: () => SubscriptionPeriod.none,
    );
  }

  // Additional helper methods
  bool get isPremium => subscriptionTier == SubscriptionTier.premium;
  bool get isSubscriptionActive => subscriptionExpiryDate != null && 
    subscriptionExpiryDate!.isAfter(DateTime.now());
  String get subscriptionStatus => isSubscriptionActive ? 'Active' : 'Inactive';
  String get formattedExpiryDate => subscriptionExpiryDate != null ? 
    '${subscriptionExpiryDate!.day}/${subscriptionExpiryDate!.month}/${subscriptionExpiryDate!.year}' : 'N/A';
}