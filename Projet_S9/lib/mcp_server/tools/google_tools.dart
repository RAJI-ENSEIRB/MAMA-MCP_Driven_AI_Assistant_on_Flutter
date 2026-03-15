import 'package:mcp_dart/mcp_dart.dart';
import 'dart:convert';
import 'repositories/access_google_calendar.dart';
import 'repositories/own_event.dart';
import 'repositories/contacts_repository.dart';

class GoogleTools {
  final ContactsRepository _repository = ContactsRepository();

  void register(McpServer server) {
    server.registerTool(
      "get_google_contacts",
      description: '''
      Retourne la liste des contacts Google (nom, email, numéro).
      Si l’utilisateur n’est pas connecté via Google, renvoie NOT_CONNECTED.
      ''',
      callback: (args, extra) async {
        try {
          final contacts = await _repository.getContacts();
          return CallToolResult(
            content: [TextContent(text: jsonEncode(contacts))],
          );
        } catch (e) {
          if (e.toString().contains("NOT_CONNECTED")) {
            return CallToolResult(
              content: [TextContent(text: "NOT_CONNECTED")],
              isError: true,
            );
          }

          return CallToolResult(
            content: [TextContent(text: "Error reading contacts: $e")],
            isError: true,
          );
        }
      }
    );

    server.registerTool("get_calendar_events", 
      description:'''Retrieves calendar events, planning, and occupation details. You have to take exactly the period by day necessary. 
      To retrieve all events, use no arguments. To filter by date range, provide "start" and/or "end" arguments.
      ''',
      inputSchema: ToolInputSchema(
        properties: {
          "start": JsonSchema.string(
            pattern: r'^(0[1-9]|[12][0-9]|3[01])/(0[1-9]|1[0-2])/\d{4}$',
            description: "Date début JJ/MM/AAAA",
          ),
          "end": JsonSchema.string(
            pattern: r'^(0[1-9]|[12][0-9]|3[01])/(0[1-9]|1[0-2])/\d{4}$',
            description: "Date fin JJ/MM/AAAA",
          ),
        },
      ),
      callback: (args, extra) async {
        final String? start = args["start"]?.toString();
        final String? end = args["end"]?.toString();

        try {
          final List<OwnEvent> allevents = await geteventscalendar(start, end);
          return CallToolResult(
              content: [
                TextContent(text: jsonEncode(allevents.map((event) => event.toJson()).toList())),
              ],
          );
        } catch (e) {
          return CallToolResult(
            content: [TextContent(text: "Erreur calendrier : $e")],
            isError: true,
          );
        }
      }
    );
  }
}