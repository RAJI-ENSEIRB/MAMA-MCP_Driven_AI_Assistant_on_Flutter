import 'dart:async';
import 'package:logging/logging.dart';
import 'package:mcp_dart/mcp_dart.dart' as mcp;
import 'package:google_generative_ai/google_generative_ai.dart' as gga;

final log = Logger('Bridge');

class McpBridge {
  final Completer<mcp.Client> _connectedClient = Completer<mcp.Client>();

  McpBridge() {
    _initConnection();
  }

  Future<void> _initConnection() async {
    log.info('=== _initConnection ==='.padRight(20));
    try {

      final transport = mcp.StreamableHttpClientTransport(
        Uri.parse('http://127.0.0.1:3000/sse')
      );

      final client = mcp.Client(
        mcp.Implementation(name: "mcp-dart-client", version: "1.0.0"),
      );
      
      await client.connect(transport);
      _connectedClient.complete(client);
      
      log.info('Bridge: Connecté au serveur MCP avec succès.');
    } catch (e) {
      log.severe('Bridge Connection Error: $e');
      if (!_connectedClient.isCompleted) {
        _connectedClient.completeError(e);
      }
    }
  }

  Future<void> dispose() async {
    if (_connectedClient.isCompleted) {
      try {
        final client = await _connectedClient.future;
        await client.close();
      } catch (e) {
        log.severe('Error disposing client: $e');
      }
    }
  }

  Future<mcp.Client> get _server async => await _connectedClient.future;

  Future<List<gga.FunctionDeclaration>> getToolsForClient() async {
    log.info('=== getToolsForClient ==='.padRight(20));
    final client = await _server;
    final mcp.ListToolsResult toolsResult = await client.listTools();

    return toolsResult.tools.map((tool) {
      
      return gga.FunctionDeclaration(
        tool.name,
        tool.description ?? '',
        
        _convertToGgaSchema(tool.inputSchema),
      );
    }).toList();
  }

  
  Future<String> callTool(String name, Map<String, dynamic> arguments) async {
    log.info('=== callTool ==='.padRight(20));
    final client = await _server;
    final mcp.CallToolResult result = await client.callTool(
      mcp.CallToolRequest(name: name, arguments: arguments),
    );

    final textContent = result.content
      .whereType<mcp.TextContent>()
      .map((c) => c.text)
      .join('\n');

    return textContent.isEmpty ? "No response from tool" : textContent;
  }

  /// Load complete user profile from all profile tools
  Future<Map<String, dynamic>> loadUserProfile() async {
    log.info('=== loadUserProfile ==='.padRight(20));

    final profile = <String, dynamic>{};

    // List of all profile tools to call
    final profileTools = [
      'get_identity_profile',
      'get_habitat_profile',
      'get_family_profile',
      'get_health_profile',
      'get_profession_profile',
      'get_mobility_profile',
      'get_social_profile',
    ];

    // Call each profile tool and store results
    for (final toolName in profileTools) {
      try {
        final result = await callTool(toolName, {});
        if (result.isNotEmpty && !result.contains('Aucun profil') && !result.contains('Erreur')) {
          profile[toolName] = result;
        }
      } catch (e) {
        log.warning('Error loading $toolName: $e');
      }
    }

    return profile;
  }

  /// Get tools filtered by context keywords
  Future<List<gga.FunctionDeclaration>> getFilteredTools(String userMessage) async {
    log.info('=== getFilteredTools ==='.padRight(20));

    final message = userMessage.toLowerCase();
    final client = await _server;
    final mcp.ListToolsResult toolsResult = await client.listTools();

    // Keywords that trigger specific tools
    final weatherKeywords = [
      'météo', 'temps', 'pluie', 'soleil', 'température', 'climat',
      'sortir', 'dehors', 'extérieur', 'parapluie', 'froid', 'chaud',
      'neige', 'vent', 'orage', 'nuageux', 'ciel'
    ];

    final locationKeywords = [
      'où', 'localisation', 'position', 'lieu', 'endroit', 'sortir',
      'aller', 'partir', 'ville', 'quartier', 'adresse', 'près', 'loin',
      'restaurant', 'café', 'bar', 'cinéma', 'magasin'
    ];

    final sleepKeywords = [
      'sommeil', 'dormi', 'fatigué', 'repos', 'nuit', 'dormir',
      'coucher', 'réveiller', 'insomnie', 'sieste', 'endormir',
      'fatigue', 'reposé', 'épuisé', 'crevé'
    ];

    final menuKeywords = [
      'manger', 'repas', 'nourriture', 'faim', 'menu', 'déjeuner', 'dîner',
      'petit-déjeuner', 'goûter', 'plat', 'cuisine', 'restaurant',
      'recette', 'calories', 'régime', 'nutrition', 'aliment'
    ];

    final activityKeywords = [
      'activité', 'faire', 'proposer', 'idée', 'occuper', 'divertissement',
      'loisir', 'sport', 'sortie', 'balade', 'promenade', 'visite',
      'cinéma', 'théâtre', 'concert', 'exposition', 'musée', 'parc',
      'jeu', 'hobby', 'passe-temps', 'week-end', 'soirée', 'après-midi'
    ];

    // Determine which tools are needed
    final neededTools = <String>{};

    // Check for weather context
    if (weatherKeywords.any((keyword) => message.contains(keyword))) {
      neededTools.addAll(['get_weather', 'get_current_location']);
    }

    // Check for location context
    if (locationKeywords.any((keyword) => message.contains(keyword))) {
      neededTools.add('get_current_location');
    }

    // Check for sleep context
    if (sleepKeywords.any((keyword) => message.contains(keyword))) {
      neededTools.add('get_sleep');
    }

    // Check for menu context
    if (menuKeywords.any((keyword) => message.contains(keyword))) {
      neededTools.add('get_menu');
    }

    // Check for activity context
    if (activityKeywords.any((keyword) => message.contains(keyword))) {
      neededTools.addAll(['get_weather', 'get_current_location', 'get_sleep']);
    }

    // If no specific context, provide basic tools
    if (neededTools.isEmpty) {
      neededTools.addAll(['get_current_location', 'get_weather']);
    }

    // Filter tools based on needed tools
    final filteredTools = toolsResult.tools.where((tool) {
      return neededTools.contains(tool.name) && !tool.name.startsWith('get_') ||
             (tool.name.startsWith('get_') && neededTools.contains(tool.name));
    }).toList();

    log.info('Filtered tools: ${filteredTools.map((t) => t.name).join(", ")}');

    return filteredTools.map((tool) {
      return gga.FunctionDeclaration(
        tool.name,
        tool.description ?? '',
        _convertToGgaSchema(tool.inputSchema),
      );
    }).toList();
  }

  
  gga.Schema _convertToGgaSchema(mcp.JsonSchema inputSchema) {

    final Map<String, dynamic> schemaMap = inputSchema.toJson();
    final dynamic propertiesMap = schemaMap['properties'];
    final dynamic requiredList = schemaMap['required'];

    if (propertiesMap == null || propertiesMap is! Map) {
      return gga.Schema.object(properties: {});
    }
    
    return gga.Schema.object(
      properties: (propertiesMap as Map<String, dynamic>).map((key, value) {        
      
        String desc = "";
        String type = "string";
        if (value is Map && value.containsKey('description')) {
          desc = value['description'].toString();
        }
        if (value is Map && value.containsKey('type')) {
          type = value['type'].toString();
        }
      
        gga.Schema schema;
        switch (type) {
          case 'string':
            schema = gga.Schema.string(description: desc);
            break;
          case 'number':
          case 'integer':
            schema = gga.Schema.number(description: desc);
            break;
          case 'boolean':
            schema = gga.Schema.boolean(description: desc);
            break;
          case 'array':
            schema = gga.Schema.array(description: desc, items: gga.Schema.string());
            break;
          case 'object':
            schema = gga.Schema.object(description: desc, properties: {});
            break;
          default:
            schema = gga.Schema.string(description: desc);
        }
        return MapEntry(key, schema);
      }),
      requiredProperties: (requiredList is List) 
        ? requiredList.cast<String>() 
        : [],
    );
  }
}