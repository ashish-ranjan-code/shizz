import 'dart:io';
import 'package:flutter/material.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';
import '../services/chat_service.dart';

class ChatProvider with ChangeNotifier {
  final ChatService _chatService = ChatService();

  ChatModel? _activeChat;
  bool _isSending = false;
  bool _isUploadingAttachment = false;
  String? _chatError;

  ChatModel? get activeChat => _activeChat;
  bool get isSending => _isSending;
  bool get isUploadingAttachment => _isUploadingAttachment;
  String? get chatError => _chatError;

  Stream<List<ChatModel>> getUserChats(String currentUid) {
    return _chatService.getUserChatsStream(currentUid);
  }

  Stream<List<MessageModel>> getMessages(String chatId) {
    return _chatService.getMessagesStream(chatId);
  }

  Future<ChatModel?> initializeChat({
    required String currentUid,
    required String otherUid,
  }) async {
    try {
      final chat = await _chatService.getOrCreateChat(
        currentUid: currentUid,
        otherUid: otherUid,
      );
      _activeChat = chat;
      notifyListeners();
      return chat;
    } catch (e) {
      _chatError = 'Failed to load conversation: $e';
      notifyListeners();
      return null;
    }
  }

  Future<bool> sendMessage({
    required String chatId,
    required String senderId,
    required String receiverId,
    required String text,
  }) async {
    if (text.trim().isEmpty) return false;

    _isSending = true;
    _chatError = null;
    notifyListeners();

    try {
      await _chatService.sendMessage(
        chatId: chatId,
        senderId: senderId,
        receiverId: receiverId,
        text: text,
      );
      _isSending = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isSending = false;
      _chatError = 'Failed to send message: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> sendImageAttachment({
    required String chatId,
    required String senderId,
    required String receiverId,
    required File imageFile,
    String? caption,
  }) async {
    _isUploadingAttachment = true;
    _chatError = null;
    notifyListeners();

    try {
      await _chatService.sendImageAttachment(
        chatId: chatId,
        senderId: senderId,
        receiverId: receiverId,
        imageFile: imageFile,
        caption: caption,
      );
      _isUploadingAttachment = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isUploadingAttachment = false;
      _chatError = 'Failed to upload and send image: $e';
      notifyListeners();
      return false;
    }
  }

  Future<void> markAsRead({
    required String chatId,
    required String currentUid,
  }) async {
    await _chatService.markChatAsRead(
      chatId: chatId,
      currentUid: currentUid,
    );
  }

  void clearActiveChat() {
    _activeChat = null;
    _chatError = null;
    notifyListeners();
  }
}
