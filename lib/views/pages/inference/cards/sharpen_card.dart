import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../state/inference_store.dart';
import '../../../../theme/app_theme.dart';
import '../../../../views/widgets/stack_card.dart';

class SharpenCard extends StatefulWidget {
  const SharpenCard({super.key});

  @override
  State<SharpenCard> createState() => _SharpenCardState();
}

class _SharpenCardState extends State<SharpenCard> {
  bool enabled = false;
  double amount = 0.5;
  double radius = 1.0;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<InferenceStore>();
    return StackCard(
      title: 'Sharpen',
      icon: Icons.details,
      expanded: store.isCardExpanded('sharpen'),
      onToggle: () => store.toggleCard('sharpen'),
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
              'Amount: ${amount.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            Slider(
              value: amount,
              min: 0,
              max: 1,
              onChanged: (v) => setState(() => amount = v),
            ),
            Text(
              'Radius: ${radius.toStringAsFixed(1)}px',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            Slider(
              value: radius,
              min: 0.1,
              max: 5,
              onChanged: (v) => setState(() => radius = v),
            ),
          ],
        ],
      ),
    );
  }
}
