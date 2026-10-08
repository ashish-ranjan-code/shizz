import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/follow_model.dart';
import '../../models/user_model.dart';
import '../../providers/follow_provider.dart';
import '../../services/user_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/user_avatar.dart';
import 'user_profile_screen.dart';

class FollowersListScreen extends StatelessWidget {
  final String userId;
  final String title;
  final bool isFollowers;

  const FollowersListScreen({
    super.key,
    required this.userId,
    required this.title,
    required this.isFollowers,
  });

  @override
  Widget build(BuildContext context) {
    final followProvider = Provider.of<FollowProvider>(context);
    final userService = UserService();

    final stream = isFollowers
        ? followProvider.getFollowers(userId)
        : followProvider.getFollowing(userId);

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<List<FollowRelationModel>>(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
          }

          final list = snapshot.data ?? [];

          if (list.isEmpty) {
            return Center(
              child: Text(
                'No ${title.toLowerCase()} yet',
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 15),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final item = list[index];

              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: GlassCard(
                  borderRadius: 18,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  onTap: () async {
                    final fullUser = await userService.getUserProfile(item.uid);
                    if (fullUser != null && context.mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => UserProfileScreen(targetUser: fullUser),
                        ),
                      );
                    }
                  },
                  child: Row(
                    children: [
                      UserAvatar(
                        name: item.displayName,
                        photoUrl: item.photoUrl,
                        radius: 22,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.displayName,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            Text(
                              '@${item.username}',
                              style: const TextStyle(color: AppTheme.cyan, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted, size: 20),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
