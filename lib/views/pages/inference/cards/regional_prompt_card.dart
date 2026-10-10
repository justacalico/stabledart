import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../state/inference_store.dart';
import '../../../../theme/app_theme.dart';
import '../../../../views/widgets/stack_card.dart';

class RegionalPromptCard extends StatefulWidget {
  const RegionalPromptCard({super.key});

  @override
  State<RegionalPromptCard> createState() => _RegionalPromptCardState();
}

class _RegionalPromptCardState extends State<RegionalPromptCard> {
  bool enabled = false;
  String mode = 'Columns';
  double maskWeight = 1.0;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<InferenceStore>();
    return StackCard(
      title: 'Regional Prompt',
      icon: Icons.dashboard_customize_outlined,
      expanded: store.isCardExpanded('regionalPrompt'),
      onToggle: () => store.toggleCard('regionalPrompt'),
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
            const Text(
              'Split Mode',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 4),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'Columns', label: Text('Columns')),
                ButtonSegment(value: 'Rows', label: Text('Rows')),
                ButtonSegment(value: 'Grid', label: Text('Grid')),
              ],
              selected: {mode},
              onSelectionChanged: (s) => setState(() => mode = s.first),
            ),
            const SizedBox(height: 12),
            Text(
              'Mask Weight: ${maskWeight.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            Slider(
              value: maskWeight,
              min: 0,
              max: 1,
              onChanged: (v) => setState(() => maskWeight = v),
            ),
          ],
        ],
      ),
    );
  }
}
