import 'package:flutter/material.dart';

class NewMessage extends StatefulWidget {
  const NewMessage({super.key});

  @override
  State<NewMessage> createState() => _NewMessageState();
}

class _NewMessageState extends State<NewMessage> {
  final _messageController = TextEditingController();

  @override
  void dispose() {
    super.dispose();
    _messageController.dispose();
  }

  void _sendMessage() {
    final enteredMessage = _messageController.text;

    if (enteredMessage.trim().isEmpty) {
      return;
    }

    //save to firestore

    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 15,
        right: 1,
        bottom: 14,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                labelText: "Send Message",
              ),
              keyboardType: TextInputType.text,
              autocorrect: true,
              enableSuggestions: true,
              textCapitalization: TextCapitalization.none,
            ),
          ),
          IconButton(
            onPressed: () => _sendMessage(),
            icon: Icon(
              Icons.send,
              color: Theme.of(context).colorScheme.primary,
            ),
          )
        ],
      ),
    );
  }
}
