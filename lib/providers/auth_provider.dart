import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();

  User? _firebaseUser;
  UserModel? _currentUserModel;
  bool _isInitialized = false;
  bool _isLoading = false;
  String? _errorMessage;

  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<UserModel?>? _userDocSubscription;

  AuthProvider() {
    _initAuthListener();
  }

  User? get firebaseUser => _firebaseUser;
  UserModel? get currentUserModel => _currentUserModel;
  bool get isAuthenticated => _firebaseUser != null;
  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void _initAuthListener() {
    _authSubscription = _authService.authStateChanges.listen((user) async {
      _firebaseUser = user;
      if (user != null) {
        try {
          _currentUserModel = await _userService.getUserProfile(user.uid);
        } catch (_) {}
        _listenToUserDocument(user.uid);
      } else {
        _userDocSubscription?.cancel();
        _currentUserModel = null;
      }
      _isInitialized = true;
      notifyListeners();
    });
  }

  void _listenToUserDocument(String uid) {
    _userDocSubscription?.cancel();
    _userDocSubscription = _userService.getUserStream(uid).listen((userModel) {
      _currentUserModel = userModel;
      notifyListeners();
    });
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> signIn({required String email, required String password}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final credential = await _authService.signIn(
        email: email,
        password: password,
      );
      if (credential.user != null) {
        await _userService.updatePresence(
          uid: credential.user!.uid,
          isOnline: true,
        );
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String username,
    required String displayName,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Verify username availability first
      final isAvailable = await _userService.isUsernameAvailable(username);
      if (!isAvailable) {
        throw 'Username "@$username" is already taken. Please choose another.';
      }

      // 2. Create Auth user
      final credential = await _authService.signUp(
        email: email,
        password: password,
      );

      final uid = credential.user!.uid;

      // 3. Create Firestore User profile doc & claim username
      final newUser = UserModel(
        uid: uid,
        email: email.trim().toLowerCase(),
        username: username.trim().toLowerCase(),
        displayName: displayName.trim(),
        createdAt: DateTime.now(),
        isOnline: true,
        lastSeen: DateTime.now(),
      );

      await _userService.createUserProfile(newUser);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Google Sign-In orchestration:
  /// Returns:
  /// - 'existing_user': Google user with an existing Firestore profile and username -> proceed to Home
  /// - 'new_user_needs_username': Authenticated with Google for the first time -> navigate to Choose Username screen
  /// - 'cancelled': User aborted Google account picker -> do nothing
  /// - 'error': Failed -> display errorMessage
  Future<String> signInWithGoogle() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final credential = await _authService.signInWithGoogle();
      if (credential == null || credential.user == null) {
        _isLoading = false;
        notifyListeners();
        return 'cancelled';
      }

      final uid = credential.user!.uid;

      // Check if user already exists with an established username
      final existingUser = await _userService.getUserProfile(uid);
      if (existingUser != null && existingUser.username.isNotEmpty) {
        // User exists: update presence and go to Home
        await _userService.updatePresence(uid: uid, isOnline: true);
        _isLoading = false;
        notifyListeners();
        return 'existing_user';
      }

      // First time Google user: needs to choose a unique username
      _isLoading = false;
      notifyListeners();
      return 'new_user_needs_username';
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return 'error';
    }
  }

  /// Completes registration for a new Google user by claiming their unique username
  Future<bool> completeGoogleSignUp({
    required String username,
  }) async {
    if (_firebaseUser == null) {
      _errorMessage = 'No authenticated Google account session found.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final cleanUsername = username.trim().toLowerCase();
      final isAvailable = await _userService.isUsernameAvailable(cleanUsername);
      if (!isAvailable) {
        throw 'Username "@$cleanUsername" is already taken. Please choose another.';
      }

      final uid = _firebaseUser!.uid;
      final email = _firebaseUser!.email ?? '';
      final displayName = (_firebaseUser!.displayName != null && _firebaseUser!.displayName!.isNotEmpty)
          ? _firebaseUser!.displayName!
          : cleanUsername;
      final photoUrl = _firebaseUser!.photoURL;

      final newUser = UserModel(
        uid: uid,
        email: email,
        username: cleanUsername,
        displayName: displayName,
        photoUrl: photoUrl,
        bio: 'Hey there! I am using Shizz.',
        createdAt: DateTime.now(),
        lastSeen: DateTime.now(),
        isOnline: true,
      );

      await _userService.createUserProfile(newUser);
      _currentUserModel = newUser;
      _listenToUserDocument(uid);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    if (_firebaseUser != null) {
      await _userService.updatePresence(
        uid: _firebaseUser!.uid,
        isOnline: false,
      );
    }
    await _authService.signOut();
  }

  /// Sends a password reset email to the specified address
  Future<bool> sendPasswordResetEmail(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.sendPasswordResetEmail(email: email);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Refreshes current user authentication state
  Future<void> reloadUser() async {
    await _authService.reloadUser();
    _firebaseUser = _authService.currentUser;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _userDocSubscription?.cancel();
    super.dispose();
  }
}
