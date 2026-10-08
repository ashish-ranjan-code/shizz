import 'package:cloud_firestore/cloud_firestore.dart';

class ContactModel {
  final String contactUid;
  final String username;
  final String displayName;
  final String? photoUrl;
  final DateTime addedAt;

  ContactModel({
    required this.contactUid,
    required this.username,
    required this.displayName,
    this.photoUrl,
    required this.addedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'contactUid': contactUid,
      'username': username,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'addedAt': Timestamp.fromDate(addedAt),
    };
  }

  factory ContactModel.fromMap(Map<String, dynamic> map, {String? documentId}) {
    DateTime parseTimestamp(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return ContactModel(
      contactUid: documentId ?? (map['contactUid'] ?? ''),
      username: map['username'] ?? '',
      displayName: map['displayName'] ?? '',
      photoUrl: map['photoUrl'],
      addedAt: map['addedAt'] != null
          ? parseTimestamp(map['addedAt'])
          : DateTime.now(),
    );
  }

  factory ContactModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ContactModel.fromMap(data, documentId: doc.id);
  }
}
