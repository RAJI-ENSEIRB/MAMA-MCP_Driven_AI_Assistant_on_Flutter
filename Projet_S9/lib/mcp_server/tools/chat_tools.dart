import 'package:mcp_dart/mcp_dart.dart';
import 'dart:convert';
import 'repositories/chat_repository.dart';

class ChatTools {
	final InMemoryChatRepository _repository = InMemoryChatRepository();

	Future<void> register(McpServer server) async {
		await _repository.init();

		server.registerTool(
			'chat_get_conversation',
			description: '''Returns the list of messages for a conversation id (clientName).''',
			inputSchema: ToolInputSchema(
				properties: {
					'id': JsonSchema.string(description: 'Conversation id / clientName'),
				},
				required: ['id'],
			),
			callback: (args, extra) async {
				final id = args['id']?.toString() ?? '';
				if (id.isEmpty) {
					return CallToolResult(content: [TextContent(text: 'Missing id')], isError: true);
				}
				try {
					final messages = await _repository.getMessagesForConversation(id);
					return CallToolResult(content: [TextContent(text: jsonEncode({'messages': messages}))]);
				} catch (e) {
					return CallToolResult(content: [TextContent(text: 'Error reading conversation: $e')], isError: true);
				}
			},
		);

		server.registerTool(
			'chat_list_conversations',
			description: '''Returns the list of conversations with their ids.''',
			inputSchema: ToolInputSchema(
				properties: {},
				required: [],
			),
			callback: (args, extra) async {
				try {
					final convs = await _repository.getConversations();
					return CallToolResult(content: [TextContent(text: jsonEncode({'conversations': convs}))]);
				} catch (e) {
					return CallToolResult(content: [TextContent(text: 'Error listing conversations: $e')], isError: true);
				}
			},
		);
    server.registerTool(
			'chat_get_message',
			description: '''Returns a single message by index for a conversation.''',
			inputSchema: ToolInputSchema(
				properties: {
					'id': JsonSchema.string(description: 'Conversation id / clientName'),
					'index': JsonSchema.integer(description: 'Zero-based message index'),
				},
				required: ['id', 'index'],
			),
			callback: (args, extra) async {
				final id = args['id']?.toString() ?? '';
				final idx = args['index'] as int?;
				if (id.isEmpty || idx == null) {
					return CallToolResult(content: [TextContent(text: 'Missing id or index')], isError: true);
				}
				try {
					final msg = await _repository.getMessageByIndex(id, idx);
					if (msg == null) {
						return CallToolResult(content: [TextContent(text: 'Message not found')], isError: true);
					}
					return CallToolResult(content: [TextContent(text: jsonEncode(msg))]);
				} catch (e) {
					return CallToolResult(content: [TextContent(text: 'Error reading message: $e')], isError: true);
				}
			},
		);

		server.registerTool(
			'chat_get_count',
			description: 'Returns message count for a conversation',
			inputSchema: ToolInputSchema(
				properties: {
					'id': JsonSchema.string(description: 'Conversation id / clientName'),
				},
				required: ['id'],
			),
			callback: (args, extra) async {
				final id = args['id']?.toString() ?? '';
				if (id.isEmpty) {
					return CallToolResult(content: [TextContent(text: 'Missing id')], isError: true);
				}
				try {
					final count = await _repository.getMessageCount(id);
					return CallToolResult(content: [TextContent(text: jsonEncode({'count': count}))]);
				} catch (e) {
					return CallToolResult(content: [TextContent(text: 'Error reading count: $e')], isError: true);
				}
			},
		);
	}
}

