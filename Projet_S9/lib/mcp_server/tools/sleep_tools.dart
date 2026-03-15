import 'package:mcp_dart/mcp_dart.dart';
import 'dart:convert';
import 'repositories/sleep_repository.dart';

class NwsResult<T> {
  final T? data;
  final String? error;
  NwsResult({this.data, this.error});
  bool get isSuccess => error == null;

  Map<String, dynamic> toJson() {
    return {'success': isSuccess, 'data': data, 'error': error};
  }
}

class SleepTools {
  final InMemorySleepRepository _repository = InMemorySleepRepository();

  Future<void> register(McpServer server) async {
    await _repository.init();
    
    server.registerTool(
      "add_sleep",
      description: '''Logs a new sleep session including duration and quality''',
      inputSchema: ToolInputSchema(
        properties: {
          "date": JsonSchema.string(
            pattern: r'^(0[1-9]|[12][0-9]|3[01])-(0[1-9]|1[0-2])-\d{4}$',
            description: "Date (dd-mm-yyyy)"
          ),
          "wakeupTime": JsonSchema.string(pattern: r'^([01]\d|2[0-3]):([0-5]\d)$', description: "HH:mm"),
          "bedTime": JsonSchema.string(pattern: r'^([01]\d|2[0-3]):([0-5]\d)$', description: "HH:mm"),
          "quality": JsonSchema.integer(minimum: 0, maximum: 5, description: "Quality 0-5"),
        },
        required: ["date", "wakeupTime", "bedTime", "quality"],
      ),
      callback: (args, extra) async {
        final date = args["date"]?.toString().trim() ?? '';
        final wakeupTime = args["wakeupTime"]?.toString().trim() ?? '';
        final bedTime = args["bedTime"]?.toString().trim() ?? '';
        final quality = int.tryParse(args["quality"]?.toString() ?? '3') ?? 3;

        try {
          final addedSleep = await _repository.addSleep(date, wakeupTime, bedTime, quality);
          final result = NwsResult(data: addedSleep);
          return CallToolResult(content: [TextContent(text:
            "Sleep added successfully: ${result.data!['date']} "
            "bed at ${result.data!['bedTime']}, woke up at ${result.data!['wakeupTime']} "
            "(quality: ${result.data!['quality']})",
          )]);
        } catch (error) {
          return CallToolResult(
            content: [TextContent(text: "Error adding sleep: $error")],
            isError: true,
          );
        }
      },
    );

    server.registerTool(
      "get_sleep",
      description: '''Retrieves sleep logs for a specific date''',
      inputSchema: ToolInputSchema(
        properties: {
          'date': JsonSchema.string(
            pattern: r'^(0[1-9]|[12][0-9]|3[01])-(0[1-9]|1[0-2])-\d{4}$',
            description: "Date to fetch sleep entries (dd-mm-yyyy)",
          ),
        },
        required: ['date'],
      ),
      callback: (args, extra) async {
        final date = args["date"]?.toString().trim() ?? '';

        try {
          final sleeps = await _repository.getSleep(date);
          final result = NwsResult(data: sleeps);

          return CallToolResult(
            content: [TextContent(text: jsonEncode(result.toJson()))],
          );
        } catch (error) {
          return CallToolResult(
            content: [TextContent(text: "Error reading sleep data: $error")],
            isError: true,
          );
        }
      },
    );

    server.registerTool(
      "del_sleep",
      description: '''Deletes a specific sleep record''',
      inputSchema: ToolInputSchema(
        properties: {
          'id': JsonSchema.integer(description: 'ID of the sleep entry to delete'),
        },
        required: ['id'],
      ),
      callback: (args, extra) async {
        final id = args["id"] as int?;
        if (id == null) {
          return CallToolResult(
            content: [TextContent(text: "Invalid or missing ID")],
            isError: true,
          );
        }

        try {

          final success = _repository.deleteSleepById(id);
          if (!success) {
            return CallToolResult(
              content: [TextContent(text: "Sleep entry with id $id not found.")],
              isError: true,
            );
          }

          return CallToolResult(
            content: [TextContent(text: "Deleted sleep entry $id successfully")],
          );
          
        } catch (e) {
          return CallToolResult(
            content: [TextContent(text: "Error during deletion: $e")],
            isError: true,
          );
        }
      },
    );

    server.registerTool(
      "edit_sleep",
      description: '''Modifies an existing sleep entry's details''',
      inputSchema: ToolInputSchema(
        properties: {
          'id': JsonSchema.integer(description: 'ID of the sleep entry to edit'),
          'date': JsonSchema.string(
            pattern: r'^(0[1-9]|[12][0-9]|3[01])-(0[1-9]|1[0-2])-\d{4}$',
            description: "New date format dd-mm-yyyy",
          ),
          "wakeupTime": JsonSchema.string(pattern: r'^([01]\d|2[0-3]):([0-5]\d)$', description: "New wakeup time format HH:mm"),
          "bedTime": JsonSchema.string(pattern: r'^([01]\d|2[0-3]):([0-5]\d)$', description: "New bed time format HH:mm"),
          "quality": JsonSchema.integer(minimum: 0, maximum: 5, description: "New sleep quality"),
        },
        required: ['id'],
      ),
      callback: (args, extra) async {
        final id = args["id"] as int?;
        if (id == null) {
          return CallToolResult(
            content: [TextContent(text: "Missing required parameter: 'id'")],
            isError: true,
          );
        }

        final newDate = args["date"]?.toString().trim();
        final newWakeupTime = args["wakeupTime"]?.toString().trim();
        final newBedTime = args["bedTime"]?.toString().trim();
        final newQualityRaw = args["quality"]?.toString().trim();

        if (newDate == null &&
            newWakeupTime == null &&
            newBedTime == null &&
            newQualityRaw == null) {
          return CallToolResult(
            content: [TextContent(text:"Nothing to update. Pass at least one of: date, wakeupTime, bedTime, quality")],
            isError: true,
          );
        }

        try {

          final sleep = _repository.getSleepById(id);
          if (sleep == null) {
            return CallToolResult(
              content: [TextContent(text: "Sleep entry with id $id not found.")],
              isError: true,
            );
          }

          final updates = <String, dynamic>{};
          if (newDate != null) updates["date"] = newDate;
          if (newWakeupTime != null) updates["wakeupTime"] = newWakeupTime;
          if (newBedTime != null) updates["bedTime"] = newBedTime;
          if (newQualityRaw != null) {
            final quality = int.tryParse(newQualityRaw);
            if (quality == null) {
              return CallToolResult(
                content: [
                  TextContent(text: "Parameter 'quality' must be an integer"),
                ],
                isError: true,
              );
            }
            updates["quality"] = quality;
          }

          final updated = _repository.updateSleepById(id, updates);
          if (!updated) {
            return CallToolResult(
              content: [TextContent(text: "Failed to update sleep entry $id.")],
              isError: true,
            );
          }
        } catch (error) {
          return CallToolResult(
            content: [TextContent(text: "Error during update: $error")],
            isError: true,
          );
        }

        return CallToolResult(
          content: [TextContent(text: "Sleep entry $id updated successfully.")],
        );
      }
    );
  }
}