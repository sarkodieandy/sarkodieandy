import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_it/get_it.dart';

// Services
import '../services/database_service.dart';
import '../services/navigation_service.dart';

// Providers
import '../providers/authentication_provider.dart';

// Models
import '../models/chat_user.dart';
import '../models/chat.dart';

// Pages
import '../pages/chat_page.dart';

class UsersPageProvider extends ChangeNotifier {
  final AuthenticationProvider _auth;
  late DatabaseService _database;
  late NavigationService _navigation;

  List<ChatUser>? users;
  final List<ChatUser> _selectedUsers = [];

  List<ChatUser> get selectedUsers => _selectedUsers;

  UsersPageProvider(this._auth) {
    _database = GetIt.instance.get<DatabaseService>();
    _navigation = GetIt.instance.get<NavigationService>();
    getUsers();
  }

  // Fetch users from Firestore, optionally filtered by name
  void getUsers({String? name}) async {
    _selectedUsers.clear();
    try {
      QuerySnapshot snapshot = await _database.getUsers(name: name);
      users = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data["uid"] = doc.id;
        return ChatUser.fromJSON(data);
      }).toList();
      notifyListeners();
    } catch (e) {
      print("Error getting users: $e");
    }
  }

  // Add or remove users from the selection list
  void updateSelectedUsers(ChatUser user) {
    if (_selectedUsers.contains(user)) {
      _selectedUsers.remove(user);
    } else {
      _selectedUsers.add(user);
    }
    notifyListeners();
  }

  // Create a new chat and navigate to the chat page
  Future<void> createChat() async {
    try {
      // Prepare chat data
      final membersIds = _selectedUsers.map((user) => user.uid).toList();
      membersIds.add(_auth.user!.uid); // Add the current user to the chat
      final isGroup = _selectedUsers.length > 1;
      final chatData = {
        "is_group": isGroup,
        "is_activity": false,
        "members": membersIds,
      };

      // Create a new chat document in Firestore
      final docRef = await _database.createChat(chatData);

      if (docRef == null) {
        throw Exception("Failed to create chat document.");
      }

      // Fetch the chat members' data
      final members = <ChatUser>[];
      for (var uid in membersIds) {
        final userSnapshot = await _database.getUser(uid);
        final userData = userSnapshot.data() as Map<String, dynamic>;
        userData["uid"] = userSnapshot.id;
        members.add(ChatUser.fromJSON(userData));
      }

      // Create the chat page and navigate to it
      final chatPage = ChatPage(
        chat: Chat(
          uid: docRef.id, // Access the document ID from the reference
          currentUserUid: _auth.user!.uid,
          members: members,
          messages: [],
          activity: false,
          group: isGroup,
        ),
      );

      // Clear selections and navigate
      _selectedUsers.clear();
      notifyListeners();
      _navigation.navigateToPage(chatPage);
    } catch (e) {
      print("Error creating chat: $e");
    }
  }
}
