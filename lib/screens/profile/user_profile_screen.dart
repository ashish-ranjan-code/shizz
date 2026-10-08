import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/follow_provider.dart';
import '../../services/user_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/helpers.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/user_avatar.dart';
import '../chat/chat_screen.dart';
import 'followers_list_screen.dart';

class UserProfileScreen extends StatefulWidget {
  final UserModel targetUser;

  const UserProfileScreen({
    super.key,
    required this.targetUser,
  });

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final _userService = UserService();
  String _followStatus = 'none'; // 'none', 'requested', 'following'
  bool _isLoadingStatus = true;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final followProvider = Provider.of<FollowProvider>(context, listen: false);
    final currentUid = authProvider.firebaseUser?.uid;

    if (currentUid == null || currentUid == widget.targetUser.uid) {
      setState(() => _isLoadingStatus = false);
      return;
    }

    final status = await followProvider.getStatus(currentUid, widget.targetUser.uid);
    if (mounted) {
      setState(() {
        _followStatus = status;
        _isLoadingStatus = false;
      });
    }
  }

  Future<void> _handleFollowToggle() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final followProvider = Provider.of<FollowProvider>(context, listen: false);
    final currentUid = authProvider.firebaseUser?.uid;
    if (currentUid == null) return;

    if (_followStatus == 'none') {
      await followProvider.sendRequest(currentUid, widget.targetUser.uid);
      setState(() => _followStatus = 'requested');
    } else if (_followStatus == 'requested') {
      await followProvider.cancelRequest(currentUid, widget.targetUser.uid);
      setState(() => _followStatus = 'none');
    } else if (_followStatus == 'following') {
      // Confirm unfollow
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppTheme.darkSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppTheme.glassBorder),
          ),
          title: const Text('Unfollow User', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: Text('Unfollow @${widget.targetUser.username}?', style: const TextStyle(color: AppTheme.textSecondary)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.rose),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Unfollow', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );

      if (confirm == true) {
        await followProvider.unfollow(currentUid, widget.targetUser.uid);
        setState(() => _followStatus = 'none');
      }
    }
  }

  Future<void> _openChat() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final currentUid = authProvider.firebaseUser?.uid;
    if (currentUid == null) return;

    final chat = await chatProvider.initializeChat(
      currentUid: currentUid,
      otherUid: widget.targetUser.uid,
    );

    if (chat != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            chatId: chat.chatId,
            recipientUser: widget.targetUser,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final followProvider = Provider.of<FollowProvider>(context);
    final isSelf = authProvider.firebaseUser?.uid == widget.targetUser.uid;

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: Text(
          '@${widget.targetUser.username}',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<UserModel?>(
        stream: _userService.getUserStream(widget.targetUser.uid),
        initialData: widget.targetUser,
        builder: (context, snapshot) {
          final liveUser = snapshot.data ?? widget.targetUser;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Column(
              children: [
                // Avatar + Stats row
                Row(
                  children: [
                    UserAvatar(
                      name: liveUser.displayName,
                      photoUrl: liveUser.photoUrl,
                      radius: 40,
                      isOnline: liveUser.isOnline,
                      showOnlineBadge: true,
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          // Followers Count Stream
                          StreamBuilder(
                            stream: followProvider.getFollowers(liveUser.uid),
                            builder: (context, snap) {
                              final count = (snap.data as List?)?.length ?? 0;
                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => FollowersListScreen(
                                        userId: liveUser.uid,
                                        title: 'Followers',
                                        isFollowers: true,
                                      ),
                                    ),
                                  );
                                },
                                child: Column(
                                  children: [
                                    Text('$count', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 2),
                                    const Text('Followers', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                                  ],
                                ),
                              );
                            },
                          ),
                          // Following Count Stream
                          StreamBuilder(
                            stream: followProvider.getFollowing(liveUser.uid),
                            builder: (context, snap) {
                              final count = (snap.data as List?)?.length ?? 0;
                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => FollowersListScreen(
                                        userId: liveUser.uid,
                                        title: 'Following',
                                        isFollowers: false,
                                      ),
                                    ),
                                  );
                                },
                                child: Column(
                                  children: [
                                    Text('$count', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 2),
                                    const Text('Following', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Name and Bio
                Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        liveUser.displayName,
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        liveUser.bio ?? 'Hey there! I am using Shizz.',
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.circle,
                            size: 9,
                            color: liveUser.isOnline ? AppTheme.emerald : AppTheme.textMuted,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            Helpers.formatPresence(isOnline: liveUser.isOnline, lastSeen: liveUser.lastSeen),
                            style: TextStyle(
                              color: liveUser.isOnline ? AppTheme.emerald : AppTheme.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Action Buttons
                if (!isSelf) ...[
                  Row(
                    children: [
                      Expanded(
                        child: _isLoadingStatus
                            ? const SizedBox(
                                height: 42,
                                child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary)),
                              )
                            : ElevatedButton(
                                onPressed: _handleFollowToggle,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _followStatus == 'following'
                                      ? AppTheme.glassWhiteMedium
                                      : _followStatus == 'requested'
                                      ? AppTheme.cyan.withOpacity(0.2)
                                      : AppTheme.primary,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                child: Text(
                                  _followStatus == 'following'
                                      ? 'Following'
                                      : _followStatus == 'requested'
                                      ? 'Requested'
                                      : 'Follow',
                                  style: TextStyle(
                                    color: _followStatus == 'requested' ? AppTheme.cyan : Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _openChat,
                          icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16, color: Colors.white),
                          label: const Text('Message', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppTheme.glassBorder),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
