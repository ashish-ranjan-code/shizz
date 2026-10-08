import 'package:flutter/material.dart';
import '../models/follow_model.dart';
import '../models/user_model.dart';
import '../services/follow_service.dart';

class FollowProvider with ChangeNotifier {
  final FollowService _followService = FollowService();

  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  Stream<List<FollowRequestModel>> getPendingRequests(String uid) {
    return _followService.getPendingRequestsStream(uid);
  }

  Stream<List<FollowRelationModel>> getFollowers(String uid) {
    return _followService.getFollowersStream(uid);
  }

  Stream<List<FollowRelationModel>> getFollowing(String uid) {
    return _followService.getFollowingStream(uid);
  }

  Future<String> getStatus(String currentUid, String targetUid) {
    return _followService.getFollowStatus(currentUid: currentUid, targetUid: targetUid);
  }

  Future<void> sendRequest(String currentUid, String targetUid) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _followService.sendFollowRequest(currentUid: currentUid, targetUid: targetUid);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> cancelRequest(String currentUid, String targetUid) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _followService.cancelFollowRequest(currentUid: currentUid, targetUid: targetUid);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> acceptRequest(UserModel currentUser, UserModel requester) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _followService.acceptFollowRequest(currentUser: currentUser, requesterUser: requester);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> rejectRequest(String currentUid, String requesterUid) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _followService.rejectFollowRequest(currentUid: currentUid, requesterUid: requesterUid);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> unfollow(String currentUid, String targetUid) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _followService.unfollowUser(currentUid: currentUid, targetUid: targetUid);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }
}
