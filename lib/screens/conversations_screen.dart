import 'package:chatgpt/model/conversation.dart';
import 'package:flutter/material.dart';

import '../services/database_helper.dart';
import 'chat_screen.dart';

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  late Future<List<Conversation>?> _conversations;

  @override
  void initState() {
    super.initState();
    _refreshNotes();
  }

  Future<void> _refreshNotes() async {
    setState(() {
      _conversations = DatabaseHelper.getDistinctConversationIds();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Conversations'),
      ),
      body: FutureBuilder(
        future: _conversations,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          } else {
            List<Conversation> conversations =
                (snapshot.data as List<Conversation>);
            return ListView.builder(
              itemCount: conversations.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(conversations[index].conversationId),
                  subtitle: Text(conversations[index].title),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MyHomePage(
                          title: 'chat',
                          conversationId: conversations[index].conversationId,
                        ),
                      ),
                    );
                  },
                );
              },
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const MyHomePage(
                      title: 'chat',
                      conversationId: '',
                    )),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
