import 'dart:async';

import 'package:flutter/material.dart';
import 'mcp_client/mcp_client.dart';
import 'mcp_client/mcp_bridge.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logging/logging.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:hive/hive.dart';
import 'models/chat_message.dart';
import 'models/conversation.dart';
import 'package:google_generative_ai/google_generative_ai.dart' as gga;

final log = Logger('AppState');

class MyAppState extends ChangeNotifier {
  late Client _client;
  bool _isReady = false;
  String _response = "";
  String _currentClient = "general"; // default prompt
  final McpBridge bridge = McpBridge();
  bool _isTyping = false;
  bool _loading = false;
  Timer? _typingTimer;
  bool _isChatbotMode =
      false; // True when in chatbot tab (ephemeral), False in discussion tab (persistent)

  // Simple storage for chatbot - just keep last question
  String _lastChatbotQuestion = "";
  String get lastChatbotQuestion => _lastChatbotQuestion;

  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  bool _isListening = false;
  String _lastWords = "";
  bool get isListening => _isListening;
  String get lastWords => _lastWords;
  bool get isTyping => _isTyping;
  bool get loading => _loading;

  final List<String> promptNames = [
    "general",
    "smart",
    //"exemple",
  ]; // List of all prompts

  String get response => _response;
  bool get isReady => _isReady;
  String get currentClient => _currentClient;
  bool get isChatbotMode => _isChatbotMode;

  /// Set whether we're in chatbot mode (ephemeral) or discussion mode (persistent)
  void setChatbotMode(bool isChatbot) {
    _isChatbotMode = isChatbot;
    // Clear chatbot state when leaving chatbot mode
    if (!isChatbot) {
      _lastChatbotQuestion = "";
      _response = "";
    }
    notifyListeners();
  }

  MyAppState() {
    _init();
    _initSpeech();
  }

  Future<void> _init() async {
    log.info('=== _init ==='.padRight(20));
    await loadClient(_currentClient);
  }

  Future<void> loadClient(String clientName) async {
    log.info('${'=== loadClient ==='.padRight(20)} (client: $clientName)');

    _isReady = false;
    setResponse("⏳ Chargement du client $clientName...");

    try {
      // Read AI models and API keys from .env
      // add your api keys in the .env file in root (API_KEY_X=...)
      List<String> keys = _getFromEnv("API_KEY");
      List<String> models = _getFromEnv("MODEL");

      _client = Client(
        clientName: clientName,
        fallbackModels: models,
        fallbackApiKeys: keys,
        bridge: bridge,
      );

      _currentClient = clientName;
      _isReady = true;
      setResponse("Client $clientName prêt");
    } catch (e) {
      setResponse("Erreur lors du chargement du client");
      log.warning("$e");
    }
  }

  List<String> _getFromEnv(String prefix) {
    final uniqueValues = <String>{};
    List<String> results = dotenv.env.entries
        .where((entry) => entry.key.startsWith(prefix))
        .map((entry) => entry.value)
        .where((value) => value.isNotEmpty && uniqueValues.add(value))
        .toList();
    if (results.isEmpty) {
      throw Exception("$prefix manquante dans .env");
    }
    return results;
  }

  Future<void> askAI(String prompt) async {
    log.info('=== askAI ==='.padRight(20));

    if (!_isReady) {
      setResponse("⏳ Initialisation de l'IA...");
      return;
    }

    // Handle user message storage based on mode
    if (_isChatbotMode) {
      // Chatbot mode: just store the last question (ephemeral)
      _lastChatbotQuestion = prompt;
    } else {
      // Discussion mode: persist to Hive
      // If the current client is still a default prompt (no conversation loaded),
      // create a new conversation automatically and switch to it.
      // EXCEPTION: Keep "smart" client active to preserve loaded profile
      try {
        final convBox = Hive.box<Conversation>('conversations');
        final isPromptClient = promptNames.contains(_currentClient);
        final exists = convBox.values.any((c) => c.name == _currentClient);

        // Don't switch away from "smart" client - keep it to preserve profile
        if (_currentClient != "smart" && (isPromptClient || !exists)) {
          // create a new unique conversation name and switch to it
          final newName = 'Discussion_${DateTime.now().millisecondsSinceEpoch}';
          await createConversation(newName);
          await loadClient(newName);
        }
      } catch (e) {
        log.info('Could not auto-create/switch conversation: $e');
      }

      // Persist the user's message
      try {
        final box = Hive.box<ChatMessage>('chat_messages');
        await box.add(
          ChatMessage(
            role: 'user',
            text: prompt,
            timestamp: DateTime.now(),
            clientName: _currentClient,
          ),
        );
        // update conversation metadata
        try {
          await _updateConversationOnNewMessage(_currentClient, prompt);
        } catch (e) {
          log.warning('Failed to update conversation metadata (user): $e');
        }
      } catch (e) {
        log.warning('Failed to persist user message: $e');
      }
    }

    try {
      _loading = true;
      _isTyping = false;
      _cancelTyping();
      setResponse("Je réfléchis...");
      notifyListeners();

      // Load all messages from OTHER conversations to give AI full context
      if (!_isChatbotMode) {
        await _loadOtherConversationsContext();
      }

      final res = await _client.ask(prompt);
      _loading = false;

      // Store assistant response based on mode
      if (_isChatbotMode) {
        // Chatbot mode: response is already in _response via typewriter
        // Nothing to do, just let the UI display it
      } else {
        // Discussion mode: persist to Hive
        try {
          final box = Hive.box<ChatMessage>('chat_messages');
          await box.add(
            ChatMessage(
              role: 'assistant',
              text: res,
              timestamp: DateTime.now(),
              clientName: _currentClient,
            ),
          );
          // update conversation metadata for assistant message
          try {
            await _updateConversationOnNewMessage(_currentClient, res);
          } catch (e) {
            log.warning(
              'Failed to update conversation metadata (assistant): $e',
            );
          }
        } catch (e) {
          log.warning('Failed to persist assistant message: $e');
        }
      }
      _startTypewriter(res);
    } catch (e, stack) {
      log.warning("Error askAI: $e\n$stack");
      setResponse("Erreur lors de la demande à l'IA");
      _loading = false;
      _isTyping = false;
      _cancelTyping();
      notifyListeners();
    }
  }

  void setResponse(String newValue) {
    _response = newValue;
    notifyListeners();
  }

  void clearResponse() {
    _response = "";
    _loading = false;
    _isTyping = false;
    _cancelTyping();
    notifyListeners();
  }

  void _startTypewriter(String fullText) {
    _cancelTyping();
    _response = "";
    _isTyping = true;
    notifyListeners();

    int index = 0;
    _typingTimer = Timer.periodic(const Duration(milliseconds: 14), (timer) {
      if (index >= fullText.length) {
        timer.cancel();
        _isTyping = false;
        _response = fullText;
        notifyListeners();
        return;
      }
      index++;
      _response = fullText.substring(0, index);
      notifyListeners();
    });
  }

  void _cancelTyping() {
    _typingTimer?.cancel();
    _typingTimer = null;
  }

  Future<void> _initSpeech() async {
    log.info('=== _initSpeech ==='.padRight(15));
    try {
      _speechEnabled = await _speechToText.initialize(
        onStatus: (status) {
          log.info("Speech status: $status");
          if (status == 'listening') {
            _isListening = true;
          } else if (status == 'notListening' || status == 'done') {
            _isListening = false;
          }
          notifyListeners();
        },
        onError: (error) {
          log.severe("Speech Error: $error");
          _isListening = false;
          notifyListeners();
        },
      );
      notifyListeners();
    } catch (e) {
      log.warning("Could not initialize speech: $e");
    }
  }

  // Start listening to user
  Future<void> startListening() async {
    log.info('=== startListening ==='.padRight(15));
    if (_isListening) return;

    if (!_speechEnabled) {
      setResponse("Tentative de ré-initialisation du micro...");
      await _initSpeech();
      if (!_speechEnabled) {
        setResponse("Le micro n'est pas activé. Vérifiez les permissions.");
        return;
      }
    }

    try {
      _lastWords = "";
      await _speechToText.listen(
        onResult: (result) {
          _lastWords = result.recognizedWords;
          notifyListeners();
        },
        localeId: "fr_FR",
        listenOptions: SpeechListenOptions(
          listenMode: ListenMode.dictation,
          cancelOnError: true,
          partialResults: true,
        ),
      );
    } catch (e) {
      _isListening = false;
      setResponse("Erreur d'enregistrement: $e");
    }
  }

  Future<void> stopAndSendRecording() async {
    log.info('=== stopAndSendRecording ==='.padRight(15));
    if (!_isListening) return;

    try {
      await _speechToText.stop();
    } finally {
      _isListening = false;
      notifyListeners();
    }

    if (_lastWords.trim().isEmpty) {
      setResponse("Aucune parole détectée");
      return;
    }

    try {
      await askAI(_lastWords);
      _lastWords = "";
      notifyListeners();
    } catch (e) {
      setResponse("Erreur lors de l'envoi à l'IA: $e");
    }
  }

  /// Create a new conversation entry and an initial system message.
  Future<void> createConversation(String name) async {
    final convBox = Hive.box<Conversation>('conversations');
    // avoid duplicates
    final exists = convBox.values.any((c) => c.name == name);
    if (exists) return;

    final now = DateTime.now();
    final conv = Conversation(
      id: 'conv_${now.millisecondsSinceEpoch}',
      name: name,
      createdAt: now,
      lastUpdated: now,
      lastMessage: 'Conversation créée',
      messageCount: 0,
    );
    await convBox.add(conv);

    // add initial system message to messages box
    final msgBox = Hive.box<ChatMessage>('chat_messages');
    await msgBox.add(
      ChatMessage(
        role: 'system',
        text: 'Conversation créée',
        timestamp: now,
        clientName: name,
      ),
    );

    // update metadata to reflect the initial message
    await _updateConversationOnNewMessage(name, 'Conversation créée');
  }

  Future<void> _updateConversationOnNewMessage(
    String name,
    String lastMessage,
  ) async {
    final convBox = Hive.box<Conversation>('conversations');
    dynamic foundKey;
    Conversation? found;
    for (final key in convBox.keys) {
      final c = convBox.get(key);
      if (c != null && c.name == name) {
        foundKey = key;
        found = c;
        break;
      }
    }
    final now = DateTime.now();
    if (found != null && foundKey != null) {
      final updated = Conversation(
        id: found.id,
        name: found.name,
        createdAt: found.createdAt,
        lastUpdated: now,
        lastMessage: lastMessage,
        messageCount: found.messageCount + 1,
      );
      await convBox.put(foundKey, updated);
    } else {
      // create if missing
      final conv = Conversation(
        id: 'conv_${now.millisecondsSinceEpoch}',
        name: name,
        createdAt: now,
        lastUpdated: now,
        lastMessage: lastMessage,
        messageCount: 1,
      );
      await convBox.add(conv);
    }
  }

  /// Load a conversation (by clientName) from Hive and replace the client's
  /// conversation history so subsequent asks use this context.
  Future<void> loadConversationToClient(String clientName) async {
    try {
      final box = Hive.box<ChatMessage>('chat_messages');
      final msgs = box.values
          .whereType<ChatMessage>()
          .where((m) => m.clientName == clientName)
          .toList();

      if (msgs.isEmpty) {
        setResponse("Aucune discussion trouvée pour: $clientName");
        return;
      }

      // Convert and load into client (await the async loader so model refresh completes)
      await _client.loadConversationFromChatMessages(msgs);

      // Update the current client so askAI() uses this conversation
      _currentClient = clientName;

      setResponse("Conversation chargée: $clientName");
      notifyListeners();
    } catch (e, st) {
      log.warning('Failed to load conversation: $e\n$st');
      setResponse('Erreur lors du chargement de la conversation');
    }
  }

  /// Load all messages from OTHER conversations to provide context
  Future<void> _loadOtherConversationsContext() async {
    try {
      final box = Hive.box<ChatMessage>('chat_messages');
      final convBox = Hive.box<Conversation>('conversations');
      final allMessages = box.values.whereType<ChatMessage>().toList();

      // Get list of valid conversation names (still existing in Hive)
      final validConversationNames = convBox.values
          .whereType<Conversation>()
          .map((c) => c.name)
          .toSet();

      // Group by conversation (clientName), but only include valid conversations
      final Map<String, List<ChatMessage>> conversationsByName = {};
      for (final msg in allMessages) {
        if (msg.clientName != _currentClient &&
            validConversationNames.contains(msg.clientName)) {
          conversationsByName.putIfAbsent(msg.clientName, () => []);
          conversationsByName[msg.clientName]!.add(msg);
        }
      }

      if (conversationsByName.isEmpty) {
        return; // No other conversations
      }

      // Build context string from other conversations
      final contextBuffer = StringBuffer();
      contextBuffer.writeln("\n--- Contexte des autres conversations ---");

      for (final convName in conversationsByName.keys) {
        final msgs = conversationsByName[convName]!;
        msgs.sort((a, b) => a.timestamp.compareTo(b.timestamp));

        contextBuffer.writeln("\nConversation: $convName");
        for (final msg in msgs.take(10)) {
          // Take last 10 messages per conversation
          final role = msg.role == 'user' ? 'Utilisateur' : 'Assistant';
          contextBuffer.writeln("$role: ${msg.text}");
        }
      }

      contextBuffer.writeln("\n--- Fin du contexte ---\n");

      // Inject context into the model's system prompt via a special message
      // This will be prepended to the conversation history
      final contextMessage = gga.Content.text(contextBuffer.toString());
      _client.convHistory.insert(0, contextMessage);
    } catch (e) {
      log.warning('Failed to load other conversations context: $e');
    }
  }

  /// Lightweight method to just set the current conversation without loading full history
  void setCurrentConversation(String clientName) {
    _currentClient = clientName;
    notifyListeners();
  }

  @override
  void dispose() {
    _cancelTyping();
    super.dispose();
  }
}
