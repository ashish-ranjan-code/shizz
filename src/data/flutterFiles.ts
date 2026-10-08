import { FlutterCodeFile } from '../types/shizz';

export const FLUTTER_FILES: FlutterCodeFile[] = [
  {
    path: 'pubspec.yaml',
    category: 'root',
    description: 'Dependencies: firebase_core, firebase_auth, cloud_firestore, firebase_storage, provider, shared_preferences, google_fonts, cached_network_image, image_picker',
    content: `name: shizz
description: "Shizz - Modern Real-Time Messenger"
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter

  firebase_core: ^3.6.0
  firebase_auth: ^5.3.1
  cloud_firestore: ^5.4.4
  firebase_storage: ^12.3.4
  google_sign_in: ^6.2.1
  provider: ^6.1.2
  shared_preferences: ^2.3.2
  google_fonts: ^6.2.1
  cached_network_image: ^3.4.1
  intl: ^0.19.0
  image_picker: ^1.1.2
  cupertino_icons: ^1.0.8

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0

flutter:
  uses-material-design: true`
  },
  {
    path: 'android/app/build.gradle',
    category: 'android',
    description: 'Android application build configuration with applicationId com.shizz.messenger, google-services plugin, and Play Services auth',
    content: `// Located at android/app/build.gradle (see file in workspace)`
  },
  {
    path: 'android/app/build.gradle.kts',
    category: 'android',
    description: 'Android application Kotlin DSL configuration with namespace and applicationId com.shizz.messenger',
    content: `// Located at android/app/build.gradle.kts (see file in workspace)`
  },
  {
    path: 'android/app/google-services.json',
    category: 'android',
    description: 'Firebase Android config with OAuth 2.0 client IDs for package com.shizz.messenger and SHA-1 fingerprint registration',
    content: `// Located at android/app/google-services.json (see file in workspace)`
  },
  {
    path: 'android/app/src/main/kotlin/com/shizz/messenger/MainActivity.kt',
    category: 'android',
    description: 'Android MainActivity with package com.shizz.messenger',
    content: `package com.shizz.messenger

import io.flutter.embedding.android.FlutterActivity

class MainActivity: FlutterActivity()`
  },
  {
    path: 'android/gradle.properties',
    category: 'android',
    description: 'Gradle properties disabling Kotlin incremental compilation to resolve Windows multi-drive root conflict (C: vs D:)',
    content: `org.gradle.jvmargs=-Xmx4G -XX:MaxMetaspaceSize=1G -XX:+HeapDumpOnOutOfMemoryError
android.useAndroidX=true
android.enableJetifier=true

kotlin.incremental=false
kotlin.compiler.execution.strategy=in-process
org.gradle.workers.max=1

kotlin.incremental.useClasspathSnapshot=false
kotlin.incremental.java=false`
  },
  {
    path: 'lib/screens/auth/choose_username_screen.dart',
    category: 'screens',
    description: 'ChooseUsernameScreen: Google user onboarding, unique @handle reservation with live Firestore debounce check',
    content: `// Located at lib/screens/auth/choose_username_screen.dart (see file in workspace)`
  },
  {
    path: 'lib/screens/auth/login_screen.dart',
    category: 'screens',
    description: 'LoginScreen: Email/Password login, Continue with Google button, Google account handling, and modern UI styling',
    content: `// Located at lib/screens/auth/login_screen.dart (see file in workspace)`
  },
  {
    path: 'lib/screens/auth/signup_screen.dart',
    category: 'screens',
    description: 'SignUpScreen: Email/Password registration, Continue with Google button, normalized lowercase uniqueness checking',
    content: `// Located at lib/screens/auth/signup_screen.dart (see file in workspace)`
  },
  {
    path: 'firestore.rules',
    category: 'root',
    description: 'Production Firestore security rules for users, contacts, chats, and messages',
    content: `rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    function isAuthenticated() { return request.auth != null; }
    function isOwner(userId) { return isAuthenticated() && request.auth.uid == userId; }

    match /users/{userId} {
      allow read: if isAuthenticated();
      allow create: if isAuthenticated() && request.auth.uid == userId;
      allow update: if isOwner(userId);
      allow delete: if false;

      match /contacts/{contactId} {
        allow read, write: if isOwner(userId);
      }
    }

    match /usernames/{username} {
      allow read: if isAuthenticated();
      allow create: if isAuthenticated() && request.resource.data.uid == request.auth.uid;
      allow delete: if isAuthenticated() && resource.data.uid == request.auth.uid;
      allow update: if false;
    }

    match /chats/{chatId} {
      allow read: if isAuthenticated() && request.auth.uid in resource.data.participants;
      allow create: if isAuthenticated() 
        && request.auth.uid in request.resource.data.participants
        && request.resource.data.participants.size() == 2;
      allow update: if isAuthenticated() && request.auth.uid in resource.data.participants;
      allow delete: if false;

      match /messages/{messageId} {
        allow read: if isAuthenticated() && 
          request.auth.uid in get(/databases/$(database)/documents/chats/$(chatId)).data.participants;
        allow create: if isAuthenticated() 
          && request.auth.uid == request.resource.data.senderId
          && request.auth.uid in get(/databases/$(database)/documents/chats/$(chatId)).data.participants;
        allow update: if isAuthenticated() 
          && request.auth.uid in get(/databases/$(database)/documents/chats/$(chatId)).data.participants
          && request.resource.data.diff(resource.data).affectedKeys().hasOnly(['isRead']);
        allow delete: if false;
      }
    }
  }
}`
  },
  {
    path: 'storage.rules',
    category: 'root',
    description: 'Firebase Storage rules for user avatars and chat image attachments',
    content: `rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /profile_images/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null 
        && request.auth.uid == userId
        && request.resource.size < 5 * 1024 * 1024
        && request.resource.contentType.matches('image/.*');
    }

    match /chat_attachments/{chatId}/{fileName} {
      allow read: if request.auth != null;
      allow write: if request.auth != null
        && request.resource.size < 20 * 1024 * 1024
        && request.resource.contentType.matches('image/.*');
    }
  }
}`
  },
  {
    path: 'lib/main.dart',
    category: 'root',
    description: 'App entry point, multi-provider setup with ThemeProvider, dark/light themes, and initial route',
    content: `// Located at lib/main.dart (see file in workspace)`
  },
  {
    path: 'lib/providers/theme_provider.dart',
    category: 'providers',
    description: 'ThemeProvider: Dark mode, Light mode, System mode with SharedPreferences persistence',
    content: `// Located at lib/providers/theme_provider.dart (see file in workspace)`
  },
  {
    path: 'lib/models/user_model.dart',
    category: 'models',
    description: 'UserModel: uid, email, username, displayName, photoUrl, bio, isOnline, lastSeen',
    content: `// Located at lib/models/user_model.dart (see file in workspace)`
  },
  {
    path: 'lib/models/chat_model.dart',
    category: 'models',
    description: 'ChatModel: chatId, participants, lastMessage, lastMessageTime, unreadCounts',
    content: `// Located at lib/models/chat_model.dart (see file in workspace)`
  },
  {
    path: 'lib/models/message_model.dart',
    category: 'models',
    description: 'MessageModel: messageId, chatId, senderId, receiverId, text, timestamp, type, isRead',
    content: `// Located at lib/models/message_model.dart (see file in workspace)`
  },
  {
    path: 'lib/models/contact_model.dart',
    category: 'models',
    description: 'ContactModel: contactUid, username, displayName, photoUrl, addedAt',
    content: `// Located at lib/models/contact_model.dart (see file in workspace)`
  },
  {
    path: 'lib/services/auth_service.dart',
    category: 'services',
    description: 'AuthService: Native Firebase Authentication & real Google Sign-In with GoogleSignIn & FirebaseAuth credential exchange',
    content: `import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;
  String? get currentUid => _auth.currentUser?.uid;

  /// Native Google Sign-In with real Google account picker & Firebase credential
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // Cancelled

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return await _auth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Google Sign-In failed: \${e.toString()}';
    }
  }

  Future<UserCredential> signIn({required String email, required String password}) async {
    try {
      return await _auth.signInWithEmailAndPassword(email: email.trim(), password: password);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<UserCredential> signUp({required String email, required String password}) async {
    try {
      return await _auth.createUserWithEmailAndPassword(email: email.trim(), password: password);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  Future<void> sendPasswordResetEmail({required String email}) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> reloadUser() async {
    await _auth.currentUser?.reload();
  }

  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found': return 'No user found with this email.';
      case 'wrong-password': return 'Incorrect password. Please verify and try again.';
      case 'invalid-credential': return 'Invalid email or password.';
      case 'email-already-in-use': return 'This email address is already in use by another account.';
      case 'operation-not-allowed': return 'Google Sign-In is not enabled in Firebase Console.';
      default: return e.message ?? 'Authentication error occurred (\${e.code}).';
    }
  }
}`
  },
  {
    path: 'lib/providers/auth_provider.dart',
    category: 'providers',
    description: 'AuthProvider: Firebase Auth state listener, user persistence, real Google Sign-In orchestration, and Choose Username flow',
    content: `import 'dart:async';
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
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void _initAuthListener() {
    _authSubscription = _authService.authStateChanges.listen((user) {
      _firebaseUser = user;
      if (user != null) {
        _listenToUserDocument(user.uid);
      } else {
        _userDocSubscription?.cancel();
        _currentUserModel = null;
      }
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
      final existingUser = await _userService.getUserProfile(uid);
      if (existingUser != null && existingUser.username.isNotEmpty) {
        await _userService.updatePresence(uid: uid, isOnline: true);
        _isLoading = false;
        notifyListeners();
        return 'existing_user';
      }

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

  Future<bool> completeGoogleSignUp({required String username}) async {
    // Reserves unique @username in Firestore and creates users/{uid} profile
    // ...
    return true;
  }
}`
  },
  {
    path: 'lib/services/chat_service.dart',
    category: 'services',
    description: 'ChatService: deterministic 1-to-1 chats, text and image attachments via Firebase Storage, mark-as-read',
    content: `// Located at lib/services/chat_service.dart (see file in workspace)`
  },
  {
    path: 'lib/services/storage_service.dart',
    category: 'services',
    description: 'StorageService: profile picture upload and chat attachment upload to Firebase Storage',
    content: `// Located at lib/services/storage_service.dart (see file in workspace)`
  },
  {
    path: 'lib/services/user_service.dart',
    category: 'services',
    description: 'UserService: unique username reservation, profile updates, presence status, username prefix search',
    content: `// Located at lib/services/user_service.dart (see file in workspace)`
  },
  {
    path: 'lib/services/contact_service.dart',
    category: 'services',
    description: 'ContactService: addContact, removeContact, streamContacts, isContact in Firestore',
    content: `// Located at lib/services/contact_service.dart (see file in workspace)`
  },
  {
    path: 'lib/theme/app_theme.dart',
    category: 'theme',
    description: 'Design system: darkTheme, lightTheme, frosted blur constants, Electric Indigo and Cyan accents',
    content: `// Located at lib/theme/app_theme.dart (see file in workspace)`
  },
  {
    path: 'lib/widgets/glass_card.dart',
    category: 'widgets',
    description: 'BackdropFilter blur container with translucent gradients and glowing borders',
    content: `// Located at lib/widgets/glass_card.dart (see file in workspace)`
  },
  {
    path: 'lib/widgets/message_bubble.dart',
    category: 'widgets',
    description: 'MessageBubble: text and photo messages with full-screen zoom, timestamps, and cyan read receipt checkmarks',
    content: `// Located at lib/widgets/message_bubble.dart (see file in workspace)`
  },
  {
    path: 'lib/screens/chat/chat_screen.dart',
    category: 'screens',
    description: 'ChatScreen: real-time Firestore stream, ImagePicker attachment button, auto-scroll, read receipts, recipient info sheet',
    content: `// Located at lib/screens/chat/chat_screen.dart (see file in workspace)`
  },
  {
    path: 'lib/screens/profile/profile_screen.dart',
    category: 'screens',
    description: 'ProfileScreen: display name, username, bio, photo upload to Storage, and working Appearance theme switcher',
    content: `// Located at lib/screens/profile/profile_screen.dart (see file in workspace)`
  },
  {
    path: 'lib/screens/contacts/new_contact_screen.dart',
    category: 'screens',
    description: 'NewContactScreen: live username search in Firestore, user profile modal, add contact, start direct chat',
    content: `// Located at lib/screens/contacts/new_contact_screen.dart (see file in workspace)`
  },
  {
    path: 'lib/screens/auth/login_screen.dart',
    category: 'screens',
    description: 'LoginScreen: Real Firebase email/password and Continue with Google Sign-In button, redirects existing users to Home',
    content: `// Located at lib/screens/auth/login_screen.dart (see file in workspace)`
  },
  {
    path: 'lib/screens/auth/signup_screen.dart',
    category: 'screens',
    description: 'SignUpScreen: Real Firebase Auth account creation, real-time username uniqueness check, and Continue with Google',
    content: `// Located at lib/screens/auth/signup_screen.dart (see file in workspace)`
  },
  {
    path: 'lib/screens/auth/choose_username_screen.dart',
    category: 'screens',
    description: 'ChooseUsernameScreen: First-time Google Sign-In unique handle selection with live Firestore check, cancel/switch account option',
    content: `// Located at lib/screens/auth/choose_username_screen.dart (see file in workspace)`
  }
];
