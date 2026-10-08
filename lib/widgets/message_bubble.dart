import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../models/message_model.dart';
import '../theme/app_theme.dart';
import '../utils/helpers.dart';

class MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
  });

  void _openFullScreenImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.9),
      builder: (context) => Stack(
        children: [
          Center(
            child: InteractiveViewer(
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.contain,
                placeholder: (context, url) => const Center(
                  child: CircularProgressIndicator(color: AppTheme.primary),
                ),
                errorWidget: (context, url, error) => const Icon(
                  Icons.broken_image_rounded,
                  color: Colors.white,
                  size: 64,
                ),
              ),
            ),
          ),
          Positioned(
            top: 40,
            right: 20,
            child: IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final maxWidth = MediaQuery.of(context).size.width * 0.75;
    final isImage = message.type == 'image';

    String imageUrl = '';
    String? caption;

    if (isImage) {
      if (message.text.contains('||')) {
        final parts = message.text.split('||');
        imageUrl = parts[0];
        caption = parts[1];
      } else {
        imageUrl = message.text;
      }
    }

    final bubbleBorderRadius = BorderRadius.only(
      topLeft: const Radius.circular(20),
      topRight: const Radius.circular(20),
      bottomLeft: isMe ? const Radius.circular(20) : const Radius.circular(4),
      bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(20),
    );

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 12.0),
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: ClipRRect(
          borderRadius: bubbleBorderRadius,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding: isImage ? const EdgeInsets.all(6.0) : const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
              decoration: BoxDecoration(
                gradient: isMe
                    ? AppTheme.sentBubbleGradient
                    : AppTheme.receivedBubbleGradient,
                borderRadius: bubbleBorderRadius,
                border: Border.all(
                  color: isMe
                      ? Colors.white.withOpacity(0.2)
                      : AppTheme.glassBorder,
                  width: 1.0,
                ),
                boxShadow: isMe
                    ? [
                        BoxShadow(
                          color: AppTheme.primary.withOpacity(0.25),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                crossAxisAlignment:
                    isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isImage) ...[
                    GestureDetector(
                      onTap: () => _openFullScreenImage(context, imageUrl),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: CachedNetworkImage(
                          imageUrl: imageUrl,
                          width: double.infinity,
                          height: 200,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            height: 200,
                            color: Colors.black26,
                            child: const Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppTheme.cyan,
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            height: 120,
                            color: Colors.black26,
                            child: const Center(
                              child: Icon(Icons.broken_image_rounded, color: Colors.white54, size: 36),
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (caption != null && caption.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: Text(
                          caption,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ] else ...[
                    Text(
                      message.text,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 15,
                        height: 1.35,
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          Helpers.formatMessageTime(message.timestamp),
                          style: TextStyle(
                            color: isMe
                                ? Colors.white.withOpacity(0.7)
                                : AppTheme.textMuted,
                            fontSize: 11,
                          ),
                        ),
                        if (isMe) ...[
                          const SizedBox(width: 4),
                          Icon(
                            message.isRead ? Icons.done_all_rounded : Icons.check_rounded,
                            size: 14,
                            color: message.isRead
                                ? AppTheme.cyan
                                : Colors.white.withOpacity(0.7),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
