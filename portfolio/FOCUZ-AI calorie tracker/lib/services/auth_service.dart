import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Service to handle user authentication through Firebase Auth with OAuth
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  
  /// Stream of authentication state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  
  /// Returns the current user
  User? get currentUser => _auth.currentUser;
  
  /// Returns whether the user is signed in
  bool get isSignedIn => currentUser != null;
  
  /// Signs in with OAuth through Google provider
  Future<UserCredential?> signInWithGoogle() async {
    try {
      print('AuthService: Starting Google sign in flow');
      
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      // If sign in was canceled by user
      if (googleUser == null) {
        print('AuthService: Google sign in was canceled by the user');
        return null;
      }

      print('AuthService: Google sign in successful with user: ${googleUser.email}');

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      print('AuthService: Obtained Google auth tokens');

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      print('AuthService: Created Firebase credential, signing in to Firebase');
      
      // Sign in to Firebase with the Google credential
      final userCredential = await _auth.signInWithCredential(credential);
      
      print('AuthService: Firebase sign in successful for user: ${userCredential.user?.displayName}');
      
      return userCredential;
    } catch (e) {
      print('AuthService: Error signing in with Google: $e');
      // Re-throw the error so the UI can handle it appropriately
      rethrow;
    }
  }
  
  /// Signs in with email and password
  Future<UserCredential?> signInWithEmailPassword(String email, String password) async {
    try {
      print('AuthService: Starting email/password sign in');
      
      // Sign in to Firebase with email and password
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      print('AuthService: Email/password sign in successful for user: ${userCredential.user?.email}');
      
      return userCredential;
    } catch (e) {
      print('AuthService: Error signing in with email/password: $e');
      // Re-throw the error so the UI can handle it appropriately
      rethrow;
    }
  }
  
  /// Registers a new user with email and password
  Future<UserCredential?> registerWithEmailPassword(String email, String password, String displayName) async {
    try {
      print('AuthService: Starting email/password registration');
      
      // Create a new user with email and password
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Update the user's display name
      await userCredential.user?.updateDisplayName(displayName);
      
      // Reload user to ensure displayName is available immediately
      await userCredential.user?.reload();
      
      print('AuthService: Email/password registration successful for user: ${userCredential.user?.email}');
      
      return userCredential;
    } catch (e) {
      print('AuthService: Error registering with email/password: $e');
      // Re-throw the error so the UI can handle it appropriately
      rethrow;
    }
  }
  
  /// Sends a password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      print('AuthService: Sending password reset email to $email');
      
      // Firebase automatically includes a verification link in the email
      // The verification link includes a one-time code and is valid for a limited time
      // When the user clicks the link, they'll need to verify ownership of the account
      await _auth.sendPasswordResetEmail(
        email: email,
        // The ActionCodeSettings enable additional security features
        // such as requiring recent login for sensitive operations
        actionCodeSettings: ActionCodeSettings(
          url: 'https://focuz-fitness.firebaseapp.com/__/auth/action',
          handleCodeInApp: true,
          androidPackageName: 'com.example.focuz',
          androidInstallApp: true,
          androidMinimumVersion: '12',
          iOSBundleId: 'com.example.focuz',
        ),
      );
      
      print('AuthService: Password reset email sent to $email');
    } catch (e) {
      print('AuthService: Error sending password reset email: $e');
      rethrow;
    }
  }
  
  /// Verify phone number (used as 2FA for password reset)
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required PhoneVerificationCompleted verificationCompleted,
    required PhoneVerificationFailed verificationFailed,
    required PhoneCodeSent codeSent,
    required PhoneCodeAutoRetrievalTimeout codeAutoRetrievalTimeout,
  }) async {
    try {
      print('AuthService: Starting phone verification for $phoneNumber');
      
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: verificationCompleted,
        verificationFailed: verificationFailed,
        codeSent: codeSent,
        codeAutoRetrievalTimeout: codeAutoRetrievalTimeout,
        timeout: const Duration(seconds: 60),
      );
      
      print('AuthService: Phone verification process initiated');
    } catch (e) {
      print('AuthService: Error during phone verification: $e');
      rethrow;
    }
  }
  
  /// Verify the SMS code sent to phone
  Future<PhoneAuthCredential?> verifyPhoneCode({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      print('AuthService: Verifying SMS code');
      
      // Create a PhoneAuthCredential with the verification ID and SMS code
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      
      print('AuthService: SMS code verification successful');
      
      return credential;
    } catch (e) {
      print('AuthService: Error verifying SMS code: $e');
      rethrow;
    }
  }
  
  /// Signs out the current user
  Future<void> signOut() async {
    try {
      print('AuthService: Signing out user');
      
      // Sign out from Google
      await _googleSignIn.signOut();
      
      // Sign out from Firebase
      await _auth.signOut();
      
      print('AuthService: User signed out successfully');
    } catch (e) {
      print('AuthService: Error signing out: $e');
      throw e;
    }
  }
  
  /// Gets the current user's ID token
  Future<String?> getIdToken() async {
    try {
      final user = currentUser;
      if (user != null) {
        return await user.getIdToken();
      }
      return null;
    } catch (e) {
      print('AuthService: Error getting ID token: $e');
      return null;
    }
  }
  
  /// Refreshes the current user's ID token
  Future<String?> refreshIdToken() async {
    try {
      final user = currentUser;
      if (user != null) {
        return await user.getIdToken(true);
      }
      return null;
    } catch (e) {
      print('AuthService: Error refreshing ID token: $e');
      return null;
    }
  }
} 