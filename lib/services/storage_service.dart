import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import '../utils/constants.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Uploads user profile image to Firebase Storage and returns the public download URL
  Future<String> uploadProfileImage({
    required String uid,
    required File imageFile,
  }) async {
    try {
      final ref = _storage
          .ref()
          .child(AppConstants.profileImagesStoragePath)
          .child('$uid.jpg');

      final uploadTask = ref.putFile(
        imageFile,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final snapshot = await uploadTask.whenComplete(() => {});
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } on FirebaseException catch (e) {
      throw 'Storage error: ${e.message ?? e.code}';
    } catch (e) {
      throw 'Failed to upload profile picture. Please try again.';
    }
  }

  /// Uploads chat image/attachment to Firebase Storage and returns download URL
  Future<String> uploadChatAttachment({
    required String chatId,
    required File file,
    String? extension,
  }) async {
    try {
      final ext = extension ?? 'jpg';
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').pop()}.$ext';
      final ref = _storage
          .ref()
          .child('chat_attachments')
          .child(chatId)
          .child(fileName);

      final uploadTask = ref.putFile(
        file,
        SettableMetadata(contentType: ext == 'png' ? 'image/png' : 'image/jpeg'),
      );

      final snapshot = await uploadTask.whenComplete(() => {});
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } on FirebaseException catch (e) {
      throw 'Attachment upload error: ${e.message ?? e.code}';
    } catch (e) {
      throw 'Failed to upload image attachment: $e';
    }
  }
}
