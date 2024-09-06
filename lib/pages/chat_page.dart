import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

// Widgets
import '../widgets/top_bar.dart';
import '../widgets/custom_list_view_tiles.dart';
import '../widgets/custom_input_fields.dart';

// Models
import '../models/chat.dart';
import '../models/chat_message.dart';
import '../models/chat_user.dart';

// Providers
import '../providers/authentication_provider.dart';
import '../providers/chat_page_provider.dart';

class ChatPage extends StatefulWidget {
  final Chat chat;

  const ChatPage({super.key, required this.chat});

  @override
  State<StatefulWidget> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late double _deviceHeight;
  late double _deviceWidth;

  late AuthenticationProvider _auth;
  late ChatPageProvider _pageProvider;

  late GlobalKey<FormState> _messageFormState;
  late ScrollController _messagesListViewController;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _messageFormState = GlobalKey<FormState>();
    _messagesListViewController = ScrollController();
  }

  @override
  Widget build(BuildContext context) {
    _deviceHeight = MediaQuery.of(context).size.height;
    _deviceWidth = MediaQuery.of(context).size.width;
    _auth = Provider.of<AuthenticationProvider>(context);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ChatPageProvider>(
          create: (_) => ChatPageProvider(
              widget.chat.uid,
              _auth,
              _messagesListViewController
          ),
        ),
      ],
      child: Builder(
        builder: (BuildContext context) {
          _pageProvider = context.watch<ChatPageProvider>();
          return Scaffold(
            body: Column(
              children: [
                TopBar(
                  widget.chat.title(),
                  fontSize: 20, // Adjust fontSize as needed
                  primaryAction: IconButton(
                    icon: const Icon(
                      Icons.delete,
                      color: Color.fromRGBO(0, 82, 218, 1.0),
                    ),
                    onPressed: () {
                      _pageProvider.deleteChat();
                    },
                  ),
                  secondaryAction: IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Color.fromRGBO(0, 82, 218, 1.0),
                    ),
                    onPressed: () {
                      _pageProvider.goBack();
                    },
                  ),
                ),
                Expanded(
                  child: _messagesListView(),
                ),
                _sendMessageForm(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _messagesListView() {
    return StreamBuilder<QuerySnapshot>(
      stream: _pageProvider.getMessagesStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('No messages yet'));
        } else {
          var messages = snapshot.data!.docs
              .map((doc) => ChatMessage.fromJSON(doc.data() as Map<String, dynamic>))
              .toList();

          return ListView.builder(
            controller: _messagesListViewController,
            itemCount: messages.length,
            itemBuilder: (BuildContext context, int index) {
              ChatMessage message = messages[index];
              bool isOwnMessage = message.senderID == _auth.user?.uid;

              return FutureBuilder<ChatUser?>(
                future: _pageProvider.getUserById(message.senderID),
                builder: (context, userSnapshot) {
                  if (userSnapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (userSnapshot.hasError) {
                    return Center(child: Text('Error: ${userSnapshot.error}'));
                  } else if (!userSnapshot.hasData) {
                    return Center(child: Text('User not found'));
                  } else {
                    ChatUser sender = userSnapshot.data!;
                    return CustomChatListViewTile(
                      deviceHeight: _deviceHeight,
                      width: _deviceWidth * 0.80,
                      message: message,
                      isOwnMessage: isOwnMessage,
                      sender: sender,
                    );
                  }
                },
              );
            },
          );
        }
      },
    );
  }

  Widget _sendMessageForm() {
    return Form(
      key: _messageFormState,
      child: Row(
        children: [
          Expanded(
            child: CustomTextFormField(
              onSaved: (value) {
                _pageProvider.message = value;
              },
              regEx: r'.{1,}',
              hintText: 'Type a message',
              obscureText: false,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.photo),
            onPressed: _pickAndSendImage,
          ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: () {
              if (_messageFormState.currentState!.validate()) {
                _messageFormState.currentState!.save();
                _pageProvider.sendMessage();
                _messageFormState.currentState!.reset();
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndSendImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);
      String? imageUrl = await _pageProvider.uploadImage(imageFile);
      if (imageUrl != null) {
        await _pageProvider.sendMessage(imageUrl: imageUrl, isImage: true);
      }
    }
  }
}
