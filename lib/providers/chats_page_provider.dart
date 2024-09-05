import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Services
import '../services/database_service.dart';

// Providers
import '../providers/authentication_provider.dart';

// Models
import '../models/chat.dart';
import '../models/chat_user.dart';

class ChatsPageProvider extends ChangeNotifier {
  final AuthenticationProvider _auth;
  late DatabaseService _db;

  List<Chat>? chats;

  late StreamSubscription _chatsStream;

  // Constructor initializes the DatabaseService and starts chat fetching
  ChatsPageProvider(this._auth) {
    _db = GetIt.instance.get<DatabaseService>();
    getChats();
  }

  @override
  void dispose() {
    _chatsStream.cancel();
    super.dispose();
  }

  // Fetch and listen to real-time updates of user's chats
  void getChats() async {
    try {
      _chatsStream = _db.getChatsForUser(_auth.user!.uid).listen(
            (snapshot) async {
          chats = await Future.wait(
            snapshot.docs.map((d) async {
              Map<String, dynamic> chatData = d.data() as Map<String, dynamic>;

              // Fetch chat members
              List<ChatUser> members = [];
              for (var _uid in chatData["members"]) {
                DocumentSnapshot userSnapshot = await _db.getUser(_uid);
                if (userSnapshot.exists) {
                  Map<String, dynamic> userData = userSnapshot.data() as Map<String, dynamic>;
                  members.add(ChatUser.fromJSON(userData));
                }
              }

              // Create Chat object
              return Chat(
                uid: d.id,
                currentUserUid: _auth.user!.uid,
                activity: chatData["is_activity"],
                group: chatData["is_group"],
                members: members,
                messages: [], // Initially, messages are empty
              );
            }).toList(),
          );
          notifyListeners(); // Notify listeners to update the UI
        },
      );
    } catch (e) {
      print("Error getting chats: $e");
    }
  }
}
