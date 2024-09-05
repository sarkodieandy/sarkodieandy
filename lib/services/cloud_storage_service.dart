import 'dart:io';

// Packages
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';

class CloudStorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  CloudStorageService();

  // Save a user image to Firebase Storage
  Future<String?> saveUserImageToStorage(String uid, PlatformFile file) async {
    try {
      Reference ref = _storage.ref().child('images/users/$uid/profile.${file.extension}');
      UploadTask task = ref.putFile(File(file.path!));
      TaskSnapshot snapshot = await task;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print("Error saving user image to storage: $e");
      return null;
    }
  }

  // Save a chat image to Firebase Storage
  Future<String?> saveChatImageToStorage(String chatID, String userID, PlatformFile file) async {
    try {
      Reference ref = _storage.ref().child('images/chats/$chatID/${userID}_${Timestamp.now().millisecondsSinceEpoch}.${file.extension}');
      UploadTask task = ref.putFile(File(file.path!));
      TaskSnapshot snapshot = await task;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print("Error saving chat image to storage: $e");
      return null;
    }
  }
}
