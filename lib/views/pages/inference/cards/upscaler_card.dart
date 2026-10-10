import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../state/inference_store.dart';
import '../../../../theme/app_theme.dart';
import '../../../../views/widgets/stack_card.dart';

class UpscalerCard extends StatelessWidget {
  const UpscalerCard({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<InferenceStore>();
    final params = store.params;
    return StackCard(
      title: 'Upscaler',
      icon: Icons.zoom_out_map,
      expanded: store.isCardExpanded('upscaler'),
      onToggle: () => store.toggleCard('upscaler'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Upscaler',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 4),
          DropdownButtonFormField<String>(
            initialValue: params.upscaler,
            items: [
              for (final u in InferenceStore.upscalers)
                DropdownMenuItem(value: u, child: Text(u)),
            ],
            onChanged: (v) =>
                store.updateParams((p) => p.upscaler = v ?? p.upscaler),
          ),
          const SizedBox(height: 12),
          Text(
            'Scale: ${params.upscaleFactor.toStringAsFixed(1)}x',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          Slider(
            value: params.upscaleFactor,
            min: 1,
            max: 8,
            divisions: 14,
            onChanged: (v) => store.updateParams((p) => p.upscaleFactor = v),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('Hires fix', style: TextStyle(fontSize: 13)),
              const Spacer(),
              Switch(
                value: params.highResFix,
                onChanged: (v) => store.updateParams((p) => p.highResFix = v),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
