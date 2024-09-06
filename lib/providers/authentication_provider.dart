import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';

// Services
import '../services/database_service.dart';
import '../services/navigation_service.dart';

// Models
import '../models/chat_user.dart';

class AuthenticationProvider extends ChangeNotifier {
  late final FirebaseAuth _auth;
  late final NavigationService _navigationService;
  late final DatabaseService _databaseService;

  ChatUser? user;

  AuthenticationProvider() {
    _auth = FirebaseAuth.instance;
    _navigationService = GetIt.instance.get<NavigationService>();
    _databaseService = GetIt.instance.get<DatabaseService>();


    _auth.authStateChanges().listen((firebaseUser) async {
      if (firebaseUser != null) {
        await _databaseService.updateUserLastSeenTime(firebaseUser.uid);
        try {
          final snapshot = await _databaseService.getUser(firebaseUser.uid);
          if (snapshot.exists) {
            Map<String, dynamic> userData = snapshot.data() as Map<String, dynamic>;
            user = ChatUser.fromJSON({
              "uid": firebaseUser.uid,
              "name": userData["name"],
              "email": userData["email"],
              "last_active": userData["last_active"],
              "image": userData["image"],
            });
            notifyListeners(); // Notify the listeners of the change
            _navigationService.removeAndNavigateToRoute('/home');
          }
        } catch (e) {
          print("Error fetching user data: $e");
        }
      } else {
        if (_navigationService.getCurrentRoute() != '/login') {
          _navigationService.removeAndNavigateToRoute('/login');
        }
      }
    });
  }

  Future<void> loginUsingEmailAndPassword(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      print("Error during login: $e");
      throw Exception("Login failed. Please try again.");
    }
  }

  Future<String?> registerUserUsingEmailAndPassword(String email, String password) async {
    try {
      UserCredential credentials = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      return credentials.user?.uid;
    } catch (e) {
      print("Error during registration: $e");
      throw Exception("Registration failed. Please try again.");
    }
  }

  Future<void> logout() async {
    try {
      await _auth.signOut();
      _navigationService.removeAndNavigateToRoute('/login');
      user = null;
      notifyListeners();
    } catch (e) {
      print("Error during logout: $e");
    }
  }
}


