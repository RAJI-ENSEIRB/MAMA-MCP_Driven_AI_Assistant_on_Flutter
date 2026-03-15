import 'package:hive/hive.dart';

part 'conversation.g.dart';

@HiveType(typeId: 9)
class Conversation {
  @HiveField(0)
  final String id; // unique id (could be same as name or generated)

  @HiveField(1)
  String name;

  @HiveField(2)
  final DateTime createdAt;

  @HiveField(3)
  DateTime lastUpdated;

  @HiveField(4)
  String lastMessage;

  @HiveField(5)
  int messageCount;

  Conversation({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.lastUpdated,
    required this.lastMessage,
    required this.messageCount,
  });
}
