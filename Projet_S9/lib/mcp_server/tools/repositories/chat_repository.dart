import 'package:logging/logging.dart';
import 'package:hive/hive.dart';
import '../../../models/chat_message.dart' as models;
import '../../../models/conversation.dart' as convmodels;

final log = Logger('ChatRepository');

abstract class ChatRepository {
  Future<void> init();
  Future<List<Map<String, dynamic>>> getMessagesForConversation(String clientName);
  Future<Map<String, dynamic>?> getMessageByIndex(String clientName, int index);
  Future<int> getMessageCount(String clientName);
  Future<List<Map<String, dynamic>>> getConversations();
}

class InMemoryChatRepository implements ChatRepository {
  static const String _boxName = 'chat_messages';
  static const String _convBoxName = 'conversations';
  late Box _box;
  late Box _convBox;

  @override
  Future<void> init() async {
    _box = await Hive.openBox<models.ChatMessage>(_boxName);
    _convBox = await Hive.openBox<convmodels.Conversation>(_convBoxName);
  }

  @override
  Future<List<Map<String, dynamic>>> getMessagesForConversation(String clientName) async {
    final msgs = _box.values
        .whereType<models.ChatMessage>()
        .where((m) => m.clientName == clientName)
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    return msgs.map((m) => {
      'role': m.role,
      'text': m.text,
      'timestamp': m.timestamp.toIso8601String(),
    }).toList();
  }

  @override
  Future<Map<String, dynamic>?> getMessageByIndex(String clientName, int index) async {
    final msgs = _box.values
        .whereType<models.ChatMessage>()
        .where((m) => m.clientName == clientName)
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    if (index < 0 || index >= msgs.length) return null;

    final m = msgs[index];
    return {
      'index': index,
      'role': m.role,
      'text': m.text,
      'timestamp': m.timestamp.toIso8601String(),
    };
  }

  @override
  Future<int> getMessageCount(String clientName) async {
    final count = _box.values
        .whereType<models.ChatMessage>()
        .where((m) => m.clientName == clientName)
        .length;
    return count;
  }

  @override
  Future<List<Map<String, dynamic>>> getConversations() async {
    final convs = _convBox.values.whereType<convmodels.Conversation>().toList()
      ..sort((a, b) => b.lastUpdated.compareTo(a.lastUpdated));

    return convs.map((c) => {
      'id': c.id,
      'name': c.name,
      'createdAt': c.createdAt.toIso8601String(),
      'lastUpdated': c.lastUpdated.toIso8601String(),
      'lastMessage': c.lastMessage,
      'messageCount': c.messageCount,
    }).toList();
  }
}
