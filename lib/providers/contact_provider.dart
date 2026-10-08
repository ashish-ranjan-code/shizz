import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/contact_service.dart';
import '../services/user_service.dart';

class ContactProvider with ChangeNotifier {
  final ContactService _contactService = ContactService();
  final UserService _userService = UserService();

  List<UserModel> _searchResults = [];
  bool _isSearching = false;
  String? _searchError;
  bool _isActionLoading = false;

  List<UserModel> get searchResults => _searchResults;
  bool get isSearching => _isSearching;
  String? get searchError => _searchError;
  bool get isActionLoading => _isActionLoading;

  Future<void> searchUsers({
    required String query,
    required String currentUid,
  }) async {
    final clean = query.trim().toLowerCase();
    if (clean.isEmpty) {
      _searchResults = [];
      _isSearching = false;
      notifyListeners();
      return;
    }

    _isSearching = true;
    _searchError = null;
    notifyListeners();

    try {
      final results = await _userService.searchUsersByUsername(
        query: clean,
        currentUid: currentUid,
      );
      _searchResults = results;
      _isSearching = false;
      notifyListeners();
    } catch (e) {
      _isSearching = false;
      _searchError = 'Failed to search users. Please try again.';
      notifyListeners();
    }
  }

  void clearSearch() {
    _searchResults = [];
    _isSearching = false;
    _searchError = null;
    notifyListeners();
  }

  Future<bool> addContact({
    required String currentUid,
    required UserModel targetUser,
  }) async {
    _isActionLoading = true;
    notifyListeners();

    try {
      await _contactService.addContact(
        currentUid: currentUid,
        targetUser: targetUser,
      );
      _isActionLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isActionLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> removeContact({
    required String currentUid,
    required String contactUid,
  }) async {
    _isActionLoading = true;
    notifyListeners();

    try {
      await _contactService.removeContact(
        currentUid: currentUid,
        contactUid: contactUid,
      );
      _isActionLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isActionLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> isContact({
    required String currentUid,
    required String contactUid,
  }) async {
    return await _contactService.isContact(
      currentUid: currentUid,
      contactUid: contactUid,
    );
  }
}
