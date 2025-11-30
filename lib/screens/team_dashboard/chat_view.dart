import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../services/team_assistant_service.dart';


class ChatView extends StatefulWidget {
  final String teamId;
  const ChatView({super.key, required this.teamId});


  @override
  State<ChatView> createState() => _ChatViewState();
}


class _ChatViewState extends State<ChatView> {
  final msgCtrl = TextEditingController();
  final _assistant = TeamAssistantService();
  late final DocumentReference<Map<String, dynamic>> _chatDoc;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _configSub;

  bool _assistantEnabled = false;
  bool _sending = false;
  bool _assistantWorking = false;
  String? _userName;


  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildAssistantHeader(),
        Expanded(
          child: StreamBuilder(
            stream: FirebaseFirestore.instance.collection('chats').doc(widget.teamId).collection('messages').orderBy('timestamp', descending: true).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final docs = snapshot.data!.docs;
              return ListView.builder(
                reverse: true,
                itemCount: docs.length,
                itemBuilder: (context, i) {
                  final d = docs[i].data();
                  final senderType = d['sender_type'] ?? 'user';
                  final isAssistant = senderType == 'assistant';
                  final senderName = d['sender_name'] ?? d['sender_uid'];
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isAssistant ? Colors.indigo.shade50 : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isAssistant ? Colors.indigo.shade200 : Colors.grey.shade200,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              isAssistant ? Icons.smart_toy : Icons.person,
                              size: 16,
                              color: isAssistant ? Colors.indigo : Colors.grey.shade600,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              senderName,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: isAssistant ? Colors.indigo : Colors.grey.shade800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          d['message'] ?? '',
                          style: const TextStyle(fontSize: 14, height: 1.4),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
        if (_assistantWorking)
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: LinearProgressIndicator(minHeight: 2),
          ),
        Row(
          children: [
            Expanded(child: TextField(controller: msgCtrl, decoration: const InputDecoration(hintText: 'Message'))),
            IconButton(
              icon: const Icon(Icons.send),
              onPressed: _sending ? null : _handleSend,
            )
          ],
        )
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    _chatDoc = FirebaseFirestore.instance.collection('chats').doc(widget.teamId);
    _ensureChatDoc();
    _configSub = _chatDoc.snapshots().listen((doc) {
      if (!mounted) return;
      setState(() {
        _assistantEnabled = (doc.data()?['assistant_enabled'] as bool?) ?? false;
      });
    });
    _loadCurrentUser();
  }

  @override
  void dispose() {
    msgCtrl.dispose();
    _configSub?.cancel();
    super.dispose();
  }

  Future<void> _loadCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    setState(() {
      _userName = userDoc.data()?['name'] ?? user.email ?? user.uid;
    });
  }

  Future<void> _ensureChatDoc() async {
    final doc = await _chatDoc.get();
    if (!doc.exists) {
      await _chatDoc.set({
        'assistant_enabled': false,
        'created_at': FieldValue.serverTimestamp(),
      });
    }
  }

  Widget _buildAssistantHeader() {
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: _chatDoc.get(),
      builder: (context, snapshot) {
        final enabled = _assistantEnabled;
        return Card(
          margin: const EdgeInsets.fromLTRB(12, 12, 12, 6),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(Icons.smart_toy, color: enabled ? Colors.indigo : Colors.grey),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Collab Assistant',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: enabled ? Colors.indigo : Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        enabled
                            ? 'Assistant is active. Every message can get project ideas & task splits.'
                            : 'Toggle to invite the assistant. You can switch it off anytime.',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: enabled,
                  onChanged: (value) async {
                    await _chatDoc.set({'assistant_enabled': value}, SetOptions(merge: true));
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleSend() async {
    final text = msgCtrl.text.trim();
    if (text.isEmpty) return;
    msgCtrl.clear();
    setState(() => _sending = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _sending = false);
      return;
    }

    final senderName = _userName ?? user.email ?? user.uid;

    await _chatDoc.collection('messages').add({
      'sender_uid': user.uid,
      'sender_name': senderName,
      'sender_type': 'user',
      'message': text,
      'timestamp': FieldValue.serverTimestamp(),
    });

    setState(() => _sending = false);

    if (!_assistantEnabled) return;

    setState(() => _assistantWorking = true);
    try {
      final reply = await _assistant.generateAssistantReply(
        teamId: widget.teamId,
        prompt: text,
      );

      await _chatDoc.collection('messages').add({
        'sender_uid': 'assistant',
        'sender_name': 'Collab Assistant',
        'sender_type': 'assistant',
        'message': reply,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      await _chatDoc.collection('messages').add({
        'sender_uid': 'assistant',
        'sender_name': 'Collab Assistant',
        'sender_type': 'assistant',
        'message': 'I had trouble generating ideas ($e). Please try again.',
        'timestamp': FieldValue.serverTimestamp(),
      });
    } finally {
      if (mounted) {
        setState(() => _assistantWorking = false);
      }
    }
  }
}