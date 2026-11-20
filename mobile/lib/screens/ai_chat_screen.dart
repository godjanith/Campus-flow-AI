import 'package:flutter/material.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final List<Map<String, String>> _messages = [
    {'sender': 'ai', 'text': 'Hello! I am your CampusFlow AI Assistant. How can I help you navigate or resolve campus issues today?'}
  ];
  final _controller = TextEditingController();

  void _sendMessage() {
    if (_controller.text.isEmpty) return;
    final text = _controller.text;
    setState(() {
      _messages.add({'sender': 'user', 'text': text});
      _messages.add({'sender': 'ai', 'text': 'AI Response: I have analyzed your query regarding "$text". Maintenance team has been notified.'});
    });
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final m = _messages[index];
              final isAi = m['sender'] == 'ai';
              return Align(
                alignment: isAi ? Alignment.centerLeft : Alignment.centerRight,
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isAi ? Colors.grey[200] : Colors.indigo,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    m['text']!,
                    style: TextStyle(color: isAi ? Colors.black : Colors.white),
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: const InputDecoration(hintText: 'Ask CampusFlow AI...', border: OutlineInputBorder()),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send, color: Colors.indigo),
                onPressed: _sendMessage,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
