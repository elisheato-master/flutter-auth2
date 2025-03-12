import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import '../models/user_model.dart';
import 'database_service.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final DatabaseService _databaseService = DatabaseService();
  
  // Sign up with email and password
  Future<UserModel?> signUpWithEmail(String email, String password) async {
    try {
      // Hash the password
      final hashedPassword = _hashPassword(password);
      
      // Create a user in MongoDB
      final userId = DateTime.now().millisecondsSinceEpoch.toString();
      final user = UserModel(
        id: userId,
        email: email,
        authType: AuthType.email,
      );
      
      // Store user in MongoDB
      await _databaseService.createUser(user, hashedPassword);
      
      return user;
    } catch (e) {
      print('Error signing up with email: $e');
      rethrow;
    }
  }
  
  // Sign in with email and password
  Future<UserModel?> signInWithEmail(String email, String password) async {
    try {
      // Hash the password for comparison
      final hashedPassword = _hashPassword(password);
      
      // Verify credentials against MongoDB
      final user = await _databaseService.getUserByEmail(email);
      
      if (user == null) {
        throw Exception('User not found');
      }
      
      // Verify password
      final isValid = await _databaseService.verifyPassword(email, hashedPassword);
      
      if (!isValid) {
        throw Exception('Invalid password');
      }
      
      return user;
    } catch (e) {
      print('Error signing in with email: $e');
      rethrow;
    }
  }
  
  // Sign in with Google
  Future<UserModel?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        return null;
      }
      
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      
      final userCredential = await _firebaseAuth.signInWithCredential(credential);
      final user = userCredential.user;
      
      if (user != null) {
        final userModel = UserModel(
          id: user.uid,
          email: user.email!,
          displayName: user.displayName,
          photoUrl: user.photoURL,
          authType: AuthType.google,
        );
        
        // Store or update user in MongoDB
        await _databaseService.createOrUpdateUser(userModel);
        
        return userModel;
      }
      
      return null;
    } catch (e) {
      print('Error signing in with Google: $e');
      rethrow;
    }
  }
  
  // Sign in with Facebook
  Future<UserModel?> signInWithFacebook() async {
    try {
      final LoginResult result = await FacebookAuth.instance.login();
      
      if (result.status == LoginStatus.success) {
        // Get user data from Facebook
        final userData = await FacebookAuth.instance.getUserData();
        
        // Get access token for Firebase auth
        final AccessToken accessToken = result.accessToken!;
        
        // Sign in to Firebase with Facebook credential
        final OAuthCredential credential = FacebookAuthProvider.credential(accessToken.token);
        final userCredential = await _firebaseAuth.signInWithCredential(credential);
        final user = userCredential.user;
        
        if (user != null) {
          final userModel = UserModel(
            id: user.uid,
            email: user.email ?? userData['email'],
            displayName: user.displayName ?? userData['name'],
            photoUrl: user.photoURL ?? userData['picture']['data']['url'],
            authType: AuthType.facebook,
          );
          
          // Store or update user in MongoDB
          await _databaseService.createOrUpdateUser(userModel);
          
          return userModel;
        }
      }
      
      return null;
    } catch (e) {
      print('Error signing in with Facebook: $e');
      rethrow;
    }
  }
  
  // Sign out
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
      await _googleSignIn.signOut();
      await FacebookAuth.instance.logOut();
    } catch (e) {
      print('Error signing out: $e');
      rethrow;
    }
  }
  
  // Hash password using SHA-256
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final hash = sha256.convert(bytes);
    return hash.toString();
  }
}
