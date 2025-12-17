// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';

// Default FAQ questions and answers
final List<Map<String, String>> faqList = [
  {
    "question": "How to register as a student?",
    "answer":
        "Go to the registration page, fill in your details, and submit the required documents."
  },
  {
    "question": "How to reset my password?",
    "answer":
        "Click 'Forgot Password' on the login screen and follow the instructions."
  },
  {
    "question": "How to check exam results?",
    "answer":
        "Go to the 'Results' section in your dashboard to see your latest exam results."
  },
];

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  _ChatbotScreenState createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  List<Map<String, String>> messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  void _sendMessage(String question) {
    String answer = "I don't have an answer for this question.";

    // Check if question matches FAQ
    for (var faq in faqList) {
      if (faq['question']!.toLowerCase() == question.toLowerCase()) {
        answer = faq['answer']!;
        break;
      }
    }

    setState(() {
      messages.add({'user': question, 'bot': answer});
    });

    _controller.clear();

    // Scroll to bottom
    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 100,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  Widget _buildMessage(Map<String, String> msg) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User message
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 10, 161, 15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(msg['user']!,
                  style: const TextStyle(color: Colors.black)),
            ),
          ),
          const SizedBox(height: 5),
          // Bot message
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(msg['bot']!,
                  style: const TextStyle(color: Colors.black)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("AI FAQ Chatbot"),
        backgroundColor: const Color(0xFF2E7D32),
      ),
      body: Column(
        children: [
          // Chat area
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: messages.length,
              itemBuilder: (context, index) {
                return _buildMessage(messages[index]);
              },
            ),
          ),

          // Default questions list
          Container(
            height: 90,
            color: Colors.grey[100],
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: faqList.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    _sendMessage(faqList[index]['question']!);
                  },
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 28, 151, 28),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        faqList[index]['question']!,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Input field
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: "Type your question...",
                      border: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Color(0xFF2E7D32)),
                  onPressed: () {
                    if (_controller.text.isNotEmpty) {
                      _sendMessage(_controller.text);
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
