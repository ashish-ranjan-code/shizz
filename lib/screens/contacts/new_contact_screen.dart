import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/contact_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/helpers.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/search_bar.dart';
import '../../widgets/user_avatar.dart';
import '../chat/chat_screen.dart';
import '../profile/user_profile_screen.dart';

class NewContactScreen extends StatefulWidget {
  const NewContactScreen({super.key});

  @override
  State<NewContactScreen> createState() => _NewContactScreenState();
}

class _NewContactScreenState extends State<NewContactScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final contactProvider = Provider.of<ContactProvider>(context, listen: false);
    final currentUid = authProvider.firebaseUser?.uid ?? '';

    contactProvider.searchUsers(query: query, currentUid: currentUid);
  }

  void _openUserProfileModal(UserModel user, bool isAlreadyContact) {
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
              name: user.displayName,
              photoUrl: user.photoUrl,
              radius: 44,
              isOnline: user.isOnline,
              showOnlineBadge: true,
            ),
            const SizedBox(height: 14),
            Text(
              user.displayName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '@${user.username}',
              style: const TextStyle(
                color: AppTheme.cyan,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              user.bio ?? 'Hey there! I am using Shizz.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
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
                    color: user.isOnline ? AppTheme.emerald : AppTheme.textMuted,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    Helpers.formatPresence(
                      isOnline: user.isOnline,
                      lastSeen: user.lastSeen,
                    ),
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _startDirectChat(user);
                    },
                    icon: const Icon(Icons.chat_bubble_rounded, size: 16, color: Colors.white),
                    label: const Text('Send Message', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                if (!isAlreadyContact) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _addContactAndNotify(user);
                      },
                      icon: const Icon(Icons.person_add_rounded, size: 16, color: Colors.white),
                      label: const Text('Add Contact', style: TextStyle(color: Colors.white)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppTheme.glassBorder),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addContactAndNotify(UserModel targetUser) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final contactProvider = Provider.of<ContactProvider>(context, listen: false);

    final success = await contactProvider.addContact(
      currentUid: authProvider.firebaseUser!.uid,
      targetUser: targetUser,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Added ${targetUser.displayName} to contacts'
                : 'Failed to add contact',
          ),
          backgroundColor: success ? AppTheme.emerald : AppTheme.rose,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _startDirectChat(UserModel targetUser) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);

    final chat = await chatProvider.initializeChat(
      currentUid: authProvider.firebaseUser!.uid,
      otherUid: targetUser.uid,
    );

    if (chat != null && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            chatId: chat.chatId,
            recipientUser: targetUser,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final contactProvider = Provider.of<ContactProvider>(context);
    final currentUid = authProvider.firebaseUser?.uid ?? '';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Add Contact', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // Ambient Glow
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primary.withOpacity(0.25),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 90, sigmaY: 90),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),

          Column(
            children: [
              // Search Input
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: ShizzSearchBar(
                  controller: _searchController,
                  autofocus: true,
                  hintText: 'Enter username (e.g. sarah_sky)...',
                  onChanged: _onSearchChanged,
                ),
              ),

              // Search results or prompt
              Expanded(
                child: Builder(
                  builder: (context) {
                    if (contactProvider.isSearching) {
                      return const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
                        ),
                      );
                    }

                    if (_searchController.text.trim().isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.manage_search_rounded,
                              size: 64,
                              color: Colors.white.withOpacity(0.3),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Search by Unique Username',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 40.0),
                              child: Text(
                                'Type an exact or partial username to find anyone registered on Shizz.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    if (contactProvider.searchResults.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.person_off_outlined,
                              size: 56,
                              color: Colors.white.withOpacity(0.3),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'No user found matching "${_searchController.text}"',
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      itemCount: contactProvider.searchResults.length,
                      itemBuilder: (context, index) {
                        final targetUser = contactProvider.searchResults[index];

                        return FutureBuilder<bool>(
                          future: contactProvider.isContact(
                            currentUid: currentUid,
                            contactUid: targetUser.uid,
                          ),
                          builder: (context, isContactSnap) {
                            final alreadyAdded = isContactSnap.data ?? false;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: GlassCard(
                                borderRadius: 24,
                                padding: const EdgeInsets.all(16),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => UserProfileScreen(targetUser: targetUser),
                                    ),
                                  );
                                },
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        UserAvatar(
                                          name: targetUser.displayName,
                                          photoUrl: targetUser.photoUrl,
                                          radius: 26,
                                          isOnline: targetUser.isOnline,
                                          showOnlineBadge: true,
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                targetUser.displayName,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                '@${targetUser.username}',
                                                style: const TextStyle(
                                                  color: AppTheme.cyan,
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.info_outline_rounded, color: AppTheme.textSecondary, size: 20),
                                          onPressed: () => _openUserProfileModal(targetUser, alreadyAdded),
                                          tooltip: 'View Profile',
                                        ),
                                      ],
                                    ),
                                    if (targetUser.bio != null && targetUser.bio!.isNotEmpty) ...[
                                      const SizedBox(height: 12),
                                      Text(
                                        targetUser.bio!,
                                        style: const TextStyle(
                                          color: AppTheme.textSecondary,
                                          fontSize: 13,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 16),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: OutlinedButton.icon(
                                            onPressed: alreadyAdded
                                                ? null
                                                : () => _addContactAndNotify(targetUser),
                                            icon: Icon(
                                              alreadyAdded ? Icons.check : Icons.person_add_rounded,
                                              size: 16,
                                              color: alreadyAdded ? AppTheme.emerald : Colors.white,
                                            ),
                                            label: Text(
                                              alreadyAdded ? 'In Contacts' : 'Add Contact',
                                              style: TextStyle(
                                                color: alreadyAdded ? AppTheme.emerald : Colors.white,
                                                fontSize: 13,
                                              ),
                                            ),
                                            style: OutlinedButton.styleFrom(
                                              side: BorderSide(
                                                color: alreadyAdded
                                                    ? AppTheme.emerald.withOpacity(0.5)
                                                    : AppTheme.glassBorder,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(14),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            onPressed: () => _startDirectChat(targetUser),
                                            icon: const Icon(Icons.chat_bubble_rounded, size: 16, color: Colors.white),
                                            label: const Text('Chat', style: TextStyle(color: Colors.white, fontSize: 13)),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppTheme.primary,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(14),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
