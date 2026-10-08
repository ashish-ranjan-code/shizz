import 'package:cloud_firestore/cloud_firestore.dart';

class ChatModel {
  final String chatId;
  final List<String> participants;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final String? lastSenderId;
  final Map<String, int> unreadCounts;
  final DateTime createdAt;

  ChatModel({
    required this.chatId,
    required this.participants,
    this.lastMessage,
    this.lastMessageTime,
    this.lastSenderId,
    this.unreadCounts = const {},
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'chatId': chatId,
      'participants': participants,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime != null ? Timestamp.fromDate(lastMessageTime!) : null,
      'lastSenderId': lastSenderId,
      'unreadCounts': unreadCounts,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory ChatModel.fromMap(Map<String, dynamic> map, {String? documentId}) {
    DateTime parseTimestamp(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    Map<String, int> parseUnread(dynamic mapVal) {
      if (mapVal is Map) {
        return mapVal.map((key, value) => MapEntry(key.toString(), (value as num).toInt()));
      }
      return {};
    }

    return ChatModel(
      chatId: documentId ?? (map['chatId'] ?? ''),
      participants: List<String>.from(map['participants'] ?? []),
      lastMessage: map['lastMessage'],
      lastMessageTime: map['lastMessageTime'] != null
          ? parseTimestamp(map['lastMessageTime'])
          : null,
      lastSenderId: map['lastSenderId'],
      unreadCounts: parseUnread(map['unreadCounts']),
      createdAt: map['createdAt'] != null
          ? parseTimestamp(map['createdAt'])
          : DateTime.now(),
    );
  }

  factory ChatModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ChatModel.fromMap(data, documentId: doc.id);
  }

  int getUnreadForUser(String uid) {
    return unreadCounts[uid] ?? 0;
  }
}
