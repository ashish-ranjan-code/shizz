import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/follow_model.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';

class FollowService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference _usersRef() =>
      _firestore.collection(AppConstants.usersCollection);

  CollectionReference _followRequestsRef(String uid) =>
      _usersRef().doc(uid).collection('followRequests');

  CollectionReference _followersRef(String uid) =>
      _usersRef().doc(uid).collection('followers');

  CollectionReference _followingRef(String uid) =>
      _usersRef().doc(uid).collection('following');

  /// Gets current follow relationship status between current user and target user
  /// Returns: 'following' | 'requested' | 'none'
  Future<String> getFollowStatus({
    required String currentUid,
    required String targetUid,
  }) async {
    // 1. Check if already following
    final followingDoc = await _followingRef(currentUid).doc(targetUid).get();
    if (followingDoc.exists) return 'following';

    // 2. Check if request is pending
    final requestDoc = await _followRequestsRef(targetUid).doc(currentUid).get();
    if (requestDoc.exists && requestDoc.get('status') == 'pending') {
      return 'requested';
    }

    return 'none';
  }

  /// Sends follow request to target user
  Future<void> sendFollowRequest({
    required String currentUid,
    required String targetUid,
  }) async {
    final request = FollowRequestModel(
      requesterUid: currentUid,
      receiverUid: targetUid,
      status: 'pending',
      createdAt: DateTime.now(),
    );

    await _followRequestsRef(targetUid).doc(currentUid).set(request.toMap());
  }

  /// Cancels an existing pending follow request
  Future<void> cancelFollowRequest({
    required String currentUid,
    required String targetUid,
  }) async {
    await _followRequestsRef(targetUid).doc(currentUid).delete();
  }

  /// Accepts a follow request atomically and establishes follower/following relationship
  Future<void> acceptFollowRequest({
    required UserModel currentUser,
    required UserModel requesterUser,
  }) async {
    final batch = _firestore.batch();

    // 1. Add requester to currentUser's followers
    final followerDoc = _followersRef(currentUser.uid).doc(requesterUser.uid);
    batch.set(followerDoc, {
      'uid': requesterUser.uid,
      'username': requesterUser.username,
      'displayName': requesterUser.displayName,
      'photoUrl': requesterUser.photoUrl,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // 2. Add currentUser to requester's following
    final followingDoc = _followingRef(requesterUser.uid).doc(currentUser.uid);
    batch.set(followingDoc, {
      'uid': currentUser.uid,
      'username': currentUser.username,
      'displayName': currentUser.displayName,
      'photoUrl': currentUser.photoUrl,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // 3. Delete the pending follow request
    final requestDoc = _followRequestsRef(currentUser.uid).doc(requesterUser.uid);
    batch.delete(requestDoc);

    // 4. Also register as mutual contacts so messaging is seamless
    final contactA = _usersRef().doc(currentUser.uid).collection(AppConstants.contactsCollection).doc(requesterUser.uid);
    final contactB = _usersRef().doc(requesterUser.uid).collection(AppConstants.contactsCollection).doc(currentUser.uid);
    batch.set(contactA, {
      'contactUid': requesterUser.uid,
      'username': requesterUser.username,
      'displayName': requesterUser.displayName,
      'photoUrl': requesterUser.photoUrl,
      'addedAt': FieldValue.serverTimestamp(),
    });
    batch.set(contactB, {
      'contactUid': currentUser.uid,
      'username': currentUser.username,
      'displayName': currentUser.displayName,
      'photoUrl': currentUser.photoUrl,
      'addedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  /// Rejects a pending follow request
  Future<void> rejectFollowRequest({
    required String currentUid,
    required String requesterUid,
  }) async {
    await _followRequestsRef(currentUid).doc(requesterUid).delete();
  }

  /// Unfollows target user and removes mutual relationship
  Future<void> unfollowUser({
    required String currentUid,
    required String targetUid,
  }) async {
    final batch = _firestore.batch();
    batch.delete(_followingRef(currentUid).doc(targetUid));
    batch.delete(_followersRef(targetUid).doc(currentUid));
    await batch.commit();
  }

  /// Stream of pending follow requests for the current user
  Stream<List<FollowRequestModel>> getPendingRequestsStream(String currentUid) {
    return _followRequestsRef(currentUid)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => FollowRequestModel.fromFirestore(doc)).toList());
  }

  /// Stream of followers list
  Stream<List<FollowRelationModel>> getFollowersStream(String uid) {
    return _followersRef(uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => FollowRelationModel.fromFirestore(doc)).toList());
  }

  /// Stream of following list
  Stream<List<FollowRelationModel>> getFollowingStream(String uid) {
    return _followingRef(uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => FollowRelationModel.fromFirestore(doc)).toList());
  }
}
