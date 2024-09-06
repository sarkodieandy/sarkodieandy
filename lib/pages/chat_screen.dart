import 'package:flutter/material.dart';
import '../models/message.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:intl/intl.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _userInputs = TextEditingController();
  static const apiKey = "AIzaSyCHYgMKhDfYfXHRscIOWro6YzuLkcYh0q0";
  final model = GenerativeModel(model: "gemini-pro", apiKey: apiKey);

  final List<Message> _message = [];

  Future<void> callGemini() async {
    final message = _userInputs.text;
    setState(() {
      _message.add(
        Message(
          isUser: true,
          message: message,
          date: DateTime.now(),
        ),
      );
    });

    final content = Content.text(message);
    final response = await model.generateContent([content]);
    print(response.text);

    setState(() {
      _message.add(
        Message(
          isUser: false,
          message: response.text ?? "",
          date: DateTime.now(),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage("assets/images/ShareChat.png"),
              fit: BoxFit.cover,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Expanded(
                child: ListView.builder(
                    itemCount: _message.length,
                    itemBuilder: (context, index) {
                      final message = _message[index];
                      return Messages(
                          isUser: message.isUser,
                          message: message.message,
                          date: DateFormat("HH:mm").format(message.date));
                    }),
              ),
              Row(
                children: [
                  Expanded(
                    flex: 15,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: TextFormField(
                        controller: _userInputs,
                        decoration: InputDecoration(
                            label: const Text("Type in here",
                              style: TextStyle(color: Colors.white),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(25),
                            )),
                      ),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    padding: const EdgeInsets.all(16),
                    style: ButtonStyle(
                        foregroundColor:
                        WidgetStateProperty.all(Colors.white),
                        backgroundColor:
                        WidgetStateProperty.all(Colors.blue),
                        shape: WidgetStateProperty.all(
                          const CircleBorder(),
                        )),
                    onPressed: () {
                      callGemini();
                    },
                    icon: const Icon(Icons.send, size: 30),
                  )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
