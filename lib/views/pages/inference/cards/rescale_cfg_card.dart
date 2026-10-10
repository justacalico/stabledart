import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../state/inference_store.dart';
import '../../../../theme/app_theme.dart';
import '../../../../views/widgets/stack_card.dart';

class RescaleCfgCard extends StatefulWidget {
  const RescaleCfgCard({super.key});

  @override
  State<RescaleCfgCard> createState() => _RescaleCfgCardState();
}

class _RescaleCfgCardState extends State<RescaleCfgCard> {
  bool enabled = false;
  double multiplier = 0.7;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<InferenceStore>();
    return StackCard(
      title: 'Rescale CFG',
      icon: Icons.compress,
      expanded: store.isCardExpanded('rescaleCfg'),
      onToggle: () => store.toggleCard('rescaleCfg'),
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
              'Multiplier: ${multiplier.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            Slider(
              value: multiplier,
              min: 0,
              max: 1,
              onChanged: (v) => setState(() => multiplier = v),
            ),
          ],
        ],
      ),
    );
  }
}
