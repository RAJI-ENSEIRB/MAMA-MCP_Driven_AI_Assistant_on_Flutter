import 'package:flutter/material.dart';

class AppFooter extends StatelessWidget {
  final int currentIndex;
  final void Function(int index) onTap;

  const AppFooter({super.key, required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surface,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: theme.dividerColor.withOpacity(0.15)),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _FooterItem(
              icon: Icons.forum_outlined,
              label: 'Discussion',
              isActive: currentIndex == 0,
              onTap: () => onTap(0),
            ),
            _FooterItem(
              icon: Icons.smart_toy_outlined,
              label: 'Chatbot',
              isActive: currentIndex == 1,
              onTap: () => onTap(1),
            ),
            _FooterItem(
              icon: Icons.science_outlined,
              label: 'Démo',
              isActive: currentIndex == 2,
              onTap: () => onTap(2),
            ),
            _FooterItem(
              icon: Icons.person_outline,
              label: 'Profil',
              isActive: currentIndex == 3,
              onTap: () => onTap(3),
            ),
          ],
        ),
      ),
    );
  }
}

class _FooterItem extends StatelessWidget {
  final IconData? icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _FooterItem({
    this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final Color color = isActive
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurface.withOpacity(0.45);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      splashColor: theme.colorScheme.primary.withOpacity(0.15),
      highlightColor: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20, color: color),
              const SizedBox(height: 4),
            ],
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
