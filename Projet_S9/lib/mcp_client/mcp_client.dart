import 'package:google_generative_ai/google_generative_ai.dart' as gga;
import 'package:logging/logging.dart';
import 'prompts/general_prompt.dart';
import 'prompts/smart_prompt.dart';
import 'prompts/exemple_prompt.dart';
import 'mcp_bridge.dart';
import '../models/chat_message.dart';

final log = Logger('Client');

class Client {
  final McpBridge _bridge;

  final List<String> fallbackModels;
  final List<String> fallbackApiKeys;

  gga.GenerativeModel? _model;
  String _currentModelName;
  String _currentApiKey;
  final String _clientName;

  final List<gga.Content> convHistory = [];
  static final int historySize = 500;

  // User profile for smart client
  Map<String, dynamic> _userProfile = {};

  // Last user message for context-aware tool filtering
  String _lastUserMessage = "";

  /// Replace the current conversation history with the provided contents.
  /// This is used to load a history from persistent storage (Hive) into the
  /// in-memory conversation used by the model.
  void setConversationHistory(List<gga.Content> contents) {
    convHistory
      ..clear()
      ..addAll(contents);
    // Ensure history size limit
    if (convHistory.length > historySize) {
      convHistory.removeRange(0, convHistory.length - historySize);
    }
  }


  Future<void> loadConversationFromChatMessages(List<ChatMessage> msgs) async {
    // Sort messages chronologically
    msgs.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    // Helper to format a stored timestamp in the same style as getDateTime()
    String _formatDate(DateTime t) {
      final y = t.year;
      final mm = t.month.toString().padLeft(2, '0');
      final dd = t.day.toString().padLeft(2, '0');
      final hh = t.hour.toString().padLeft(2, '0');
      final min = t.minute.toString().padLeft(2, '0');
      return "[${y}-${mm}-${dd} ${hh}:${min}]";
    }


    // Build contents simply: use stored role directly and include a timestamp prefix
    final List<gga.Content> contents = [];
    for (final m in msgs) {
      contents.add(gga.Content(m.role, [gga.TextPart('${_formatDate(m.timestamp)}: ${m.text}')]));
    }

    setConversationHistory(contents);

    // Refresh the model so the loaded systemInstruction (if any) is applied
    await _refreshModel();
  }

  Client({
    required String clientName,
    required this.fallbackModels,
    required this.fallbackApiKeys,
    required McpBridge bridge,
  }) :
  _clientName = clientName,
  _bridge = bridge,
  _currentModelName = fallbackModels.removeAt(0),
  _currentApiKey = fallbackApiKeys.removeAt(0)
  {
    _initializeClient();
  }

  Future<void> _initializeClient() async {
    // Load user profile for smart client
    if (_clientName == "smart") {
      try {
        _userProfile = await _bridge.loadUserProfile();
        log.info('User profile loaded: ${_userProfile.keys.join(", ")}');
      } catch (e) {
        log.warning('Failed to load user profile: $e');
      }
    }
    await _refreshModel();
  }

  Future<String> getSystemPrompt() async {
    log.info('=== getSystemPrompt ==='.padRight(20));

    switch (_clientName) {
      case "general":
        return getGeneralSystemPrompt(getDateTime());
      case "smart":
        return getSmartSystemPrompt(getDateTime(), _userProfile);
      case "Exemple":
        try {
          String info = await _bridge.callTool('get_current_location', {});
          return getExempleSystemPrompt(getDateTime(), info);
        } catch (e) {
          return getExempleSystemPrompt(getDateTime(), "Error: $e");
        }
      default:
        // Use general prompt for discussions and unknown client types
        return getGeneralSystemPrompt(getDateTime());
    }
  }

  Future<void> _refreshModel() async {
    _model = gga.GenerativeModel(
      model: _currentModelName,
      apiKey: _currentApiKey,
      systemInstruction: gga.Content.system(await getSystemPrompt()), 
    );
  }
  Future<String> ask(String userPrompt) async {
    log.info('=== ask ==='.padRight(15));
    await _refreshModel();

    // Store last user message for context-aware tool filtering
    _lastUserMessage = userPrompt;

    // Limit the size of history
    if (convHistory.length > historySize) {
      convHistory.removeRange(0, convHistory.length - historySize);
    }

    // Add user prompt to content
    log.info("[USER]: $userPrompt");
    final userContent = gga.Content.text("${getDateTime()}: $userPrompt");
    convHistory.add(userContent);

    // Response from the AI
    while (true) {
      try {
        final response = await _tryGenerate();

        final modelContent = response.candidates.first.content;
        convHistory.add(modelContent);

        final toolCalls = response.functionCalls;
        if (toolCalls.isEmpty) { // no tool needed: send final response
          log.info("No tool needed, sending final response:");
          log.info("[AI]: ${response.text?.trimLeft() ?? "No text response"}");

          return response.text?.trimLeft() ?? "No text response";
        }

        // Perform each tool call to the server requested by the AI
        var toolResponses = await _handleToolCalls(toolCalls);
        if (toolResponses.isNotEmpty) {    
          final toolContent = gga.Content('tool', toolResponses);
          convHistory.add(toolContent);
        }
      }
      catch (e){
        log.warning(e);
        return "Error: $e";
      }
    }
  }

  String getDateTime() {
    final now = DateTime.now();
    return "[${now.year}-${now.month.toString().padLeft(2,'0')}-${now.day.toString().padLeft(2,'0')} "
            "${now.hour.toString().padLeft(2,'0')}:${now.minute.toString().padLeft(2,'0')}]";
  }

  Future<gga.GenerateContentResponse> _tryGenerate() async {
    log.info('=== _tryGenerate ==='.padRight(15));
    int idxModel = 0;
    int idxKey = 0;

    // candidateCount = 1 makes the answer more stable/often the same
    final config = gga.GenerationConfig(candidateCount: 1); // other args:temperature, maxOutputTokens, topP and topK

    // Recuperate the tools from the server
    // For smart client, use filtered tools based on context
    final List<gga.FunctionDeclaration> declarations = _clientName == "smart" && _lastUserMessage.isNotEmpty
        ? await _bridge.getFilteredTools(_lastUserMessage)
        : await _bridge.getToolsForClient();

    final toolsList = [gga.Tool(functionDeclarations: declarations)];

    while (true) {
      try {
        return await _model!.generateContent(
          convHistory,
          generationConfig: config, 
          tools: toolsList,
          toolConfig: gga.ToolConfig(
            functionCallingConfig: gga.FunctionCallingConfig(
              mode: gga.FunctionCallingMode.auto,
            ),
          ),
        );

      } catch (e) {
        // If there is a problem with the AI response
        log.warning("Model $_currentModelName unavailable: $e"); // .runtimeType
        
        // If there is no more fallback key
        if (idxKey >= fallbackApiKeys.length) {
          throw Exception("API Key cycle exhausted");
        }
        (idxModel, idxKey) = _rotateConfig(idxModel, idxKey);
        await _refreshModel();
      }
    }
  }

  (int, int) _rotateConfig(int idxModel, int idxKey) {
    log.info('=== _rotateConfig ==='.padRight(15));
    // Try another model
    if (fallbackModels.isNotEmpty) {
      final nextModelName = fallbackModels.removeAt(0);
      log.warning("Trying fallback model: $nextModelName");
      fallbackModels.add(_currentModelName);
      _currentModelName = nextModelName;

      idxModel++;
      
      // If there is a problem for all models, try another key
      if (fallbackApiKeys.isNotEmpty && idxModel >= fallbackModels.length) {
        final nextApiKey = fallbackApiKeys.removeAt(0);
        String lastpartKey = nextApiKey.length > 3
          ? nextApiKey.substring(nextApiKey.length - 3)
          : nextApiKey;
        log.warning("Trying fallback key: ***$lastpartKey");

        fallbackApiKeys.add(_currentApiKey);
        _currentApiKey = nextApiKey;

        idxModel = 0;
        idxKey++;
      }
    }
    return (idxModel, idxKey);
  }

  Future<List<gga.FunctionResponse>> _handleToolCalls(Iterable<gga.FunctionCall> toolCalls) async {
    log.info('=== _handleToolCalls ==='.padRight(15));
    var toolResponses = <gga.FunctionResponse>[];

    for (final call in toolCalls) {
      final toolName = call.name;
      final args = Map<String, dynamic>.from(call.args);
      log.info("Calling tool: $toolName with $args");

      String toolResponse;
      try {
        toolResponse = await _bridge.callTool(toolName, args);
      } catch (e) {
        toolResponse = "Error running tool: $e";
      }
      log.info("Tool response: $toolResponse");

      toolResponses.add(gga.FunctionResponse(toolName, {'result': toolResponse}));
    }
    return toolResponses;
  }
}