import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../state/inference_store.dart';
import '../../../../theme/app_theme.dart';
import '../../../../views/widgets/stack_card.dart';

class ModelCard extends StatelessWidget {
  const ModelCard({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<InferenceStore>();
    final params = store.params;
    return StackCard(
      title: 'Model',
      icon: Icons.model_training,
      expanded: store.isCardExpanded('model'),
      onToggle: () => store.toggleCard('model'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Checkpoint',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 4),
          DropdownButtonFormField<String>(
            initialValue: params.model.isEmpty ? null : params.model,
            decoration: const InputDecoration(hintText: 'Select a model'),
            items: [
              for (final m in InferenceStore.models)
                DropdownMenuItem(value: m, child: Text(m)),
            ],
            onChanged: (v) => store.updateParams((p) => p.model = v ?? ''),
          ),
          const SizedBox(height: 12),
          const Text(
            'CLIP Skip',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          Slider(
            value: params.clipSkip,
            min: 1,
            max: 12,
            divisions: 11,
            label: '${params.clipSkip.round()}',
            onChanged: (v) => store.updateParams((p) => p.clipSkip = v),
          ),
          Text(
            '${params.clipSkip.round()}',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
