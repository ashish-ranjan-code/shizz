import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/follow_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/follow_provider.dart';
import '../../services/user_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/user_avatar.dart';
import 'user_profile_screen.dart';

class FollowRequestsScreen extends StatelessWidget {
  const FollowRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final followProvider = Provider.of<FollowProvider>(context);
    final userService = UserService();
    final currentUser = authProvider.currentUserModel;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: const Text('Follow Requests', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<List<FollowRequestModel>>(
        stream: followProvider.getPendingRequests(currentUser.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
          }

          final requests = snapshot.data ?? [];

          if (requests.isEmpty) {
            return const Center(
              child: Text(
                'No pending follow requests',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 15),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final req = requests[index];

              return FutureBuilder<UserModel?>(
                future: userService.getUserProfile(req.requesterUid),
                builder: (context, userSnap) {
                  final requester = userSnap.data;
                  if (requester == null) return const SizedBox.shrink();

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10.0),
                    child: GlassCard(
                      borderRadius: 20,
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => UserProfileScreen(targetUser: requester),
                                ),
                              );
                            },
                            child: UserAvatar(
                              name: requester.displayName,
                              photoUrl: requester.photoUrl,
                              radius: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  requester.displayName,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                Text(
                                  '@${requester.username}',
                                  style: const TextStyle(color: AppTheme.cyan, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          // Accept Button
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            ),
                            onPressed: () async {
                              await followProvider.acceptRequest(currentUser, requester);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Accepted @${requester.username} follow request'),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            },
                            child: const Text('Accept', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 8),
                          // Reject Button
                          IconButton(
                            icon: const Icon(Icons.close_rounded, color: AppTheme.textMuted, size: 20),
                            onPressed: () async {
                              await followProvider.rejectRequest(currentUser.uid, requester.uid);
                            },
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
    );
  }
}
