import 'package:flutter/material.dart';

class AppConstants {
  // App Info
  static const String appName = 'Shizz';
  static const String appTagline = 'Fast, Secure & Seamless Messaging';

  // Firestore Collections
  static const String usersCollection = 'users';
  static const String contactsCollection = 'contacts';
  static const String chatsCollection = 'chats';
  static const String messagesCollection = 'messages';
  static const String usernamesCollection = 'usernames';

  // Firebase Storage paths
  static const String profileImagesStoragePath = 'profile_images';

  // Spacing & Radii
  static const double radiusSmall = 12.0;
  static const double radiusMedium = 18.0;
  static const double radiusLarge = 24.0;
  static const double radiusPill = 999.0;

  // Glassmorphism Blur Strength
  static const double glassBlur = 18.0;
  static const double glassSubtleBlur = 10.0;
}
