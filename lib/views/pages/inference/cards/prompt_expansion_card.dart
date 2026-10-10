import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../state/inference_store.dart';
import '../../../../theme/app_theme.dart';
import '../../../../views/widgets/stack_card.dart';

class PromptExpansionCard extends StatefulWidget {
  const PromptExpansionCard({super.key});

  @override
  State<PromptExpansionCard> createState() => _PromptExpansionCardState();
}

class _PromptExpansionCardState extends State<PromptExpansionCard> {
  bool enabled = false;
  String style = 'Danbooru Tags';
  double creativity = 0.5;

  static const styles = [
    'Danbooru Tags',
    'Natural Language',
    'Photography',
    'Digital Art',
  ];

  @override
  Widget build(BuildContext context) {
    final store = context.watch<InferenceStore>();
    return StackCard(
      title: 'Prompt Expansion',
      icon: Icons.auto_fix_high,
      expanded: store.isCardExpanded('promptExpansion'),
      onToggle: () => store.toggleCard('promptExpansion'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Enabled', style: TextStyle(fontSize: 13)),
              const Spacer(),
              Switch(
                value: enabled,
                onChanged: (v) => setState(() => enabled = v),
              ),
            ],
          ),
          if (enabled) ...[
            const Text(
              'Expansion Style',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 4),
            DropdownButtonFormField<String>(
              initialValue: style,
              items: [
                for (final s in styles)
                  DropdownMenuItem(value: s, child: Text(s)),
              ],
              onChanged: (v) => setState(() => style = v ?? style),
            ),
            const SizedBox(height: 12),
            Text(
              'Creativity: ${creativity.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            Slider(
              value: creativity,
              min: 0,
              max: 1,
              onChanged: (v) => setState(() => creativity = v),
            ),
          ],
        ],
      ),
    );
  }
}
