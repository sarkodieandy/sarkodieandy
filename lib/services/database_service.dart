import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_message.dart';

const String USER_COLLECTION = "Users";
const String CHAT_COLLECTION = "Chats";
const String MESSAGES_COLLECTION = "messages";

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  DatabaseService();

  // Create user in Firestore
  Future<void> createUser(String uid, String email, String name, String imageURL) async {
    try {
      await _db.collection(USER_COLLECTION).doc(uid).set({
        "email": email,
        "image": imageURL,
        "last_active": DateTime.now().toUtc(),
        "name": name,
      });
    } catch (e) {
      print("Error creating user: $e");
    }
  }

  // Get user data
  Future<DocumentSnapshot> getUser(String uid) async {
    try {
      DocumentSnapshot userSnapshot = await _db.collection(USER_COLLECTION).doc(uid).get();
      if (userSnapshot.exists) {
        return userSnapshot;
      } else {
        throw Exception("User not found");
      }
    } catch (e) {
      print("Error getting user: $e");
      rethrow;
    }
  }

  // Get users based on name search
  Future<QuerySnapshot> getUsers({String? name}) async {
    try {
      Query query = _db.collection(USER_COLLECTION);
      if (name != null) {
        query = query
            .where("name", isGreaterThanOrEqualTo: name)
            .where("name", isLessThanOrEqualTo: "${name}z");
      }
      return await query.get();
    } catch (e) {
      print("Error getting users: $e");
      rethrow;
    }
  }

  // Stream chats for a specific user
  Stream<QuerySnapshot> getChatsForUser(String uid) {
    return _db
        .collection(CHAT_COLLECTION)
        .where('members', arrayContains: uid)
        .snapshots();
  }

  // Get the last message for a specific chat
  Future<QuerySnapshot> getLastMessageForChat(String chatID) async {
    try {
      return await _db
          .collection(CHAT_COLLECTION)
          .doc(chatID)
          .collection(MESSAGES_COLLECTION)
          .orderBy("sent_time", descending: true)
          .limit(1)
          .get();
    } catch (e) {
      print("Error getting last message for chat: $e");
      rethrow;
    }
  }

  // Stream all messages for a specific chat
  Stream<QuerySnapshot> streamMessagesForChat(String chatID) {
    return _db
        .collection(CHAT_COLLECTION)
        .doc(chatID)
        .collection(MESSAGES_COLLECTION)
        .orderBy("sent_time", descending: false)
        .snapshots();
  }

  // Add a message to a chat
  Future<void> addMessageToChat(String chatID, ChatMessage message) async {
    try {
      await _db
          .collection(CHAT_COLLECTION)
          .doc(chatID)
          .collection(MESSAGES_COLLECTION)
          .add(message.toJson());
    } catch (e) {
      print("Error adding message to chat: $e");
    }
  }

  // Update chat data
  Future<void> updateChatData(String chatID, Map<String, dynamic> data) async {
    try {
      await _db.collection(CHAT_COLLECTION).doc(chatID).update(data);
    } catch (e) {
      print("Error updating chat data: $e");
    }
  }

  // Update last active time for a user
  Future<void> updateUserLastSeenTime(String uid) async {
    try {
      await _db.collection(USER_COLLECTION).doc(uid).update({
        "last_active": DateTime.now().toUtc(),
      });
    } catch (e) {
      print("Error updating last seen time: $e");
    }
  }

  // Delete a chat
  Future<void> deleteChat(String chatID) async {
    try {
      await _db.collection(CHAT_COLLECTION).doc(chatID).delete();
    } catch (e) {
      print("Error deleting chat: $e");
    }
  }

  // Create a new chat
  Future<DocumentReference?> createChat(Map<String, dynamic> data) async {
    try {
      DocumentReference chat = await _db.collection(CHAT_COLLECTION).add(data);
      return chat;
    } catch (e) {
      print("Error creating chat: $e");
    }
    return null;
  }
}
