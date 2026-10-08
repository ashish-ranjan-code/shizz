import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../models/message_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../services/user_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/helpers.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/message_bubble.dart';
import '../../widgets/user_avatar.dart';
import '../auth/login_screen.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final UserModel recipientUser;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.recipientUser,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _userService = UserService();
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (!authProvider.isAuthenticated) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    });
    _markRead();
  }

  void _markRead() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      if (authProvider.firebaseUser != null) {
        chatProvider.markAsRead(
          chatId: widget.chatId,
          currentUid: authProvider.firebaseUser!.uid,
        );
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 100,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _handleSendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);

    _messageController.clear();

    await chatProvider.sendMessage(
      chatId: widget.chatId,
      senderId: authProvider.firebaseUser!.uid,
      receiverId: widget.recipientUser.uid,
      text: text,
    );

    _scrollToBottom();
  }

  Future<void> _pickAndSendImageAttachment() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);

    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1200,
    );

    if (picked != null) {
      final imageFile = File(picked.path);
      final success = await chatProvider.sendImageAttachment(
        chatId: widget.chatId,
        senderId: authProvider.firebaseUser!.uid,
        receiverId: widget.recipientUser.uid,
        imageFile: imageFile,
        caption: _messageController.text.trim().isNotEmpty
            ? _messageController.text.trim()
            : null,
      );

      if (success) {
        _messageController.clear();
        _scrollToBottom();
      } else if (mounted && chatProvider.chatError != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(chatProvider.chatError!),
            backgroundColor: AppTheme.rose,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showRecipientDetails(UserModel liveUser) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => GlassCard(
        borderRadius: 28,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            UserAvatar(
              name: liveUser.displayName,
              photoUrl: liveUser.photoUrl,
              radius: 40,
              isOnline: liveUser.isOnline,
              showOnlineBadge: true,
            ),
            const SizedBox(height: 14),
            Text(
              liveUser.displayName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '@${liveUser.username}',
              style: const TextStyle(
                color: AppTheme.cyan,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              liveUser.bio ?? 'Hey there! I am using Shizz.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.glassWhiteLow,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.glassBorder),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.circle,
                    size: 10,
                    color: liveUser.isOnline ? AppTheme.emerald : AppTheme.textMuted,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    Helpers.formatPresence(
                      isOnline: liveUser.isOnline,
                      lastSeen: liveUser.lastSeen,
                    ),
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUid = authProvider.firebaseUser?.uid ?? '';
    final chatProvider = Provider.of<ChatProvider>(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(68),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: AppBar(
              backgroundColor: AppTheme.darkSurface.withOpacity(0.7),
              leadingWidth: 40,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
              title: StreamBuilder<UserModel?>(
                stream: _userService.getUserStream(widget.recipientUser.uid),
                initialData: widget.recipientUser,
                builder: (context, snapshot) {
                  final liveRecipient = snapshot.data ?? widget.recipientUser;
                  return GestureDetector(
                    onTap: () => _showRecipientDetails(liveRecipient),
                    child: Row(
                      children: [
                        UserAvatar(
                          name: liveRecipient.displayName,
                          photoUrl: liveRecipient.photoUrl,
                          radius: 20,
                          isOnline: liveRecipient.isOnline,
                          showOnlineBadge: true,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                liveRecipient.displayName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                Helpers.formatPresence(
                                  isOnline: liveRecipient.isOnline,
                                  lastSeen: liveRecipient.lastSeen,
                                ),
                                style: TextStyle(
                                  color: liveRecipient.isOnline ? AppTheme.emerald : AppTheme.textMuted,
                                  fontSize: 12,
                                  fontWeight: liveRecipient.isOnline ? FontWeight.w600 : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.info_outline_rounded, color: AppTheme.textSecondary),
                  onPressed: () => _showRecipientDetails(widget.recipientUser),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          // Background soft ambient orbs
          Positioned(
            top: 40,
            right: -60,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primary.withOpacity(0.15),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 90, sigmaY: 90),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),
          Positioned(
            bottom: 120,
            left: -60,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.cyan.withOpacity(0.12),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 90, sigmaY: 90),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),

          // Messages & Input
          Column(
            children: [
              Expanded(
                child: StreamBuilder<List<MessageModel>>(
                  stream: chatProvider.getMessages(widget.chatId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
                        ),
                      );
                    }

                    final messages = snapshot.data ?? [];

                    if (messages.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              UserAvatar(
                                name: widget.recipientUser.displayName,
                                photoUrl: widget.recipientUser.photoUrl,
                                radius: 36,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Say hello to ${widget.recipientUser.displayName}!',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Send a message or photo to start the conversation.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppTheme.textMuted,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    // Schedule scroll to bottom on new messages
                    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final msg = messages[index];
                        final isMe = msg.senderId == currentUid;
                        return MessageBubble(message: msg, isMe: isMe);
                      },
                    );
                  },
                ),
              ),

              if (chatProvider.isUploadingAttachment)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: AppTheme.primary.withOpacity(0.1),
                  child: const Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.cyan),
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Uploading attachment to Firebase Storage...',
                        style: TextStyle(color: AppTheme.cyan, fontSize: 12),
                      ),
                    ],
                  ),
                ),

              // Bottom Input Bar with Attachment Button
              _buildInputBar(chatProvider),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar(ChatProvider chatProvider) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.darkSurface.withOpacity(0.85),
          border: const Border(
            top: BorderSide(color: AppTheme.glassBorder, width: 1.0),
          ),
        ),
        child: Row(
          children: [
            // Attachment Button (File / Image Picker)
            IconButton(
              icon: const Icon(Icons.attach_file_rounded, color: AppTheme.cyan, size: 22),
              onPressed: chatProvider.isUploadingAttachment ? null : _pickAndSendImageAttachment,
              tooltip: 'Attach Image / Photo',
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: AppTheme.glassWhiteLow,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppTheme.glassBorder),
                ),
                child: TextField(
                  controller: _messageController,
                  maxLines: 4,
                  minLines: 1,
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                  decoration: const InputDecoration(
                    hintText: 'Type a message...',
                    hintStyle: TextStyle(color: AppTheme.textMuted, fontSize: 14),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                  ),
                  onSubmitted: (_) => _handleSendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                gradient: AppTheme.liquidPrimaryGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                onPressed: _handleSendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
