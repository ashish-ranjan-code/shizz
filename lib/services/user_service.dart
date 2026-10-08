import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _usersRef =>
      _firestore.collection(AppConstants.usersCollection);

  CollectionReference get _usernamesRef =>
      _firestore.collection(AppConstants.usernamesCollection);

  /// Checks if a given username is available (not already taken)
  Future<bool> isUsernameAvailable(String username) async {
    final clean = username.trim().toLowerCase();
    final doc = await _usernamesRef.doc(clean).get();
    return !doc.exists;
  }

  /// Creates user profile document in Firestore and claims unique username
  Future<void> createUserProfile(UserModel user) async {
    final batch = _firestore.batch();
    final userDocRef = _usersRef.doc(user.uid);
    final usernameDocRef = _usernamesRef.doc(user.username.toLowerCase());

    batch.set(userDocRef, user.toMap());
    batch.set(usernameDocRef, {
      'uid': user.uid,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  /// Gets single user profile by UID
  Future<UserModel?> getUserProfile(String uid) async {
    final doc = await _usersRef.doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  /// Stream of user profile updates
  Stream<UserModel?> getUserStream(String uid) {
    return _usersRef.doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromFirestore(doc);
    });
  }

  /// Updates profile details (displayName, bio, photoUrl, and optionally username)
  Future<void> updateProfile({
    required String uid,
    String? displayName,
    String? bio,
    String? photoUrl,
    String? currentUsername,
    String? newUsername,
  }) async {
    final Map<String, dynamic> updates = {};
    if (displayName != null) updates['displayName'] = displayName.trim();
    if (bio != null) updates['bio'] = bio.trim();
    if (photoUrl != null) updates['photoUrl'] = photoUrl;

    // Handle username update if changing
    if (newUsername != null &&
        currentUsername != null &&
        newUsername.toLowerCase().trim() != currentUsername.toLowerCase().trim()) {
      final cleanNew = newUsername.toLowerCase().trim();
      final cleanOld = currentUsername.toLowerCase().trim();

      final isAvailable = await isUsernameAvailable(cleanNew);
      if (!isAvailable) {
        throw 'Username "@$cleanNew" is already taken. Please choose another.';
      }

      final batch = _firestore.batch();
      batch.set(_usernamesRef.doc(cleanNew), {
        'uid': uid,
        'createdAt': FieldValue.serverTimestamp(),
      });
      batch.delete(_usernamesRef.doc(cleanOld));

      updates['username'] = cleanNew;
      batch.update(_usersRef.doc(uid), updates);
      await batch.commit();
      return;
    }

    if (updates.isNotEmpty) {
      await _usersRef.doc(uid).update(updates);
    }
  }

  /// Updates user presence status (online/offline + lastSeen)
  Future<void> updatePresence({
    required String uid,
    required bool isOnline,
  }) async {
    try {
      await _usersRef.doc(uid).update({
        'isOnline': isOnline,
        'lastSeen': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Ignore background presence failures silently
    }
  }

  /// Searches users by username prefix (e.g. "alex"), excluding current user
  Future<List<UserModel>> searchUsersByUsername({
    required String query,
    required String currentUid,
  }) async {
    final clean = query.trim().toLowerCase();
    if (clean.isEmpty) return [];

    final snapshot = await _usersRef
        .where('username', isGreaterThanOrEqualTo: clean)
        .where('username', isLessThanOrEqualTo: '$clean\uf8ff')
        .limit(20)
        .get();

    return snapshot.docs
        .map((doc) => UserModel.fromFirestore(doc))
        .where((user) => user.uid != currentUid)
        .toList();
  }
}
