import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../state/inference_store.dart';
import '../../../../theme/app_theme.dart';
import '../../../../views/widgets/number_field.dart';
import '../../../../views/widgets/stack_card.dart';

class SamplerCard extends StatelessWidget {
  const SamplerCard({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<InferenceStore>();
    final params = store.params;
    return StackCard(
      title: 'Sampler',
      icon: Icons.shuffle,
      expanded: store.isCardExpanded('sampler'),
      onToggle: () => store.toggleCard('sampler'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Sampler',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<String>(
                      initialValue: params.sampler,
                      items: [
                        for (final s in InferenceStore.samplers)
                          DropdownMenuItem(value: s, child: Text(s)),
                      ],
                      onChanged: (v) =>
                          store.updateParams((p) => p.sampler = v ?? p.sampler),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Scheduler',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<String>(
                      initialValue: params.scheduler,
                      items: [
                        for (final s in InferenceStore.schedulers)
                          DropdownMenuItem(value: s, child: Text(s)),
                      ],
                      onChanged: (v) => store.updateParams(
                        (p) => p.scheduler = v ?? p.scheduler,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Steps: ${params.steps}',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          Slider(
            value: params.steps.toDouble(),
            min: 1,
            max: 150,
            divisions: 149,
            onChanged: (v) => store.updateParams((p) => p.steps = v.round()),
          ),
          Text(
            'CFG Scale: ${params.cfgScale.toStringAsFixed(1)}',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          Slider(
            value: params.cfgScale,
            min: 1,
            max: 30,
            divisions: 58,
            onChanged: (v) => store.updateParams((p) => p.cfgScale = v),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: NumberField(
                  label: 'Width',
                  value: params.width,
                  min: 64,
                  max: 4096,
                  onChanged: (v) => store.updateParams((p) => p.width = v),
                ),
              ),
              Expanded(
                child: NumberField(
                  label: 'Height',
                  value: params.height,
                  min: 64,
                  max: 4096,
                  onChanged: (v) => store.updateParams((p) => p.height = v),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
