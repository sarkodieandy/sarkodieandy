//Packages
import 'package:flutter/material.dart';

//Pages
import '../pages/chats_page.dart';
import '../pages/users_page.dart';
import '../pages/chat_screen.dart'; // Import your ChatScreen here

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<StatefulWidget> createState() {
    return _HomePageState();
  }
}

class _HomePageState extends State<HomePage> {
  int _currentPage = 0;
  final List<Widget> _pages = [
    const ChatsPage(),
    const UsersPage(),
    const ChatScreen(), // Add ChatScreen to the list of pages
  ];

  @override
  Widget build(BuildContext context) {
    return _buildUI();
  }

  Widget _buildUI() {
    return Scaffold(
      body: _pages[_currentPage],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentPage,
        onTap: (index) {
          setState(() {
            _currentPage = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            label: "Chats",
            icon: Icon(
              Icons.chat_bubble_sharp,
            ),
          ),
          BottomNavigationBarItem(
            label: "Users",
            icon: Icon(
              Icons.supervised_user_circle_sharp,
            ),
          ),
          BottomNavigationBarItem(
            label: "Chatbot", // Update the label to be more descriptive
            icon: Icon(
              Icons.chat, // Use a different icon for distinction
            ),
          ),
        ],
      ),
    );
  }
}
