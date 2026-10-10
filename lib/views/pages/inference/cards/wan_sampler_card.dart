import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../state/inference_store.dart';
import '../../../../theme/app_theme.dart';
import '../../../../views/widgets/stack_card.dart';

class WanSamplerCard extends StatelessWidget {
  const WanSamplerCard({super.key});

  static const wanSamplers = [
    'euler',
    'euler_ancestral',
    'uni_pc',
    'dpmpp_2m',
    'ddim',
    'lcm',
  ];

  @override
  Widget build(BuildContext context) {
    final store = context.watch<InferenceStore>();
    final params = store.params;
    return StackCard(
      title: 'Sampler',
      icon: Icons.shuffle,
      expanded: store.isCardExpanded('wanSampler'),
      onToggle: () => store.toggleCard('wanSampler'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sampler',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 4),
          DropdownButtonFormField<String>(
            initialValue: wanSamplers.first,
            items: [
              for (final s in wanSamplers)
                DropdownMenuItem(value: s, child: Text(s)),
            ],
            onChanged: (_) {},
          ),
          const SizedBox(height: 12),
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
            max: 50,
            divisions: 49,
            onChanged: (v) => store.updateParams((p) => p.steps = v.round()),
          ),
          Text(
            'CFG: ${params.cfgScale.toStringAsFixed(1)}',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          Slider(
            value: params.cfgScale,
            min: 1,
            max: 15,
            onChanged: (v) => store.updateParams((p) => p.cfgScale = v),
          ),
        ],
      ),
    );
  }
}
