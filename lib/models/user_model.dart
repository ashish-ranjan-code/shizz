import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String username;
  final String displayName;
  final String? photoUrl;
  final String? bio;
  final DateTime createdAt;
  final DateTime? lastSeen;
  final bool isOnline;

  UserModel({
    required this.uid,
    required this.email,
    required this.username,
    required this.displayName,
    this.photoUrl,
    this.bio,
    required this.createdAt,
    this.lastSeen,
    this.isOnline = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'username': username.toLowerCase(),
      'displayName': displayName,
      'photoUrl': photoUrl,
      'bio': bio ?? 'Hey there! I am using Shizz.',
      'createdAt': Timestamp.fromDate(createdAt),
      'lastSeen': lastSeen != null ? Timestamp.fromDate(lastSeen!) : null,
      'isOnline': isOnline,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map, {String? documentId}) {
    DateTime parseTimestamp(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return UserModel(
      uid: documentId ?? (map['uid'] ?? ''),
      email: map['email'] ?? '',
      username: map['username'] ?? '',
      displayName: map['displayName'] ?? (map['username'] ?? 'User'),
      photoUrl: map['photoUrl'],
      bio: map['bio'] ?? 'Hey there! I am using Shizz.',
      createdAt: map['createdAt'] != null
          ? parseTimestamp(map['createdAt'])
          : DateTime.now(),
      lastSeen: map['lastSeen'] != null ? parseTimestamp(map['lastSeen']) : null,
      isOnline: map['isOnline'] == true,
    );
  }

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return UserModel.fromMap(data, documentId: doc.id);
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? username,
    String? displayName,
    String? photoUrl,
    String? bio,
    DateTime? createdAt,
    DateTime? lastSeen,
    bool? isOnline,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      bio: bio ?? this.bio,
      createdAt: createdAt ?? this.createdAt,
      lastSeen: lastSeen ?? this.lastSeen,
      isOnline: isOnline ?? this.isOnline,
    );
  }
}
