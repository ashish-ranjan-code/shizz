import 'dart:io';
import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../services/user_service.dart';

class UserProvider with ChangeNotifier {
  final UserService _userService = UserService();
  final StorageService _storageService = StorageService();

  bool _isUpdating = false;
  String? _updateError;

  bool get isUpdating => _isUpdating;
  String? get updateError => _updateError;

  Future<bool> updateProfileDetails({
    required String uid,
    String? displayName,
    String? bio,
    String? currentUsername,
    String? newUsername,
  }) async {
    _isUpdating = true;
    _updateError = null;
    notifyListeners();

    try {
      await _userService.updateProfile(
        uid: uid,
        displayName: displayName,
        bio: bio,
        currentUsername: currentUsername,
        newUsername: newUsername,
      );
      _isUpdating = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isUpdating = false;
      _updateError = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> uploadAndSetAvatar({
    required String uid,
    required File imageFile,
  }) async {
    _isUpdating = true;
    _updateError = null;
    notifyListeners();

    try {
      final photoUrl = await _storageService.uploadProfileImage(
        uid: uid,
        imageFile: imageFile,
      );
      await _userService.updateProfile(
        uid: uid,
        photoUrl: photoUrl,
      );
      _isUpdating = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isUpdating = false;
      _updateError = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> setPresence(String uid, bool isOnline) async {
    await _userService.updatePresence(uid: uid, isOnline: isOnline);
  }
}
