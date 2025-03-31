import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthController extends StateNotifier<AsyncValue<User?>> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  
  AuthController() : super(const AsyncValue.loading()) {
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
  Future<void> signUpWithEmail(String email, String password) async {
    try {
      state = const AsyncValue.loading();
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      state = AsyncValue.data(_auth.currentUser);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }
  
  // Email sign in
  Future<void> signInWithEmail(String email, String password) async {
    try {
      state = const AsyncValue.loading();
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      state = AsyncValue.data(_auth.currentUser);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }
  
  // Google sign in
  Future<void> signInWithGoogle() async {
    try {
      state = const AsyncValue.loading();
      
      // Trigger the Google authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        state = AsyncValue.data(_auth.currentUser);
        return;
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
      
      state = AsyncValue.data(_auth.currentUser);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }
  
  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      rethrow;
    }
  }
  
  // Sign out
  Future<void> signOut() async {
    try {
      state = const AsyncValue.loading();
      await _googleSignIn.signOut();
      await _auth.signOut();
      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }
  
  // Update profile
  Future<void> updateProfile({String? displayName, String? photoURL}) async {
    try {
      state = const AsyncValue.loading();
      
      if (_auth.currentUser != null) {
        await _auth.currentUser!.updateDisplayName(displayName);
        await _auth.currentUser!.updatePhotoURL(photoURL);
        
        // Refresh user data
        await _auth.currentUser!.reload();
        state = AsyncValue.data(_auth.currentUser);
      }
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AsyncValue<User?>>((ref) {
  return AuthController();
});