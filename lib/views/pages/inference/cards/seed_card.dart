import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../state/inference_store.dart';
import '../../../../theme/app_theme.dart';
import '../../../../views/widgets/stack_card.dart';

class SeedCard extends StatelessWidget {
  const SeedCard({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<InferenceStore>();
    final params = store.params;
    return StackCard(
      title: 'Seed',
      icon: Icons.tag,
      expanded: store.isCardExpanded('seed'),
      onToggle: () => store.toggleCard('seed'),
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              key: ValueKey('seed-${params.seed}'),
              initialValue: '${params.seed}',
              decoration: const InputDecoration(
                labelText: 'Seed',
                hintText: '-1 for random',
              ),
              keyboardType: TextInputType.number,
              onChanged: (v) {
                final parsed = int.tryParse(v);
                if (parsed != null) {
                  store.updateParams((p) => p.seed = parsed);
                }
              },
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Random seed',
            onPressed: store.randomizeSeed,
            icon: const Icon(Icons.casino, color: AppColors.accent),
          ),
          IconButton(
            tooltip: 'Reset to random',
            onPressed: () => store.updateParams((p) => p.seed = -1),
            icon: const Icon(Icons.restart_alt, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
