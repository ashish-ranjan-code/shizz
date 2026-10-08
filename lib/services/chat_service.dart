import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import 'storage_service.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final StorageService _storageService = StorageService();

  CollectionReference get _chatsRef =>
      _firestore.collection(AppConstants.chatsCollection);

  CollectionReference _messagesRef(String chatId) =>
      _chatsRef.doc(chatId).collection(AppConstants.messagesCollection);

  /// Retrieves or creates a 1-to-1 conversation between two users
  Future<ChatModel> getOrCreateChat({
    required String currentUid,
    required String otherUid,
  }) async {
    final chatId = Helpers.generateChatId(currentUid, otherUid);
    final chatDoc = await _chatsRef.doc(chatId).get();

    if (chatDoc.exists) {
      return ChatModel.fromFirestore(chatDoc);
    }

    // Create new conversation document
    final newChat = ChatModel(
      chatId: chatId,
      participants: [currentUid, otherUid],
      lastMessage: null,
      lastMessageTime: null,
      lastSenderId: null,
      unreadCounts: {
        currentUid: 0,
        otherUid: 0,
      },
      createdAt: DateTime.now(),
    );

    await _chatsRef.doc(chatId).set(newChat.toMap());
    return newChat;
  }

  /// Real-time stream of all conversations the user is a participant in
  Stream<List<ChatModel>> getUserChatsStream(String currentUid) {
    return _chatsRef
        .where('participants', arrayContains: currentUid)
        .snapshots()
        .map((snapshot) {
      final chats = snapshot.docs
          .map((doc) => ChatModel.fromFirestore(doc))
          .toList();

      // Sort chats by lastMessageTime descending (nulls at end)
      chats.sort((a, b) {
        if (a.lastMessageTime == null && b.lastMessageTime == null) return 0;
        if (a.lastMessageTime == null) return 1;
        if (b.lastMessageTime == null) return -1;
        return b.lastMessageTime!.compareTo(a.lastMessageTime!);
      });

      return chats;
    });
  }

  /// Real-time stream of messages in a specific chat (ordered oldest first for display)
  Stream<List<MessageModel>> getMessagesStream(String chatId) {
    return _messagesRef(chatId)
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => MessageModel.fromFirestore(doc))
          .toList();
    });
  }

  /// Sends a text message and updates parent chat metadata in a batch
  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String receiverId,
    required String text,
    String type = 'text',
  }) async {
    if (text.trim().isEmpty) return;

    final messageDocRef = _messagesRef(chatId).doc();
    final chatDocRef = _chatsRef.doc(chatId);

    final newMessage = MessageModel(
      messageId: messageDocRef.id,
      chatId: chatId,
      senderId: senderId,
      receiverId: receiverId,
      text: text.trim(),
      timestamp: DateTime.now(),
      type: type,
      isRead: false,
    );

    final batch = _firestore.batch();

    // 1. Write the new message
    batch.set(messageDocRef, newMessage.toMap());

    // 2. Update chat metadata and increment receiver's unread counter
    batch.update(chatDocRef, {
      'lastMessage': type == 'image' ? '📷 Photo' : text.trim(),
      'lastMessageTime': FieldValue.serverTimestamp(),
      'lastSenderId': senderId,
      'unreadCounts.$receiverId': FieldValue.increment(1),
      'unreadCounts.$senderId': 0,
    });

    await batch.commit();
  }

  /// Uploads image to Firebase Storage and records message in Firestore
  Future<void> sendImageAttachment({
    required String chatId,
    required String senderId,
    required String receiverId,
    required File imageFile,
    String? caption,
  }) async {
    // 1. Upload to Firebase Storage
    final imageUrl = await _storageService.uploadChatAttachment(
      chatId: chatId,
      file: imageFile,
    );

    // 2. Send message with imageUrl as payload
    final messageDocRef = _messagesRef(chatId).doc();
    final chatDocRef = _chatsRef.doc(chatId);

    final contentText = caption != null && caption.trim().isNotEmpty
        ? '$imageUrl||${caption.trim()}'
        : imageUrl;

    final newMessage = MessageModel(
      messageId: messageDocRef.id,
      chatId: chatId,
      senderId: senderId,
      receiverId: receiverId,
      text: contentText,
      timestamp: DateTime.now(),
      type: 'image',
      isRead: false,
    );

    final batch = _firestore.batch();
    batch.set(messageDocRef, newMessage.toMap());
    batch.update(chatDocRef, {
      'lastMessage': caption != null && caption.trim().isNotEmpty
          ? '📷 ${caption.trim()}'
          : '📷 Photo',
      'lastMessageTime': FieldValue.serverTimestamp(),
      'lastSenderId': senderId,
      'unreadCounts.$receiverId': FieldValue.increment(1),
      'unreadCounts.$senderId': 0,
    });

    await batch.commit();
  }

  /// Marks unread messages in the chat as read when user opens the chat
  Future<void> markChatAsRead({
    required String chatId,
    required String currentUid,
  }) async {
    try {
      // 1. Reset current user's unread counter in chat doc
      await _chatsRef.doc(chatId).update({
        'unreadCounts.$currentUid': 0,
      });

      // 2. Mark unread messages sent to current user as isRead: true
      final unreadDocs = await _messagesRef(chatId)
          .where('receiverId', isEqualTo: currentUid)
          .where('isRead', isEqualTo: false)
          .limit(50)
          .get();

      if (unreadDocs.docs.isNotEmpty) {
        final batch = _firestore.batch();
        for (var doc in unreadDocs.docs) {
          batch.update(doc.reference, {'isRead': true});
        }
        await batch.commit();
      }
    } catch (_) {
      // Ignore if offline or transient
    }
  }
}
