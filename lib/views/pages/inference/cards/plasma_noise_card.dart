import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../state/inference_store.dart';
import '../../../../theme/app_theme.dart';
import '../../../../views/widgets/stack_card.dart';

class PlasmaNoiseCard extends StatefulWidget {
  const PlasmaNoiseCard({super.key});

  @override
  State<PlasmaNoiseCard> createState() => _PlasmaNoiseCardState();
}

class _PlasmaNoiseCardState extends State<PlasmaNoiseCard> {
  bool enabled = false;
  double strength = 0.1;
  int octaveCount = 4;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<InferenceStore>();
    return StackCard(
      title: 'Plasma Noise',
      icon: Icons.waves,
      expanded: store.isCardExpanded('plasmaNoise'),
      onToggle: () => store.toggleCard('plasmaNoise'),
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
              'Strength: ${strength.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            Slider(
              value: strength,
              min: 0,
              max: 1,
              onChanged: (v) => setState(() => strength = v),
            ),
            Text(
              'Octaves: $octaveCount',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            Slider(
              value: octaveCount.toDouble(),
              min: 1,
              max: 8,
              divisions: 7,
              onChanged: (v) => setState(() => octaveCount = v.round()),
            ),
          ],
        ],
      ),
    );
  }
}
