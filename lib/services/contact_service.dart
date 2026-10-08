import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/contact_model.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';

class ContactService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference _contactsRef(String uid) => _firestore
      .collection(AppConstants.usersCollection)
      .doc(uid)
      .collection(AppConstants.contactsCollection);

  /// Real-time stream of all saved contacts for the user
  Stream<List<ContactModel>> getContactsStream(String currentUid) {
    return _contactsRef(currentUid)
        .orderBy('addedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ContactModel.fromFirestore(doc))
          .toList();
    });
  }

  /// Adds another user into current user's contacts
  Future<void> addContact({
    required String currentUid,
    required UserModel targetUser,
  }) async {
    final contact = ContactModel(
      contactUid: targetUser.uid,
      username: targetUser.username,
      displayName: targetUser.displayName,
      photoUrl: targetUser.photoUrl,
      addedAt: DateTime.now(),
    );

    await _contactsRef(currentUid).doc(targetUser.uid).set(contact.toMap());
  }

  /// Removes a contact from the current user's contact list
  Future<void> removeContact({
    required String currentUid,
    required String contactUid,
  }) async {
    await _contactsRef(currentUid).doc(contactUid).delete();
  }

  /// Checks if another user is already in current user's contacts
  Future<bool> isContact({
    required String currentUid,
    required String contactUid,
  }) async {
    final doc = await _contactsRef(currentUid).doc(contactUid).get();
    return doc.exists;
  }
}
