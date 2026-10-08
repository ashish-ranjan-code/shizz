import 'package:intl/intl.dart';

class Helpers {
  /// Generates a deterministic 1-to-1 chat ID from two user IDs.
  /// Lexicographically compares uid1 and uid2 so both users always resolve to the same chat document.
  static String generateChatId(String uid1, String uid2) {
    if (uid1.compareTo(uid2) < 0) {
      return '${uid1}_$uid2';
    } else {
      return '${uid2}_$uid1';
    }
  }

  /// Extracts the other participant's UID from a 2-user list
  static String getOtherParticipantUid(List<String> participants, String currentUid) {
    return participants.firstWhere(
      (uid) => uid != currentUid,
      orElse: () => '',
    );
  }

  /// Formats message timestamp to readable hour:minute format (e.g., 04:20 PM)
  static String formatMessageTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    return DateFormat('hh:mm a').format(dateTime);
  }

  /// Formats chat list item timestamp (e.g., "11:30 AM", "Yesterday", "Oct 04")
  static String formatChatListTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0 && now.day == dateTime.day) {
      return DateFormat('hh:mm a').format(dateTime);
    } else if (difference.inDays <= 1 && now.day - dateTime.day == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return DateFormat('EEEE').format(dateTime); // e.g. Tuesday
    } else {
      return DateFormat('MMM dd').format(dateTime);
    }
  }

  /// Human-readable presence text
  static String formatPresence({required bool isOnline, DateTime? lastSeen}) {
    if (isOnline) return 'Online';
    if (lastSeen == null) return 'Offline';

    final now = DateTime.now();
    final diff = now.difference(lastSeen);

    if (diff.inMinutes < 1) {
      return 'Last seen just now';
    } else if (diff.inMinutes < 60) {
      return 'Last seen ${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return 'Last seen ${diff.inHours}h ago';
    } else {
      return 'Last seen ${DateFormat('MMM dd, hh:mm a').format(lastSeen)}';
    }
  }
}
