import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app_state.dart';
import '../profile/new_profile_page.dart';
import '../common/app_header.dart';
import '../common/app_footer.dart';
import '../common/robot_avatar.dart';
import 'simple_chatbot_page.dart';
import '../discussion/discussion_page.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 1; // Chatbot par défaut
  final TextEditingController _controller = TextEditingController();
  int _selectedScenarioIndex = 1;

  Map<int, List<(String, IconData)>> get _scenarioPrompts => {
    1: [
      ("Quel temps fait-il aujourd'hui ?", Icons.wb_cloudy),
      ("Va-t-il pleuvoir cet après-midi ?", Icons.water_drop),
      ("Quelle est la météo de demain ?", Icons.wb_cloudy),
      ("Dois-je prévoir un parapluie ?", Icons.water_drop),
    ],
    2: [
      ("Je veux courir 30 minutes", Icons.directions_run),
      ("Planifie une séance de sport", Icons.fitness_center),
      ("Quel est mon objectif fitness ?", Icons.flag),
    ],
    3: [
      ("Je suis crevée", Icons.bedtime),
      ("Je viens de me lever", Icons.alarm),
      ("Aide-moi pour mon sommeil", Icons.bedtime),
    ],
    4: [
      ("J'ai faim, des idées ?", Icons.restaurant),
      ("Pizza ou salade ?", Icons.local_pizza),
      ("Propose un repas rapide", Icons.fastfood),
    ],
    5: [
      ("Je dois faire la lessive", Icons.local_laundry_service),
      ("Puis-je mettre le linge dehors ?", Icons.wb_sunny),
      ("Rappelle-moi le cycle de lavage", Icons.autorenew),
    ],
    6: [
      ("J'ai eu une journée horrible", Icons.mood_bad),
      ("Je suis stressée", Icons.mood_bad),
      ("Aide-moi à me détendre", Icons.spa),
    ],
    7: [
      ("Je ne me sens pas bien", Icons.medical_services),
      ("J'ai mal à la tête", Icons.medical_services),
      ("Je suis fatiguée", Icons.bedtime),
    ],
    8: [
      ("Quel est le numéro de Julie ?", Icons.person_search),
      ("Montre-moi mes contacts", Icons.contacts),
      ("Est-ce que Marc est dans mes contacts ?", Icons.person_search),
    ],
  };

  List<Widget> get _screens => [
    const DiscussionListPage(),
    const SimpleChatbotPage(),
    _buildDemoPage(),
    const NewProfileTab(),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<MyAppState>();
    final theme = Theme.of(context);

    return Scaffold(
      body: Column(
        children: [
          AppHeader(
            pageTitle: _selectedIndex == 0
                ? 'Discussion'
                : _selectedIndex == 1
                ? 'Chatbot'
                : _selectedIndex == 2
                ? 'Démonstration'
                : 'Profil',
            robotAvatar: RobotAvatar(state: state, theme: theme, compact: true),
            currentIndex: _selectedIndex,
            onNavigate: (index) {
              if (index == 0 || index == 1) {
                setState(() => _selectedIndex = index);
              }
            },
          ),
          Expanded(child: _screens[_selectedIndex]),
          AppFooter(
            currentIndex: _selectedIndex,
            onTap: (i) => setState(() => _selectedIndex = i),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // PAGE DÉMONSTRATION (OUTIL INTERNE)
  // ---------------------------------------------------------------------------
  Widget _buildDemoPage() {
    final state = context.watch<MyAppState>();
    final prompts = _scenarioPrompts[_selectedScenarioIndex] ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSelectionSection<String>(
            title: 'Client',
            items: state.promptNames,
            selectedItem: state.currentClient,
            state: state,
            labelBuilder: (name) => name,
            onSelected: (name) => state.loadClient(name),
          ),

          _buildSelectionSection<int>(
            title: 'Scénario',
            items: _scenarioPrompts.keys.toList(),
            selectedItem: _selectedScenarioIndex,
            state: state,
            labelBuilder: (index) => 'Scénario $index',
            onSelected: (index) =>
                setState(() => _selectedScenarioIndex = index),
          ),

          _section(
            context,
            title: 'Prompts',
            child: _buildPromptList(prompts, state),
          ),

          _section(
            context,
            title: 'Question libre',
            child: _buildFreeInputField(state),
          ),

          if (state.response.isNotEmpty)
            _section(
              context,
              title: 'Réponse',
              child: _buildResponseDisplay(state.response),
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION HELPER
  // ---------------------------------------------------------------------------
  Widget _section(
    BuildContext context, {
    required String title,
    required Widget child,
  }) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.primary.withOpacity(0.12),
              ),
            ),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionSection<T>({
    required String title,
    required List<T> items,
    required T selectedItem,
    required MyAppState state,
    required String Function(T) labelBuilder,
    required void Function(T) onSelected,
  }) {
    final theme = Theme.of(context);
    final chipTextStyle = theme.textTheme.bodyMedium?.copyWith(
      fontWeight: FontWeight.w600,
    );

    return _section(
      context,
      title: title,
      child: Wrap(
        spacing: 24,
        runSpacing: 16,
        children: items.map((item) {
          final isSelected = item == selectedItem;
          return ChoiceChip(
            label: Text(labelBuilder(item)),
            selected: isSelected,
            onSelected: (state.isReady && !state.loading)
                ? (selected) => onSelected(item)
                : null,
            labelStyle: chipTextStyle?.copyWith(
              color: isSelected
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.primary,
            ),
            selectedColor: theme.colorScheme.primary,
            backgroundColor: theme.colorScheme.primary.withOpacity(0.08),
            side: BorderSide(
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.primary.withOpacity(0.25),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPromptList(List<(String, IconData)> prompts, MyAppState state) {
    final theme = Theme.of(context);
    return Column(
      children: prompts.map((item) {
        final (q, icon) = item;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: (state.isReady && !state.loading)
                ? () => state.askAI(q)
                : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: theme.colorScheme.primary.withOpacity(0.15),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  _buildPromptIcon(icon),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      q,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // Sous-composant pour l'icône du prompt
  Widget _buildPromptIcon(IconData icon) {
    final theme = Theme.of(context);
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: theme.colorScheme.primary, size: 16),
    );
  }

  Widget _buildFreeInputField(MyAppState state) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.18)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              enabled: !state.loading,
              minLines: 1,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: state.loading
                    ? 'L\'IA réfléchit...'
                    : 'Tapez votre question…',
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(16),
              ),
            ),
          ),
          _buildSendButton(state),
        ],
      ),
    );
  }

  Widget _buildSendButton(MyAppState state) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: (state.isReady && !state.loading)
              ? [
                  theme.colorScheme.primary,
                  theme.colorScheme.primary.withOpacity(0.85),
                ]
              : [Colors.grey, Colors.grey.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        icon: const Icon(Icons.send_rounded, color: Colors.white),
        onPressed: (state.isReady && !state.loading)
            ? () {
                final text = _controller.text.trim();
                if (text.isNotEmpty) {
                  state.askAI(text);
                  _controller.clear();
                }
              }
            : null,
      ),
    );
  }

  Widget _buildResponseDisplay(String response) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withOpacity(0.12),
            theme.colorScheme.secondary.withOpacity(0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.25)),
      ),
      child: Text(response, style: const TextStyle(height: 1.6)),
    );
  }
}
