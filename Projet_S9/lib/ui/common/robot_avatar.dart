import 'package:flutter/material.dart';
import '../../app_state.dart';

class RobotAvatar extends StatelessWidget {
  final MyAppState state;
  final ThemeData theme;
  final bool compact;

  const RobotAvatar({
    super.key,
    required this.state,
    required this.theme,
    this.compact = true,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = state.loading || state.isTyping;

    if (compact) {
      // Version compacte pour l'appbar
      return AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        width: isActive ? 44 : 40,
        height: isActive ? 44 : 40,
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
                    blurRadius: 12,
                    offset: const Offset(0, 4),
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
                width: 36,
                height: 36,
                fit: BoxFit.cover,
              ),
            ),
            if (isActive)
              Positioned(
                bottom: 4,
                child: Row(
                  children: List.generate(3, (i) {
                    final delay = i * 120;
                    return AnimatedContainer(
                      duration: Duration(milliseconds: 300 + delay),
                      margin: const EdgeInsets.symmetric(horizontal: 1.5),
                      width: 4,
                      height: 4,
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
      );
    } else {
      // Version full pour la page chatbot
      return Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 240),
            width: isActive ? 54 : 50,
            height: isActive ? 54 : 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.secondary,
                ],
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
                isActive
                    ? state.loading
                          ? "L'assistant réfléchit..."
                          : "Rédaction en cours..."
                    : "Prêt",
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
}
