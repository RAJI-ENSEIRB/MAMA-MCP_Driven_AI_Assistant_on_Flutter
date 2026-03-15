import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../app_state.dart';
import '../common/app_header.dart';
import '../common/app_footer.dart';
import '../common/audio_to_text.dart';
import '../common/robot_avatar.dart';

import '../../models/chat_message.dart';
import '../../models/conversation.dart';

class _NewConversationDialog extends StatelessWidget {
  const _NewConversationDialog();

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController();
    return AlertDialog(
      title: const Text('Nouvelle discussion'),
      content: TextField(
        controller: controller,
        decoration: const InputDecoration(hintText: 'Nom de la discussion'),
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () {
            final text = controller.text.trim();
            if (text.isNotEmpty) {
              Navigator.of(context).pop(text);
            }
          },
          child: const Text('Créer'),
        ),
      ],
    );
  }
}

class DiscussionListPage extends StatelessWidget {
  const DiscussionListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final convBox = Hive.box<Conversation>('conversations');

    return Scaffold(
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () async {
                    final newName = await showDialog<String>(
                      context: context,
                      builder: (context) => _NewConversationDialog(),
                    );

                    if (newName == null || newName.isEmpty) return;

                    final appState = context.read<MyAppState>();
                    appState.setChatbotMode(false);

                    await appState.createConversation(newName);
                    if (context.mounted) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ConversationPage(clientName: newName),
                        ),
                      );
                    }
                  },
                  icon: Icon(
                    Icons.add,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  label: const Text('Nouvelle'),
                ),
              ],
            ),
          ),
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: convBox.listenable(),
              builder: (context, Box<Conversation> b, _) {
                final conversations = b.values.toList().cast<Conversation>();
                conversations.sort(
                  (a, b) => b.lastUpdated.compareTo(a.lastUpdated),
                );

                if (conversations.isEmpty) {
                  return const Center(
                    child: Text('Aucune discussion pour le moment'),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: conversations.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    final conv = conversations[index];
                    final date = DateFormat(
                      'dd/MM/yyyy HH:mm',
                    ).format(conv.lastUpdated);

                    return Dismissible(
                      key: Key(conv.name),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: Colors.red.shade50,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 16),
                        child: Icon(
                          Icons.delete_outline,
                          color: Colors.red.shade700,
                        ),
                      ),
                      onDismissed: (direction) async {
                        // Delete from Hive
                        final convBox = Hive.box<Conversation>('conversations');
                        final msgBox = Hive.box<ChatMessage>('chat_messages');

                        // Find and remove conversation
                        final convKey = convBox.keys.firstWhere(
                          (key) => convBox.get(key)?.name == conv.name,
                          orElse: () => null,
                        );
                        if (convKey != null) {
                          await convBox.delete(convKey);
                        }

                        // Remove all messages from this conversation
                        final keysToDelete = msgBox.keys
                            .where(
                              (key) => msgBox.get(key)?.clientName == conv.name,
                            )
                            .toList();
                        for (final key in keysToDelete) {
                          await msgBox.delete(key);
                        }

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Discussion "${conv.name}" supprimée',
                              ),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                      child: ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              conv.name.isNotEmpty
                                  ? conv.name[0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        title: Text(conv.name),
                        subtitle: Text(
                          conv.lastMessage,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  date,
                                  style: const TextStyle(fontSize: 12),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${conv.messageCount} messages',
                                  style: const TextStyle(fontSize: 11),
                                ),
                              ],
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              tooltip: 'Ouvrir',
                              icon: Icon(
                                Icons.arrow_forward,
                                color: theme.colorScheme.onSurface,
                              ),
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        ConversationPage(clientName: conv.name),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  ConversationPage(clientName: conv.name),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class ConversationPage extends StatefulWidget {
  final String clientName;

  const ConversationPage({super.key, required this.clientName});

  @override
  State<ConversationPage> createState() => _ConversationPageState();
}

class _ConversationPageState extends State<ConversationPage> {
  final TextEditingController _controller = TextEditingController();
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    // Set the current conversation so askAI() knows which one we're in
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appState = context.read<MyAppState>();
      appState.setChatbotMode(
        false,
      ); // Ensure we're in discussion mode (persistent)
      appState.setCurrentConversation(widget.clientName);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage(String text) {
    final appState = context.read<MyAppState>();
    // Ask AI (which will save both user and assistant messages to Hive)
    appState.askAI(text);

    // Fermer le clavier
    FocusScope.of(context).unfocus();

    // Forcer le scroll vers le bas pour voir la réponse
    // Ajouter un délai pour que le message soit affiché avant de scroller
    Future.delayed(const Duration(milliseconds: 600), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final box = Hive.box<ChatMessage>('chat_messages');
    final appState = context.watch<MyAppState>();
    final theme = Theme.of(context);

    return Scaffold(
      body: Column(
        children: [
          AppHeader(
            pageTitle: "Discussion",
            showBackButton: true,
            robotAvatar: RobotAvatar(
              state: appState,
              theme: theme,
              compact: true,
            ),
            currentIndex: 0,
            onNavigate: (index) {
              Navigator.of(context).pop();
            },
          ),
          // Messages list
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: box.listenable(),
              builder: (context, Box<ChatMessage> b, _) {
                final messages =
                    b.values
                        .whereType<ChatMessage>()
                        .where((m) => m.clientName == widget.clientName)
                        .toList()
                      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                    _scrollController.animateTo(
                      _scrollController.position.maxScrollExtent,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  }
                });

                if (messages.isEmpty) {
                  return const Center(
                    child: Text('Aucun message dans cette conversation'),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(12),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    // Don't show response bubble while AI is responding
                    if (index == messages.length &&
                        (appState.loading || appState.isTyping)) {
                      return const SizedBox.shrink();
                    }

                    final m = messages[index];
                    final isUser = m.role == 'user';
                    return Align(
                      alignment: isUser
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        padding: const EdgeInsets.all(12),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.75,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isUser
                                ? [
                                    theme.colorScheme.primary,
                                    theme.colorScheme.secondary,
                                  ]
                                : [
                                    theme.colorScheme.primary.withOpacity(0.12),
                                    theme.colorScheme.secondary.withOpacity(
                                      0.08,
                                    ),
                                  ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(m.text),
                            const SizedBox(height: 6),
                            Text(
                              DateFormat(
                                'dd/MM/yyyy HH:mm',
                              ).format(m.timestamp),
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          // Chat input area
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                // Input field
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
                          hintText: appState.isListening
                              ? '🎤 Écoute en cours...'
                              : 'Tapez votre message...',
                          hintStyle: TextStyle(color: Colors.grey.shade400),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(16),
                        ),
                        enabled: !appState.isListening,
                        onSubmitted: appState.isReady && !appState.isListening
                            ? (text) {
                                final trimmed = text.trim();
                                if (trimmed.isNotEmpty) {
                                  _sendMessage(trimmed);
                                  _controller.clear();
                                }
                              }
                            : null,
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
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
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: STTW(
                                theme: theme,
                                onTextRecognized: (text) {
                                  setState(() {
                                    _controller.text += text;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    theme.colorScheme.primary,
                                    theme.colorScheme.primary.withOpacity(0.85),
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
                                    appState.isReady && !appState.isListening
                                    ? () {
                                        final text = _controller.text.trim();
                                        if (text.isNotEmpty) {
                                          _sendMessage(text);
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
          AppFooter(
            currentIndex: 0,
            onTap: (i) {
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}
