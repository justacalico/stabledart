import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../state/inference_store.dart';
import '../../../../theme/app_theme.dart';
import '../../../../views/widgets/stack_card.dart';

class FreeUCard extends StatefulWidget {
  const FreeUCard({super.key});

  @override
  State<FreeUCard> createState() => _FreeUCardState();
}

class _FreeUCardState extends State<FreeUCard> {
  bool enabled = false;
  double b1 = 1.3, b2 = 1.4, s1 = 0.9, s2 = 0.2;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<InferenceStore>();
    return StackCard(
      title: 'FreeU',
      icon: Icons.tune,
      expanded: store.isCardExpanded('freeu'),
      onToggle: () => store.toggleCard('freeu'),
      child: Column(
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
            for (final (label, value, set) in [
              ('Backbone 1', b1, (double v) => b1 = v),
              ('Backbone 2', b2, (double v) => b2 = v),
              ('Skip 1', s1, (double v) => s1 = v),
              ('Skip 2', s2, (double v) => s2 = v),
            ])
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$label: ${value.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Slider(
                    value: value,
                    min: 0,
                    max: 2,
                    divisions: 100,
                    onChanged: (v) => setState(() => set(v)),
                  ),
                ],
              ),
          ],
        ],
      ),
    );
  }
}
