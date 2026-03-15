import 'package:mcp_dart/mcp_dart.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:logging/logging.dart' as logging;

final log = logging.Logger('Server');

void setCorsHeaders(HttpResponse response) {
  response.headers.set('Access-Control-Allow-Origin', '*'); // Allow any origin
  response.headers.set('Access-Control-Allow-Methods', 'GET, POST, DELETE, OPTIONS');
  response.headers.set(
    'Access-Control-Allow-Headers',
    'Origin, X-Requested-With, Content-Type, Accept, mcp-session-id, Last-Event-ID, Authorization',
  );
  response.headers.set('Access-Control-Allow-Credentials', 'true');
  response.headers.set('Access-Control-Max-Age', '86400'); // 24 hours
  response.headers.set('Access-Control-Expose-Headers', 'mcp-session-id');
}

// Handle POST requests
Future<void> handlePostRequest(
  HttpRequest request,
  Map<String, StreamableHTTPServerTransport> transports,
  McpServer server,
) async {
  log.info('Received MCP request');

  try {
    // Parse the body
    final bodyBytes = await collectBytes(request);
    final bodyString = utf8.decode(bodyBytes);
    final body = jsonDecode(bodyString);

    // Check for existing session ID
    final sessionId = request.headers.value('mcp-session-id');
    StreamableHTTPServerTransport? transport;

    if (sessionId != null && transports.containsKey(sessionId)) {
      // Reuse existing transport
      transport = transports[sessionId]!;
    } else if (sessionId == null && isInitializeRequest(body)) {
      // New initialization request
      final eventStore = InMemoryEventStore();
      transport = StreamableHTTPServerTransport(
        options: StreamableHTTPServerTransportOptions(
          sessionIdGenerator: () => generateUUID(),
          eventStore: eventStore, // Enable resumability
          onsessioninitialized: (sessionId) {
            // Store the transport by session ID when session is initialized
            log.info('Session initialized with ID: $sessionId');
            transports[sessionId] = transport!;
          },
        ),
      );

      // Set up onclose handler to clean up transport when closed
      transport.onclose = () {
        final sid = transport!.sessionId;
        if (sid != null && transports.containsKey(sid)) {
          log.info(
            'Transport closed for session $sid, removing from transports map',
          );
          transports.remove(sid);
        }
      };

      // Connect the transport to the MCP server BEFORE handling the request
      await server.connect(transport);

      log.info('Handling initialization request for a new session');
      await transport.handleRequest(request, body);
      return; // Already handled
    } else {
      // Invalid request - no session ID or not initialization request
      request.response
        ..statusCode = HttpStatus.badRequest
        ..headers.set(HttpHeaders.contentTypeHeader, 'application/json');
      // Apply CORS headers to this specific response
      setCorsHeaders(request.response);
      request.response.write(
        jsonEncode(
          JsonRpcError(
            id: null,
            error: JsonRpcErrorData(
              code: ErrorCode.connectionClosed.value,
              message:
                  'Bad Request: No valid session ID provided or not an initialization request',
            ),
          ).toJson(),
        ),
      );
      request.response.close();
      return;
    }

    // Handle the request with existing transport
    await transport.handleRequest(request, body);
  } catch (error) {
    log.info('Error handling MCP request: $error');
    // Check if headers are already sent
    bool headersSent = false;
    try {
      headersSent = request.response.headers.contentType
          .toString()
          .startsWith('text/event-stream');
    } catch (_) {
      // Ignore errors when checking headers
    }

    if (!headersSent) {
      request.response
        ..statusCode = HttpStatus.internalServerError
        ..headers.set(HttpHeaders.contentTypeHeader, 'application/json');
      // Apply CORS headers
      setCorsHeaders(request.response);
      request.response.write(
        jsonEncode(
          JsonRpcError(
            id: null,
            error: JsonRpcErrorData(
              code: ErrorCode.internalError.value,
              message: 'Internal Server Error',
            ),
          ).toJson(),
        ),
      );
      request.response.close();
    }
  }
}

// Handle GET requests for SSE streams
Future<void> handleGetRequest(
  HttpRequest request,
  Map<String, StreamableHTTPServerTransport> transports,
) async {
  final sessionId = request.headers.value('mcp-session-id');
  if (sessionId == null || !transports.containsKey(sessionId)) {
    request.response.statusCode = HttpStatus.badRequest;
    // Apply CORS headers
    setCorsHeaders(request.response);
    request.response
      ..write('Invalid or missing session ID')
      ..close();
    return;
  }

  // Check for Last-Event-ID header for resumability
  final lastEventId = request.headers.value('Last-Event-ID');
  if (lastEventId != null) {
    log.info('Client reconnecting with Last-Event-ID: $lastEventId');
  } else {
    log.info('Establishing new SSE stream for session $sessionId');
  }

  final transport = transports[sessionId]!;
  await transport.handleRequest(request);
}

// Handle DELETE requests for session termination
Future<void> handleDeleteRequest(
  HttpRequest request,
  Map<String, StreamableHTTPServerTransport> transports,
) async {
  final sessionId = request.headers.value('mcp-session-id');
  if (sessionId == null || !transports.containsKey(sessionId)) {
    request.response.statusCode = HttpStatus.badRequest;
    // Apply CORS headers
    setCorsHeaders(request.response);
    request.response
      ..write('Invalid or missing session ID')
      ..close();
    return;
  }

  log.info('Received session termination request for session $sessionId');

  try {
    final transport = transports[sessionId]!;
    await transport.handleRequest(request);
  } catch (error) {
    log.info('Error handling session termination: $error');
    // Check if headers are already sent
    bool headersSent = false;
    try {
      headersSent = request.response.headers.contentType
          .toString()
          .startsWith('text/event-stream');
    } catch (_) {
      // Ignore errors when checking headers
    }

    if (!headersSent) {
      request.response.statusCode = HttpStatus.internalServerError;
      // Apply CORS headers
      setCorsHeaders(request.response);
      request.response
        ..write('Error processing session termination')
        ..close();
    }
  }
}

// Function to check if a request is an initialization request
bool isInitializeRequest(dynamic body) {
  if (body is Map<String, dynamic> &&
      body.containsKey('method') &&
      body['method'] == 'initialize') {
    return true;
  }
  return false;
}

// Helper function to collect bytes from an HTTP request
Future<List<int>> collectBytes(HttpRequest request) {
  final completer = Completer<List<int>>();
  final bytes = <int>[];

  request.listen(
    bytes.addAll,
    onDone: () => completer.complete(bytes),
    onError: completer.completeError,
    cancelOnError: true,
  );

  return completer.future;
}