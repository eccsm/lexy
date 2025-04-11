// lib/features/auth/services/user_profile_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:voicenotes/database/models/user_profile.dart';

class UserProfileService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final Logger _logger = Logger();

  UserProfileService({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
  })  : _firestore = firestore,
        _auth = auth;

  // Collection reference
  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  // Get a reference to a user document
  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _usersCollection.doc(uid);

  // Create a new user profile in Firestore
  Future<void> createUserProfile(UserProfile profile) async {
    try {
      await _userDoc(profile.uid).set(profile.toMap());
      _logger.i('User profile created for ${profile.uid}');
    } catch (e) {
      _logger.e('Error creating user profile: $e');
      throw Exception('Failed to create user profile: $e');
    }
  }

  // Get user profile from Firestore
  Future<UserProfile?> getUserProfile(String uid) async {
    try {
      final doc = await _userDoc(uid).get();
      if (doc.exists) {
        return UserProfile.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      _logger.e('Error getting user profile: $e');
      throw Exception('Failed to get user profile: $e');
    }
  }

  // Update user profile in Firestore
  Future<void> updateUserProfile(UserProfile profile) async {
    try {
      await _userDoc(profile.uid).update(profile.toMap());
      _logger.i('User profile updated for ${profile.uid}');
    } catch (e) {
      _logger.e('Error updating user profile: $e');
      throw Exception('Failed to update user profile: $e');
    }
  }

  // Update subscription information
  Future<void> updateSubscription({
    required String uid,
    required SubscriptionTier tier,
    required SubscriptionPeriod period,
    required DateTime? expiryDate,
  }) async {
    try {
      await _userDoc(uid).update({
        'subscriptionTier': tier.toString(),
        'subscriptionPeriod': period.toString(),
        'subscriptionExpiryDate': expiryDate?.millisecondsSinceEpoch,
      });
      _logger.i('Subscription updated for $uid');
    } catch (e) {
      _logger.e('Error updating subscription: $e');
      throw Exception('Failed to update subscription: $e');
    }
  }

  // Create or update user profile on sign-in
  Future<UserProfile> createOrUpdateUserProfileOnSignIn(
    User user,
    AuthProvider provider,
  ) async {
    try {
      // Check if the user profile already exists
      final existingProfile = await getUserProfile(user.uid);
      
      if (existingProfile != null) {
        // Update profile with latest user info from Firebase Auth
        final updatedProfile = existingProfile.copyWith(
          displayName: user.displayName ?? existingProfile.displayName,
          photoURL: user.photoURL ?? existingProfile.photoURL,
          authProvider: provider,
        );
        
        await updateUserProfile(updatedProfile);
        return updatedProfile;
      } else {
        // Create new profile
        final newProfile = UserProfile.fromFirebaseUser(
          user,
          authProvider: provider,
          createdAt: DateTime.now(),
        );
        
        await createUserProfile(newProfile);
        return newProfile;
      }
    } catch (e) {
      _logger.e('Error in createOrUpdateUserProfileOnSignIn: $e');
      throw Exception('Failed to manage user profile: $e');
    }
  }

  // Get current user profile
  Future<UserProfile?> getCurrentUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    return getUserProfile(user.uid);
  }

  // Stream of user profile changes
  Stream<UserProfile?> userProfileStream(String uid) {
    return _userDoc(uid).snapshots().map((snapshot) {
      if (snapshot.exists) {
        return UserProfile.fromMap(snapshot.data()!);
      }
      return null;
    });
  }

  // Stream of current user profile changes
  Stream<UserProfile?> currentUserProfileStream() {
    return _auth.authStateChanges().asyncMap((user) async {
      if (user == null) return null;
      return await getUserProfile(user.uid);
    });
  }
}

// Provider for UserProfileService
final userProfileServiceProvider = Provider<UserProfileService>((ref) {
  return UserProfileService(
    firestore: FirebaseFirestore.instance,
    auth: FirebaseAuth.instance,
  );
});

// Provider for current user profile
final currentUserProfileProvider = StreamProvider<UserProfile?>((ref) {
  final userProfileService = ref.watch(userProfileServiceProvider);
  return userProfileService.currentUserProfileStream();
});

// Provider for a specific user profile
final userProfileProvider = StreamProvider.family<UserProfile?, String>((ref, uid) {
  final userProfileService = ref.watch(userProfileServiceProvider);
  return userProfileService.userProfileStream(uid);
});