import 'package:mcp_dart/mcp_dart.dart';
import 'package:logging/logging.dart' as logging;
import 'tools/dishes_tools.dart';
import 'tools/sleep_tools.dart';
import 'tools/weather_tools.dart';
import 'tools/google_tools.dart';
import 'tools/profile_tools.dart';
import 'tools/repositories/location_repository.dart';
import 'tools/chat_tools.dart';
import 'sse_handler.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:async';

final log = logging.Logger('Server');

final Map<String, StreamableHTTPServerTransport> transports = {};

class McpServerInstance {
  late McpServer server;
  late SseServerManager sseServerManager;

  Future<void> createMcpServer() async {
    log.info('=== createMcpServer ==='.padRight(20));
    final location = LocationRepository();

    server = McpServer(
      Implementation(name: "mcp-dart-server", version: "1.0.0"),
      options: const ServerOptions(
        capabilities: ServerCapabilities(
          //resources: ServerCapabilitiesRessources(),
          tools: ServerCapabilitiesTools(),
        ),
      ),
    );

    await DishesTools().register(server);
    await SleepTools().register(server);
    ChatTools().register(server);
    WeatherTools().register(server);
    GoogleTools().register(server);
    ProfileTools().register(server);

    // Partie géolocalisation
    server.registerTool(
      'get_current_location',
      description: '''
          Detects the user's current geographic location based without any arg needed.
          Retourne la latitude, longitude, ville, région, pays et code postal.
          À appeler en premier pour toute question nécessitant une localisation précise
      ''',
      callback: (args, extra) async {
        try {
          final loc = await location.getCurrentLocation();

          return CallToolResult(
            content: [TextContent(text: jsonEncode(loc))],
          );
        } catch (e) {
          return CallToolResult(
            content: [TextContent(text: 'Erreur get_current_location: $e')],
            isError: true,
          );
        }
      },
    );

    try {
      final address = InternetAddress.anyIPv4;
      const port = 3000;
      final httpServer = await HttpServer.bind(address, port);
      log.info('Serveur MCP actif sur http://${httpServer.address.address}:${httpServer.port}');

      httpServer.listen((request) async {

        setCorsHeaders(request.response);

        if (request.method == 'OPTIONS') {
          // Handle CORS preflight request
          request.response.statusCode = HttpStatus.ok;
          await request.response.close();
          return;
        }

        final path = request.uri.path;
        if (path != '/mcp' && path != '/sse' && path != '/messages') {
          // Not an MCP endpoint
          request.response
            ..statusCode = HttpStatus.notFound
            ..write('Not Found')
            ..close();
          return;
        }

        switch (request.method) {
          case 'OPTIONS':
            request.response.statusCode = HttpStatus.ok;
            await request.response.close();
            break;
          case 'POST':
            await handlePostRequest(request, transports, server);
            break;
          case 'GET':
            await handleGetRequest(request, transports);
            break;
          case 'DELETE':
            await handleDeleteRequest(request, transports);
            break;
          default:
            request.response
              ..statusCode = HttpStatus.methodNotAllowed
              ..headers.set(HttpHeaders.allowHeader, 'GET, POST, DELETE, OPTIONS');
            // CORS headers already applied at the top
            request.response
              ..write('Method Not Allowed')
              ..close();
        }
      }, onError: (error) => log.warning('Erreur Serveur: $error'));
    } catch (e) {
      log.warning('Failed to start MCP server: $e');
      rethrow;
    }
  }
}
