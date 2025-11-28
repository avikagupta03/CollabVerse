import 'package:flutter/material.dart';

class MessageBubble extends StatelessWidget {
  final String message;
  final String senderName;
  final DateTime timestamp;
  final bool isCurrentUser;
  final bool isEdited;

  const MessageBubble({
    Key? key,
    required this.message,
    required this.senderName,
    required this.timestamp,
    required this.isCurrentUser,
    this.isEdited = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final timeFormat =
        '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';

    return Align(
      alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: Column(
          crossAxisAlignment: isCurrentUser
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            if (!isCurrentUser)
              Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 4),
                child: Text(
                  senderName,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
            Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              decoration: BoxDecoration(
                color: isCurrentUser ? Colors.deepPurple : Colors.grey[300],
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(12),
                  topRight: const Radius.circular(12),
                  bottomLeft: isCurrentUser
                      ? const Radius.circular(12)
                      : Radius.zero,
                  bottomRight: isCurrentUser
                      ? Radius.zero
                      : const Radius.circular(12),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message,
                    style: TextStyle(
                      color: isCurrentUser ? Colors.white : Colors.black87,
                    ),
                  ),
                  if (isEdited)
                    Text(
                      '(edited)',
                      style: TextStyle(
                        fontSize: 10,
                        color: isCurrentUser ? Colors.white70 : Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 8, right: 8),
              child: Text(
                timeFormat,
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: Colors.grey[600]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
