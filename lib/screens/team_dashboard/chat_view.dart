import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';


class ChatView extends StatefulWidget {
  final String teamId;
  const ChatView({Key? key, required this.teamId}) : super(key: key);


  @override
  State<ChatView> createState() => _ChatViewState();
}


class _ChatViewState extends State<ChatView> {
  final msgCtrl = TextEditingController();


  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
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
                  return ListTile(
                    title: Text(d['message']),
                    subtitle: Text(d['sender_uid']),
                  );
                },
              );
            },
          ),
        ),
        Row(
          children: [
            Expanded(child: TextField(controller: msgCtrl, decoration: const InputDecoration(hintText: 'Message'))),
            IconButton(
              icon: const Icon(Icons.send),
              onPressed: () async {
                if (msgCtrl.text.trim().isEmpty) return;
                final uid = FirebaseAuth.instance.currentUser!.uid;
                await FirebaseFirestore.instance.collection('chats').doc(widget.teamId).collection('messages').add({
                  'sender_uid': uid,
                  'message': msgCtrl.text.trim(),
                  'timestamp': FieldValue.serverTimestamp(),
                });
                msgCtrl.clear();
              },
            )
          ],
        )
      ],
    );
  }
}