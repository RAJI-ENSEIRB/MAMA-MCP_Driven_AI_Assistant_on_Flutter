import 'package:flutter/material.dart';

class AppHeader extends StatelessWidget {
  final String pageTitle;
  final Widget? action;
  final bool showBackButton;
  final int? currentIndex;
  final Function(int)? onNavigate;
  final Widget? robotAvatar;

  const AppHeader({
    super.key,
    required this.pageTitle,
    this.action,
    this.showBackButton = false,
    this.currentIndex,
    this.onNavigate,
    this.robotAvatar,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.primary.withOpacity(0.15),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Titre de page avec icône Discussion sur Chatbot
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (showBackButton)
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Icon(
                        Icons.arrow_back_rounded,
                        color: Colors.black,
                        size: 24,
                      ),
                    )
                  else
                    const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          pageTitle,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        // Sous-titre
                        Text(
                          'Mobile AI MCP Assistant',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.black.withOpacity(0.6),
                            letterSpacing: 0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  if (robotAvatar != null)
                    robotAvatar!
                  else
                    const SizedBox(width: 24),
                ],
              ),
              if (action != null) const SizedBox(height: 12),
              if (action != null)
                DefaultTextStyle(
                  style: const TextStyle(color: Colors.black),
                  child: action!,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
