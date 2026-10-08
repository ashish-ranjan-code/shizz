import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/contact_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/contact_provider.dart';
import '../../services/contact_service.dart';
import '../../services/user_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/helpers.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/search_bar.dart';
import '../../widgets/user_avatar.dart';
import '../chat/chat_screen.dart';
import '../auth/login_screen.dart';
import 'new_contact_screen.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final _searchController = TextEditingController();
  final _contactService = ContactService();
  final _userService = UserService();
  String _filter = '';

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
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openContactProfile(UserModel user) {
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
              radius: 40,
              isOnline: user.isOnline,
              showOnlineBadge: true,
            ),
            const SizedBox(height: 14),
            Text(
              user.displayName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
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
                      _startChatWithUser(user);
                    },
                    icon: const Icon(Icons.chat_bubble_rounded, size: 16, color: Colors.white),
                    label: const Text('Start Chat', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _confirmDeleteContact(user.uid, user.displayName);
                    },
                    icon: const Icon(Icons.person_remove_outlined, size: 16, color: AppTheme.rose),
                    label: const Text('Remove', style: TextStyle(color: AppTheme.rose)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppTheme.rose.withOpacity(0.5)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteContact(String contactUid, String name) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final contactProvider = Provider.of<ContactProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppTheme.glassBorder),
        ),
        title: const Text('Remove Contact', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          'Are you sure you want to remove $name from your contacts?',
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.rose,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              Navigator.pop(context);
              await contactProvider.removeContact(
                currentUid: authProvider.firebaseUser!.uid,
                contactUid: contactUid,
              );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Removed $name from contacts'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Remove', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _startChatWithUser(UserModel targetUser) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);

    final chat = await chatProvider.initializeChat(
      currentUid: authProvider.firebaseUser!.uid,
      otherUid: targetUser.uid,
    );

    if (chat != null && mounted) {
      Navigator.push(
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

  Future<void> _startChatWithContact(ContactModel contact) async {
    final recipientUser = await _userService.getUserProfile(contact.contactUid);
    if (recipientUser == null) return;
    _startChatWithUser(recipientUser);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUid = authProvider.firebaseUser?.uid ?? '';

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Contacts',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Saved contacts & friends',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const NewContactScreen()),
                    );
                  },
                  icon: const Icon(Icons.add, size: 18, color: Colors.white),
                  label: const Text('Add', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                ),
              ],
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: ShizzSearchBar(
              controller: _searchController,
              hintText: 'Search contacts...',
              onChanged: (val) {
                setState(() {
                  _filter = val.trim().toLowerCase();
                });
              },
            ),
          ),

          // Contacts List
          Expanded(
            child: StreamBuilder<List<ContactModel>>(
              stream: _contactService.getContactsStream(currentUid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
                    ),
                  );
                }

                final contacts = snapshot.data ?? [];

                final filteredContacts = contacts.where((c) {
                  if (_filter.isEmpty) return true;
                  return c.displayName.toLowerCase().contains(_filter) ||
                      c.username.toLowerCase().contains(_filter);
                }).toList();

                if (filteredContacts.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.people_outline_rounded,
                            size: 54,
                            color: Colors.white.withOpacity(0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _filter.isEmpty
                                ? 'No contacts added yet'
                                : 'No matching contacts found',
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (_filter.isEmpty)
                            ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const NewContactScreen()),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.glassWhiteMedium,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: const Text('Add Your First Contact', style: TextStyle(color: Colors.white)),
                            ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
                  itemCount: filteredContacts.length,
                  itemBuilder: (context, index) {
                    final contact = filteredContacts[index];

                    return StreamBuilder<UserModel?>(
                      stream: _userService.getUserStream(contact.contactUid),
                      builder: (context, userSnap) {
                        final liveUser = userSnap.data;
                        final isOnline = liveUser?.isOnline ?? false;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10.0),
                          child: GlassCard(
                            borderRadius: 20,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            onTap: () {
                              if (liveUser != null) {
                                _openContactProfile(liveUser);
                              } else {
                                _startChatWithContact(contact);
                              }
                            },
                            child: Row(
                              children: [
                                UserAvatar(
                                  name: contact.displayName.isNotEmpty
                                      ? contact.displayName
                                      : contact.username,
                                  photoUrl: liveUser?.photoUrl ?? contact.photoUrl,
                                  radius: 24,
                                  isOnline: isOnline,
                                  showOnlineBadge: true,
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        contact.displayName.isNotEmpty
                                            ? contact.displayName
                                            : '@${contact.username}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '@${contact.username}',
                                        style: const TextStyle(
                                          color: AppTheme.textMuted,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.chat_bubble_outline_rounded,
                                    color: AppTheme.cyan,
                                    size: 20,
                                  ),
                                  onPressed: () => _startChatWithContact(contact),
                                  tooltip: 'Message',
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.person_remove_outlined,
                                    color: AppTheme.textMuted,
                                    size: 20,
                                  ),
                                  onPressed: () => _confirmDeleteContact(
                                    contact.contactUid,
                                    contact.displayName,
                                  ),
                                  tooltip: 'Remove',
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
    );
  }
}
