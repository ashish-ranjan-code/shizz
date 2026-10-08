import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/user_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/validators.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/user_avatar.dart';
import '../auth/login_screen.dart';
import '../../providers/follow_provider.dart';
import 'followers_list_screen.dart';
import 'follow_requests_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
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
  }

  Future<void> _pickAndUploadImage() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final uid = authProvider.firebaseUser?.uid;
    if (uid == null) return;

    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
      maxWidth: 800,
    );

    if (picked != null) {
      final success = await userProvider.uploadAndSetAvatar(
        uid: uid,
        imageFile: File(picked.path),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Profile photo updated successfully!'
                  : (userProvider.updateError ?? 'Failed to upload photo'),
            ),
            backgroundColor: success ? AppTheme.emerald : AppTheme.rose,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showEditProfileDialog() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final user = authProvider.currentUserModel;
    if (user == null) return;

    final nameController = TextEditingController(text: user.displayName);
    final usernameController = TextEditingController(text: user.username);
    final bioController = TextEditingController(text: user.bio);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppTheme.glassBorder),
        ),
        title: const Text('Edit Profile', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  validator: Validators.validateDisplayName,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Display Name',
                    labelStyle: const TextStyle(color: AppTheme.textSecondary),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppTheme.glassBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppTheme.primary),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: usernameController,
                  validator: Validators.validateUsername,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Username',
                    prefixText: '@',
                    prefixStyle: const TextStyle(color: AppTheme.cyan),
                    labelStyle: const TextStyle(color: AppTheme.textSecondary),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppTheme.glassBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppTheme.primary),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: bioController,
                  maxLines: 3,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Bio / Status',
                    labelStyle: const TextStyle(color: AppTheme.textSecondary),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppTheme.glassBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppTheme.primary),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(context);

              final success = await userProvider.updateProfileDetails(
                uid: user.uid,
                displayName: nameController.text.trim(),
                bio: bioController.text.trim(),
                currentUsername: user.username,
                newUsername: usernameController.text.trim(),
              );

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Profile updated successfully'
                          : (userProvider.updateError ?? 'Failed to update profile'),
                    ),
                    backgroundColor: success ? AppTheme.emerald : AppTheme.rose,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAppearanceDialog() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppTheme.glassBorder),
        ),
        title: const Text('Appearance', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildThemeOption(
              context: context,
              title: 'Dark Mode (Default)',
              subtitle: 'Deep dark obsidian with vibrant accents',
              mode: ThemeMode.dark,
              currentMode: themeProvider.themeMode,
              icon: Icons.dark_mode_rounded,
            ),
            const SizedBox(height: 10),
            _buildThemeOption(
              context: context,
              title: 'Light Mode',
              subtitle: 'Clean, elegant frosted light canvas',
              mode: ThemeMode.light,
              currentMode: themeProvider.themeMode,
              icon: Icons.light_mode_rounded,
            ),
            const SizedBox(height: 10),
            _buildThemeOption(
              context: context,
              title: 'System Default',
              subtitle: 'Automatically synchronize with device theme',
              mode: ThemeMode.system,
              currentMode: themeProvider.themeMode,
              icon: Icons.settings_brightness_rounded,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done', style: TextStyle(color: AppTheme.cyan)),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption({
    required BuildContext context,
    required String title,
    required String subtitle,
    required ThemeMode mode,
    required ThemeMode currentMode,
    required IconData icon,
  }) {
    final isSelected = currentMode == mode;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        Provider.of<ThemeProvider>(context, listen: false).setThemeMode(mode);
        Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary.withOpacity(0.18) : AppTheme.glassWhiteVeryLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.primary : AppTheme.glassBorder,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? AppTheme.cyan : AppTheme.textSecondary, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded, color: AppTheme.cyan, size: 18),
          ],
        ),
      ),
    );
  }

  void _confirmSignOut() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppTheme.glassBorder),
        ),
        title: const Text('Sign Out', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text(
          'Are you sure you want to sign out from Shizz?',
          style: TextStyle(color: AppTheme.textSecondary),
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
              await authProvider.signOut();
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            child: const Text('Sign Out', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final user = authProvider.currentUserModel;

    String themeLabel = 'Dark Mode';
    if (themeProvider.themeMode == ThemeMode.light) themeLabel = 'Light Mode';
    if (themeProvider.themeMode == ThemeMode.system) themeLabel = 'System Default';

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Profile',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: AppTheme.cyan),
                  onPressed: _showEditProfileDialog,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Profile Avatar with change photo button
            Stack(
              children: [
                UserAvatar(
                  name: user?.displayName ?? 'User',
                  photoUrl: user?.photoUrl,
                  radius: 54,
                  isOnline: true,
                  showOnlineBadge: true,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: userProvider.isUpdating ? null : _pickAndUploadImage,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: AppTheme.liquidPrimaryGradient,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.darkBackground, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primary.withOpacity(0.5),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: userProvider.isUpdating
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(
                              Icons.camera_alt_rounded,
                              size: 16,
                              color: Colors.white,
                            ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Name & Username
            Text(
              user?.displayName ?? 'Loading...',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.glassWhiteMedium,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.glassBorder),
              ),
              child: Text(
                '@${user?.username ?? 'username'}',
                style: const TextStyle(
                  color: AppTheme.cyan,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Followers & Following Stats Bar
            if (user != null)
              Consumer<FollowProvider>(
                builder: (context, followProvider, _) {
                  return GlassCard(
                    borderRadius: 20,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        StreamBuilder(
                          stream: followProvider.getFollowers(user.uid),
                          builder: (context, snap) {
                            final count = (snap.data as List?)?.length ?? 0;
                            return InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => FollowersListScreen(
                                      userId: user.uid,
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
                        Container(height: 30, width: 1, color: AppTheme.glassBorder),
                        StreamBuilder(
                          stream: followProvider.getFollowing(user.uid),
                          builder: (context, snap) {
                            final count = (snap.data as List?)?.length ?? 0;
                            return InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => FollowersListScreen(
                                      userId: user.uid,
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
                  );
                },
              ),
            const SizedBox(height: 16),

            // Pending Follow Requests Tile (Receiver Side)
            if (user != null)
              Consumer<FollowProvider>(
                builder: (context, followProvider, _) {
                  return StreamBuilder(
                    stream: followProvider.getPendingRequests(user.uid),
                    builder: (context, snap) {
                      final count = (snap.data as List?)?.length ?? 0;
                      if (count == 0) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: GlassCard(
                          borderRadius: 20,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const FollowRequestsScreen()),
                            );
                          },
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppTheme.cyan.withOpacity(0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.person_add_rounded, color: AppTheme.cyan, size: 20),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Follow Requests', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                    Text('$count pending request${count > 1 ? 's' : ''}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppTheme.primary,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text('$count', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),

            // Profile Details Glass Card
            GlassCard(
              borderRadius: 24,
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildProfileRow(
                    icon: Icons.info_outline_rounded,
                    label: 'About / Bio',
                    value: user?.bio ?? 'Hey there! I am using Shizz.',
                  ),
                  const Divider(color: AppTheme.glassBorder, height: 24),
                  _buildProfileRow(
                    icon: Icons.email_outlined,
                    label: 'Email',
                    value: user?.email ?? authProvider.firebaseUser?.email ?? 'Unknown',
                  ),
                  const Divider(color: AppTheme.glassBorder, height: 24),
                  _buildProfileRow(
                    icon: Icons.fingerprint_rounded,
                    label: 'User ID (UID)',
                    value: user?.uid ?? 'Unknown',
                    isMono: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Settings & Actions Glass Card
            GlassCard(
              borderRadius: 24,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.palette_outlined, color: AppTheme.cyan),
                    title: const Text('Appearance / Theme', style: TextStyle(color: Colors.white, fontSize: 15)),
                    subtitle: Text(themeLabel, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                    trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted),
                    onTap: _showAppearanceDialog,
                  ),
                  const Divider(color: AppTheme.glassBorder, height: 1),
                  ListTile(
                    leading: const Icon(Icons.edit_rounded, color: AppTheme.primaryLight),
                    title: const Text('Edit Profile Details', style: TextStyle(color: Colors.white, fontSize: 15)),
                    trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted),
                    onTap: _showEditProfileDialog,
                  ),
                  const Divider(color: AppTheme.glassBorder, height: 1),
                  ListTile(
                    leading: const Icon(Icons.logout_rounded, color: AppTheme.rose),
                    title: const Text('Sign Out', style: TextStyle(color: AppTheme.rose, fontSize: 15, fontWeight: FontWeight.w600)),
                    trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.rose),
                    onTap: _confirmSignOut,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileRow({
    required IconData icon,
    required String label,
    required String value,
    bool isMono = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppTheme.textSecondary),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontFamily: isMono ? 'monospace' : null,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
