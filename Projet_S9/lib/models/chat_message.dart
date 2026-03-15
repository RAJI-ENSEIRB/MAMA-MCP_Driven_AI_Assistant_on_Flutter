import 'package:hive/hive.dart';

part 'chat_message.g.dart';

@HiveType(typeId: 8)
class ChatMessage {
  @HiveField(0)
  final String role; // 'user' or 'assistant'

  @HiveField(1)
  final String text;

  @HiveField(2)
  final DateTime timestamp;

  @HiveField(3)
  final String clientName;

  ChatMessage({
    required this.role,
    required this.text,
    required this.timestamp,
    required this.clientName,
  });
}
