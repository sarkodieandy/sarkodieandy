import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_it/get_it.dart';
import 'package:firebase_storage/firebase_storage.dart';

// Services
import '../services/database_service.dart';

// Providers
import '../providers/authentication_provider.dart';

// Models
import '../models/chat_message.dart';
import '../models/chat_user.dart';

class ChatPageProvider extends ChangeNotifier {
  final String chatID;
  final AuthenticationProvider auth;
  final ScrollController scrollController;

  late DatabaseService _db;
  String? message;

  ChatPageProvider(this.chatID, this.auth, this.scrollController) {
    _db = GetIt.instance.get<DatabaseService>();
  }

  Stream<QuerySnapshot> getMessagesStream() {
    return _db.streamMessagesForChat(chatID);
  }

  Future<void> sendMessage({String? imageUrl, bool isImage = false}) async {
    ChatMessage chatMessage;

    if (isImage && imageUrl != null) {
      chatMessage = ChatMessage(
        content: imageUrl,
        type: MessageType.IMAGE,
        senderID: auth.user!.uid,
        sentTime: DateTime.now(),
      );
    } else if (message != null && message!.trim().isNotEmpty) {
      chatMessage = ChatMessage(
        content: message!,
        type: MessageType.TEXT,
        senderID: auth.user!.uid,
        sentTime: DateTime.now(),
      );
      message = null;
    } else {
      return; // Do nothing if there's no valid message
    }

    await _db.addMessageToChat(chatID, chatMessage);

    scrollController.animateTo(
      scrollController.position.maxScrollExtent,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
    notifyListeners();
  }

  Future<String?> uploadImage(File imageFile) async {
    try {
      final storageRef = FirebaseStorage.instance.ref().child('chat_images/${DateTime.now().millisecondsSinceEpoch}.jpg');
      final uploadTask = storageRef.putFile(imageFile);
      final snapshot = await uploadTask.whenComplete(() => null);
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print("Error uploading image: $e");
      return null;
    }
  }

  Future<void> pickAndSendImage() async {
    // Implement image picker logic here
    // Example: using image_picker package
    // final picker = ImagePicker();
    // final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    // if (pickedFile != null) {
    //   File imageFile = File(pickedFile.path);
    //   String? imageUrl = await uploadImage(imageFile);
    //   if (imageUrl != null) {
    //     await sendMessage(imageUrl: imageUrl, isImage: true);
    //   }
    // }
  }

  Future<ChatUser?> getUserById(String userId) async {
    DocumentSnapshot userDoc = await _db.getUser(userId);
    if (userDoc.exists) {
      return ChatUser.fromJSON(userDoc.data() as Map<String, dynamic>);
    }
    return null;
  }

  void deleteChat() {
    _db.deleteChat(chatID);
  }

  void goBack() {
    // Implement navigation logic to go back
  }
}
