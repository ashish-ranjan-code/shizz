import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class UserAvatar extends StatelessWidget {
  final String? photoUrl;
  final String name;
  final double radius;
  final bool isOnline;
  final bool showOnlineBadge;

  const UserAvatar({
    super.key,
    this.photoUrl,
    required this.name,
    this.radius = 24.0,
    this.isOnline = false,
    this.showOnlineBadge = false,
  });

  String _getInitials(String input) {
    final clean = input.trim();
    if (clean.isEmpty) return 'U';
    final parts = clean.split(' ');
    if (parts.length > 1 && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return clean.substring(0, clean.length >= 2 ? 2 : 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final double diameter = radius * 2;

    Widget avatarImage;
    if (photoUrl != null && photoUrl!.isNotEmpty) {
      avatarImage = CachedNetworkImage(
        imageUrl: photoUrl!,
        width: diameter,
        height: diameter,
        fit: BoxFit.cover,
        placeholder: (context, url) => _buildPlaceholder(),
        errorWidget: (context, url, error) => _buildPlaceholder(),
      );
    } else {
      avatarImage = _buildPlaceholder();
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: diameter,
          height: diameter,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isOnline ? AppTheme.emerald.withOpacity(0.5) : AppTheme.glassBorder,
              width: 1.5,
            ),
          ),
          child: ClipOval(child: avatarImage),
        ),
        if (showOnlineBadge && isOnline)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: radius * 0.55,
              height: radius * 0.55,
              decoration: BoxDecoration(
                color: AppTheme.emerald,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.background,
                  width: 2.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.emerald.withOpacity(0.5),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primary.withOpacity(0.8),
            AppTheme.violet.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        _getInitials(name),
        style: TextStyle(
          color: Colors.white,
          fontSize: radius * 0.75,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
