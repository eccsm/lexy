import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter_login_facebook/flutter_login_facebook.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:logger/logger.dart';
import 'package:voicenotes/database/models/user_profile.dart';


import 'services/user_profile_service.dart';

class AuthController extends StateNotifier<AsyncValue<User?>> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FacebookLogin _facebookLogin = FacebookLogin();
  final UserProfileService _userProfileService;
  final Logger _logger = Logger();
  
  AuthController({required UserProfileService userProfileService}) 
      : _userProfileService = userProfileService,
        super(const AsyncValue.loading()) {
    _init();
  }
  
  void _init() {
    state = AsyncValue.data(_auth.currentUser);
  }
  
  // Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  
  // Current user
  User? get currentUser => _auth.currentUser;
  
  // Email sign up
  Future<UserProfile> signUpWithEmail(String email, String password, {String? displayName}) async {
    try {
      state = const AsyncValue.loading();
      
      // Create user with email and password
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      final user = userCredential.user!;
      
      // Update display name if provided
      if (displayName != null) {
        await user.updateDisplayName(displayName);
        // Reload user to get updated info
        await user.reload();
      }
      
      // Create user profile
      final userProfile = await _userProfileService.createOrUpdateUserProfileOnSignIn(
        _auth.currentUser!, 
        AuthProvider.email
      );
      
      state = AsyncValue.data(_auth.currentUser);
      return userProfile;
    } catch (e) {
      _logger.e('Error in signUpWithEmail: $e');
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }
  
  // Email sign in
  Future<UserProfile> signInWithEmail(String email, String password) async {
    try {
      state = const AsyncValue.loading();
      
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Create or update user profile
      final userProfile = await _userProfileService.createOrUpdateUserProfileOnSignIn(
        _auth.currentUser!, 
        AuthProvider.email
      );
      
      state = AsyncValue.data(_auth.currentUser);
      return userProfile;
    } catch (e) {
      _logger.e('Error in signInWithEmail: $e');
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }
  
  // Google sign in
  Future<UserProfile> signInWithGoogle() async {
    try {
      state = const AsyncValue.loading();
      
      // Trigger the Google authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        state = AsyncValue.data(_auth.currentUser);
        throw Exception('Google sign in was canceled by the user');
      }
      
      // Obtain the auth details from the Google sign in
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      // Create a new credential for Firebase
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      
      // Sign in to Firebase with the Google credential
      await _auth.signInWithCredential(credential);
      
      // Create or update user profile
      final userProfile = await _userProfileService.createOrUpdateUserProfileOnSignIn(
        _auth.currentUser!, 
        AuthProvider.google
      );
      
      state = AsyncValue.data(_auth.currentUser);
      return userProfile;
    } catch (e) {
      _logger.e('Error in signInWithGoogle: $e');
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }
  
  // Meta (Facebook) sign in
  Future<UserProfile> signInWithMeta() async {
    try {
      state = const AsyncValue.loading();
      
      // Configure Facebook Login
      await _facebookLogin.logIn(permissions: [
        FacebookPermission.publicProfile,
        FacebookPermission.email,
      ]);
      
      // Check login status
      final FacebookAccessToken? accessToken = await _facebookLogin.accessToken;
      
      if (accessToken == null) {
        state = AsyncValue.data(_auth.currentUser);
        throw Exception('Facebook login failed or was canceled');
      }
      
      // Create a Facebook credential for Firebase
      final OAuthCredential credential = FacebookAuthProvider.credential(accessToken.token);
      
      // Sign in to Firebase with the Facebook credential
      await _auth.signInWithCredential(credential);
      
      // Create or update user profile
      final userProfile = await _userProfileService.createOrUpdateUserProfileOnSignIn(
        _auth.currentUser!, 
        AuthProvider.meta
      );
      
      state = AsyncValue.data(_auth.currentUser);
      return userProfile;
    } catch (e) {
      _logger.e('Error in signInWithMeta: $e');
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }
  
  // Apple sign in
  Future<UserProfile> signInWithApple() async {
    try {
      state = const AsyncValue.loading();
      
      // Get Apple sign in credentials
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
      
      // Create an OAuthCredential for Firebase
      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );
      
      // Sign in to Firebase with the Apple credential
      await _auth.signInWithCredential(oauthCredential);
      
      // Update user display name if Apple provides it
      final User? user = _auth.currentUser;
      if (user != null && user.displayName == null && 
          (appleCredential.givenName != null || appleCredential.familyName != null)) {
        final displayName = [
          appleCredential.givenName,
          appleCredential.familyName
        ].where((name) => name != null).join(' ');
        
        if (displayName.isNotEmpty) {
          await user.updateDisplayName(displayName);
          // Reload user to get updated info
          await user.reload();
        }
      }
      
      // Create or update user profile
      final userProfile = await _userProfileService.createOrUpdateUserProfileOnSignIn(
        _auth.currentUser!, 
        AuthProvider.apple
      );
      
      state = AsyncValue.data(_auth.currentUser);
      return userProfile;
    } catch (e) {
      _logger.e('Error in signInWithApple: $e');
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }
  
  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      _logger.i('Password reset email sent to $email');
    } catch (e) {
      _logger.e('Error sending password reset email: $e');
      rethrow;
    }
  }
  
  Future<void> signOut() async {
    try {
      state = const AsyncValue.loading();
      await _facebookLogin.logOut();
      await _googleSignIn.signOut();
      await _auth.signOut();
      state = const AsyncValue.data(null);
      _logger.i('User signed out');
    } catch (e) {
      _logger.e('Error signing out: $e');
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }
  
  // Update profile
  Future<void> updateProfile({String? displayName, String? photoURL}) async {
    try {
      state = const AsyncValue.loading();
      
      if (_auth.currentUser != null) {
        // Update Firebase Auth profile
        if (displayName != null) {
          await _auth.currentUser!.updateDisplayName(displayName);
        }
        
        if (photoURL != null) {
          await _auth.currentUser!.updatePhotoURL(photoURL);
        }
        
        // Refresh user data
        await _auth.currentUser!.reload();
        
        // Update profile in Firestore
        final currentProfile = await _userProfileService.getCurrentUserProfile();
        if (currentProfile != null) {
          final updatedProfile = currentProfile.copyWith(
            displayName: displayName ?? currentProfile.displayName,
            photoURL: photoURL ?? currentProfile.photoURL,
          );
          
          await _userProfileService.updateUserProfile(updatedProfile);
        }
        
        state = AsyncValue.data(_auth.currentUser);
        _logger.i('User profile updated');
      }
    } catch (e) {
      _logger.e('Error updating profile: $e');
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }
  
  // Update subscription
  Future<void> updateSubscription({
    required SubscriptionTier tier,
    required SubscriptionPeriod period,
    required DateTime? expiryDate,
  }) async {
    try {
      if (_auth.currentUser == null) {
        throw Exception('No authenticated user');
      }
      
      await _userProfileService.updateSubscription(
        uid: _auth.currentUser!.uid,
        tier: tier,
        period: period,
        expiryDate: expiryDate,
      );
      
      _logger.i('Subscription updated for user ${_auth.currentUser!.uid}');
    } catch (e) {
      _logger.e('Error updating subscription: $e');
      rethrow;
    }
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AsyncValue<User?>>((ref) {
  final userProfileService = ref.watch(userProfileServiceProvider);
  return AuthController(userProfileService: userProfileService);
});