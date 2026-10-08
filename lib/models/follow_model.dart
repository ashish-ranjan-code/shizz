import 'package:cloud_firestore/cloud_firestore.dart';

class FollowRequestModel {
  final String requesterUid;
  final String receiverUid;
  final String status; // 'pending', 'accepted', 'rejected'
  final DateTime createdAt;

  FollowRequestModel({
    required this.requesterUid,
    required this.receiverUid,
    this.status = 'pending',
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'requesterUid': requesterUid,
      'receiverUid': receiverUid,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory FollowRequestModel.fromMap(Map<String, dynamic> map, {String? docId}) {
    DateTime parseTime(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return FollowRequestModel(
      requesterUid: map['requesterUid'] ?? docId ?? '',
      receiverUid: map['receiverUid'] ?? '',
      status: map['status'] ?? 'pending',
      createdAt: map['createdAt'] != null ? parseTime(map['createdAt']) : DateTime.now(),
    );
  }

  factory FollowRequestModel.fromFirestore(DocumentSnapshot doc) {
    return FollowRequestModel.fromMap(
      doc.data() as Map<String, dynamic>? ?? {},
      docId: doc.id,
    );
  }
}

class FollowRelationModel {
  final String uid;
  final String username;
  final String displayName;
  final String? photoUrl;
  final DateTime createdAt;

  FollowRelationModel({
    required this.uid,
    required this.username,
    required this.displayName,
    this.photoUrl,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'username': username,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory FollowRelationModel.fromMap(Map<String, dynamic> map, {String? docId}) {
    DateTime parseTime(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return FollowRelationModel(
      uid: map['uid'] ?? docId ?? '',
      username: map['username'] ?? '',
      displayName: map['displayName'] ?? '',
      photoUrl: map['photoUrl'],
      createdAt: map['createdAt'] != null ? parseTime(map['createdAt']) : DateTime.now(),
    );
  }

  factory FollowRelationModel.fromFirestore(DocumentSnapshot doc) {
    return FollowRelationModel.fromMap(
      doc.data() as Map<String, dynamic>? ?? {},
      docId: doc.id,
    );
  }
}
