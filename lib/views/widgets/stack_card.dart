import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class StackCard extends StatelessWidget {
  final String title;
  final IconData? icon;
  final Widget child;
  final bool expanded;
  final VoidCallback? onToggle;
  final List<Widget> headerActions;

  const StackCard({
    super.key,
    required this.title,
    required this.child,
    this.icon,
    this.expanded = true,
    this.onToggle,
    this.headerActions = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 18, color: AppColors.accent),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  ...headerActions,
                  if (onToggle != null)
                    Icon(
                      expanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                ],
              ),
            ),
          ),
          if (expanded) ...[
            const Divider(height: 1),
            Padding(padding: const EdgeInsets.all(14), child: child),
          ],
        ],
      ),
    );
  }
}
