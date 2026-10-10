import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../state/inference_store.dart';
import '../../../../theme/app_theme.dart';
import '../../../../views/widgets/stack_card.dart';

class NrsCard extends StatefulWidget {
  const NrsCard({super.key});

  @override
  State<NrsCard> createState() => _NrsCardState();
}

class _NrsCardState extends State<NrsCard> {
  bool enabled = false;
  double weight = 0.7;
  int applyAt = 10;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<InferenceStore>();
    return StackCard(
      title: 'Noise Refinement',
      icon: Icons.grain,
      expanded: store.isCardExpanded('nrs'),
      onToggle: () => store.toggleCard('nrs'),
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
            Text(
              'Weight: ${weight.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            Slider(
              value: weight,
              min: 0,
              max: 1,
              onChanged: (v) => setState(() => weight = v),
            ),
            Text(
              'Apply at step: $applyAt',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            Slider(
              value: applyAt.toDouble(),
              min: 1,
              max: 50,
              divisions: 49,
              onChanged: (v) => setState(() => applyAt = v.round()),
            ),
          ],
        ],
      ),
    );
  }
}
