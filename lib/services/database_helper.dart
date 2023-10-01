import 'package:chatgpt/model/chat_message.dart';
import 'package:chatgpt/model/conversation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static const int _version = 1;
  static const String _dbName = "Chats.db";
  static Future<Database> _getDB() async {
    return openDatabase(join(await getDatabasesPath(), _dbName),
        onCreate: (db, version) async => await db.execute(
            'CREATE TABLE IF NOT EXISTS chats(id INTEGER, user TEXT, createdAt TEXT, message TEXT, conversationId TEXT, PRIMARY KEY (id, conversationId))'),
        version: _version);
  }

  static Future<int> addNote(ChatMsg chat) async {
    final db = await _getDB();
    return await db.insert('chats', chat.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<List<ChatMsg>?> getAllChats() async {
    final db = await _getDB();

    final List<Map<String, dynamic>> maps = await db.query("chats");
    if (maps.isEmpty) {
      return null;
    }

    return List.generate(maps.length, (index) => ChatMsg.fromJson(maps[index]));
  }

  static Future<List<Conversation>> getDistinctConversationIds() async {
    Database db = await _getDB();
    List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT conversationId, min(message) AS firstTitle
      FROM chats
      GROUP BY conversationId
    ''');

    return List.generate(maps.length, (i) {
      print(maps[i]);
      return Conversation(
        maps[i]['conversationId'] as String,
        maps[i]['firstTitle'] as String,
      );
    });
  }

  static Future<List<ChatMsg>?> getMessagesConversation(
      String conversationId) async {
    final db = await _getDB();

    List<Map<String, dynamic>> maps = await db.rawQuery('''
    SELECT *
    FROM chats
    WHERE conversationId= '$conversationId'
  ''');
    if (maps.isEmpty) {
      return null;
    }

    return List.generate(maps.length, (index) => ChatMsg.fromJson(maps[index]));
  }
}
