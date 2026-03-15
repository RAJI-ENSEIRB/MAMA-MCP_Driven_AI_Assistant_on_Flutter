// lib/ui/home/simple_chatbot_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app_state.dart';
import '../common/audio_to_text.dart';

class SimpleChatbotPage extends StatefulWidget {
  const SimpleChatbotPage({super.key});

  @override
  State<SimpleChatbotPage> createState() => _SimpleChatbotPageState();
}

class _SimpleChatbotPageState extends State<SimpleChatbotPage> {
  final TextEditingController _controller = TextEditingController();
  String _textListened = '';

  @override
  void initState() {
    super.initState();
    // Enable chatbot mode immediately (ephemeral conversations)
    Future.microtask(() {
      if (mounted) {
        context.read<MyAppState>().setChatbotMode(true);
      }
    });
  }

  @override
  void dispose() {
    // Disable chatbot mode when leaving
    try {
      context.read<MyAppState>().setChatbotMode(false);
    } catch (e) {
      // Context may no longer be available
    }
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<MyAppState>();
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildAssistantAvatar(theme, state),
                    const SizedBox(height: 16),
                    // Display last question if exists
                    if (state.lastChatbotQuestion.isNotEmpty)
                      Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          padding: const EdgeInsets.all(12),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.75,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                theme.colorScheme.primary,
                                theme.colorScheme.secondary,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            state.lastChatbotQuestion,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                    // Display current response
                    if (state.response.isNotEmpty)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          padding: const EdgeInsets.all(12),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.75,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                theme.colorScheme.primary.withOpacity(0.12),
                                theme.colorScheme.secondary.withOpacity(0.08),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            state.response,
                            style: const TextStyle(
                              color: Color(0xFF1F2937),
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    // Chat input field
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          TextField(
                            controller: _controller,
                            autocorrect: false,
                            enableSuggestions: false,
                            maxLines: 4,
                            minLines: 1,
                            decoration: InputDecoration(
                              hintText: state.isListening
                                  ? '🎤 Écoute en cours...'
                                  : 'Tapez votre message...',
                              hintStyle: TextStyle(color: Colors.grey.shade400),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.all(20),
                            ),
                            enabled: !state.isListening,
                            onSubmitted: state.isReady && !state.isListening
                                ? (text) {
                                    final trimmed = text.trim();
                                    if (trimmed.isNotEmpty) {
                                      state.askAI(trimmed);
                                      _controller.clear();
                                    }
                                  }
                                : null,
                          ),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(20),
                                bottomRight: Radius.circular(20),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: state.isListening
                                        ? Colors.red.shade50
                                        : theme.colorScheme.primary.withOpacity(
                                            0.1,
                                          ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: /*IconButton(
                                  icon: Icon(
                                    state.isListening
                                        ? Icons.stop_rounded
                                        : Icons.mic_rounded,
                                    color: state.isListening
                                        ? Colors.red
                                        : theme.colorScheme.primary,
                                  ),
                                  onPressed: state.isReady
                                      ? () {
                                          if (state.isListening) {
                                            state.stopAndSendRecording();
                                          } else {
                                            state.startListening();
                                          }
                                        }
                                      : null,
                                ),*/ STTW(
                                    theme: theme,
                                    onTextRecognized: (text) {
                                      print("New text registered" + text);
                                      setState(() {
                                        _controller.text += text;
                                      });
                                      print(_textListened);
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        theme.colorScheme.primary,
                                        theme.colorScheme.primary.withOpacity(
                                          0.85,
                                        ),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: theme.colorScheme.primary
                                            .withOpacity(0.35),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.send_rounded,
                                      color: Colors.white,
                                    ),
                                    onPressed:
                                        state.isReady && !state.isListening
                                        ? () {
                                            final text = _controller.text
                                                .trim();
                                            if (text.isNotEmpty) {
                                              state.askAI(text);
                                              _controller.clear();
                                            }
                                          }
                                        : null,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssistantAvatar(ThemeData theme, MyAppState state) {
    final isActive = state.loading || state.isTyping;
    final statusText = state.loading
        ? "L'assistant réfléchit..."
        : state.isTyping
        ? "Rédaction en cours..."
        : "Prêt";

    return Row(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          width: isActive ? 54 : 50,
          height: isActive ? 54 : 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: theme.colorScheme.primary.withOpacity(0.35),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : [],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              ClipOval(
                child: Image.asset(
                  state.loading
                      ? 'lib/assets/mascot_reflect.png'
                      : state.isTyping
                      ? 'lib/assets/mascot_speak.png'
                      : 'lib/assets/mascot_idle.png',
                  width: 46,
                  height: 46,
                  fit: BoxFit.cover,
                ),
              ),
              if (isActive)
                Positioned(
                  bottom: 6,
                  child: Row(
                    children: List.generate(3, (i) {
                      final delay = i * 120;
                      return AnimatedContainer(
                        duration: Duration(milliseconds: 300 + delay),
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9 - (i * 0.2)),
                          shape: BoxShape.circle,
                        ),
                      );
                    }),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Assistant',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.primary,
              ),
            ),
            Text(
              statusText,
              style: TextStyle(
                color: theme.colorScheme.onSurface.withOpacity(0.65),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
