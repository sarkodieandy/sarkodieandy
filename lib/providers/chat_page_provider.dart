import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_it/get_it.dart';

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

  Future<void> sendMessage() async {
    if (message != null && message!.trim().isNotEmpty) {
      ChatMessage chatMessage = ChatMessage(
        content: message!,
        type: MessageType.TEXT, // Assuming text messages for now
        senderID: auth.user!.uid,
        sentTime: DateTime.now(),
      );

      await _db.addMessageToChat(chatID, chatMessage);
      message = null;
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
      notifyListeners();
    }
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
