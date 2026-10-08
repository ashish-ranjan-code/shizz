import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/chat_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/user_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/helpers.dart';
import '../../widgets/bottom_nav.dart';
import '../../widgets/chat_tile.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/search_bar.dart';
import '../chat/chat_screen.dart';
import '../contacts/contacts_screen.dart';
import '../contacts/new_contact_screen.dart';
import '../profile/profile_screen.dart';
import '../auth/choose_username_screen.dart';
import '../auth/login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _currentIndex = 0;
  final _searchController = TextEditingController();
  final _userService = UserService();
  String _searchFilter = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (!authProvider.isAuthenticated) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      } else if (authProvider.currentUserModel != null &&
          authProvider.currentUserModel!.username.isEmpty) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const ChooseUsernameScreen()),
          (route) => false,
        );
      }
    });
    _updateOnlineStatus(true);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _updateOnlineStatus(true);
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      _updateOnlineStatus(false);
    }
  }

  void _updateOnlineStatus(bool isOnline) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (authProvider.firebaseUser != null) {
      userProvider.setPresence(authProvider.firebaseUser!.uid, isOnline);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUid = authProvider.firebaseUser?.uid ?? '';

    return Scaffold(
      backgroundColor: AppTheme.background,
      extendBody: true,
      body: Stack(
        children: [
          // Ambient background glow
          Positioned(
            top: -100,
            left: -80,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primary.withOpacity(0.22),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 110, sigmaY: 110),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            right: -60,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.cyan.withOpacity(0.18),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),

          // Tab content
          IndexedStack(
            index: _currentIndex,
            children: [
              _buildChatsTab(currentUid),
              const ContactsScreen(),
              const ProfileScreen(),
            ],
          ),
        ],
      ),

      // Floating Action Button on Chats Tab
      floatingActionButton: _currentIndex == 0
          ? Container(
              decoration: BoxDecoration(
                gradient: AppTheme.liquidPrimaryGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withOpacity(0.5),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: FloatingActionButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const NewContactScreen()),
                  );
                },
                backgroundColor: Colors.transparent,
                elevation: 0,
                child: const Icon(Icons.add_comment_rounded, color: Colors.white, size: 26),
              ),
            )
          : null,

      bottomNavigationBar: ShizzBottomNav(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }

  Widget _buildChatsTab(String currentUid) {
    final chatProvider = Provider.of<ChatProvider>(context);

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          // Header Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Messages',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Direct messages',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const NewContactScreen()),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.glassWhiteLow,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.glassBorder),
                    ),
                    child: const Icon(
                      Icons.person_add_alt_1_rounded,
                      color: AppTheme.cyan,
                      size: 20,
                    ),
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
              hintText: 'Search chats...',
              onChanged: (val) {
                setState(() {
                  _searchFilter = val.trim().toLowerCase();
                });
              },
            ),
          ),

          // Conversations Stream
          Expanded(
            child: StreamBuilder<List<ChatModel>>(
              stream: chatProvider.getUserChats(currentUid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Text(
                        'Failed to load chats: ${snapshot.error}',
                        style: const TextStyle(color: AppTheme.rose),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                final chats = snapshot.data ?? [];

                if (chats.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
                  itemCount: chats.length,
                  itemBuilder: (context, index) {
                    final chat = chats[index];
                    final otherUid = Helpers.getOtherParticipantUid(chat.participants, currentUid);

                    return FutureBuilder<UserModel?>(
                      future: _userService.getUserProfile(otherUid),
                      builder: (context, userSnap) {
                        if (!userSnap.hasData || userSnap.data == null) {
                          return const SizedBox.shrink();
                        }
                        final otherUser = userSnap.data!;

                        // Filter check
                        if (_searchFilter.isNotEmpty) {
                          final matchName = otherUser.displayName.toLowerCase().contains(_searchFilter);
                          final matchUser = otherUser.username.toLowerCase().contains(_searchFilter);
                          final matchLast = (chat.lastMessage ?? '').toLowerCase().contains(_searchFilter);
                          if (!matchName && !matchUser && !matchLast) {
                            return const SizedBox.shrink();
                          }
                        }

                        return ChatTile(
                          chat: chat,
                          otherUser: otherUser,
                          currentUid: currentUid,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChatScreen(
                                  chatId: chat.chatId,
                                  recipientUser: otherUser,
                                ),
                              ),
                            );
                          },
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

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: GlassCard(
          borderRadius: 24,
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primary.withOpacity(0.15),
                ),
                child: const Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: 44,
                  color: AppTheme.primaryLight,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'No Conversations Yet',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Search for users by username to add contacts and start chatting.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const NewContactScreen()),
                  );
                },
                icon: const Icon(Icons.person_search_rounded, size: 18, color: Colors.white),
                label: const Text('Find People', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
