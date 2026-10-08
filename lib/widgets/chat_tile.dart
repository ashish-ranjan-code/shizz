import 'package:flutter/material.dart';
import '../models/chat_model.dart';
import '../models/user_model.dart';
import '../theme/app_theme.dart';
import '../utils/helpers.dart';
import 'glass_card.dart';
import 'user_avatar.dart';

class ChatTile extends StatelessWidget {
  final ChatModel chat;
  final UserModel otherUser;
  final String currentUid;
  final VoidCallback onTap;

  const ChatTile({
    super.key,
    required this.chat,
    required this.otherUser,
    required this.currentUid,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final unreadCount = chat.getUnreadForUser(currentUid);
    final hasUnread = unreadCount > 0;
    final isMeSender = chat.lastSenderId == currentUid;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: GlassCard(
        borderRadius: 20,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        backgroundColor: hasUnread
            ? AppTheme.primary.withOpacity(0.08)
            : AppTheme.glassWhiteLow,
        borderColor: hasUnread
            ? AppTheme.primary.withOpacity(0.3)
            : AppTheme.glassBorder,
        onTap: onTap,
        child: Row(
          children: [
            UserAvatar(
              name: otherUser.displayName.isNotEmpty
                  ? otherUser.displayName
                  : otherUser.username,
              photoUrl: otherUser.photoUrl,
              radius: 26,
              isOnline: otherUser.isOnline,
              showOnlineBadge: true,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          otherUser.displayName.isNotEmpty
                              ? otherUser.displayName
                              : '@${otherUser.username}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        Helpers.formatChatListTime(chat.lastMessageTime),
                        style: TextStyle(
                          color: hasUnread ? AppTheme.cyan : AppTheme.textMuted,
                          fontSize: 12,
                          fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          chat.lastMessage != null
                              ? (isMeSender ? 'You: ${chat.lastMessage}' : chat.lastMessage!)
                              : 'No messages yet',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: hasUnread ? AppTheme.textPrimary : AppTheme.textSecondary,
                            fontSize: 13,
                            fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
                          ),
                        ),
                      ),
                      if (hasUnread) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            gradient: AppTheme.liquidPrimaryGradient,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primary.withOpacity(0.4),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: Text(
                            unreadCount > 99 ? '99+' : unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
