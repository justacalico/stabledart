import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../state/inference_store.dart';
import '../../../../theme/app_theme.dart';
import '../../../../views/widgets/stack_card.dart';

class DiscreteModelSamplingCard extends StatefulWidget {
  const DiscreteModelSamplingCard({super.key});

  @override
  State<DiscreteModelSamplingCard> createState() =>
      _DiscreteModelSamplingCardState();
}

class _DiscreteModelSamplingCardState extends State<DiscreteModelSamplingCard> {
  bool enabled = false;
  String samplingMode = 'eps';
  double sigmaMin = 0.002;
  double sigmaMax = 80.0;

  static const modes = ['eps', 'v_prediction', 'lcm', 'x0'];

  @override
  Widget build(BuildContext context) {
    final store = context.watch<InferenceStore>();
    return StackCard(
      title: 'Discrete Model Sampling',
      icon: Icons.scatter_plot_outlined,
      expanded: store.isCardExpanded('dms'),
      onToggle: () => store.toggleCard('dms'),
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
              'Sampling Mode',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 4),
            DropdownButtonFormField<String>(
              initialValue: samplingMode,
              items: [
                for (final m in modes)
                  DropdownMenuItem(value: m, child: Text(m)),
              ],
              onChanged: (v) =>
                  setState(() => samplingMode = v ?? samplingMode),
            ),
            const SizedBox(height: 12),
            Text(
              'Sigma Min: ${sigmaMin.toStringAsFixed(3)}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            Slider(
              value: sigmaMin * 100,
              min: 0.1,
              max: 20,
              onChanged: (v) => setState(() => sigmaMin = v / 100),
            ),
            Text(
              'Sigma Max: ${sigmaMax.toStringAsFixed(1)}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            Slider(
              value: sigmaMax,
              min: 1,
              max: 200,
              onChanged: (v) => setState(() => sigmaMax = v),
            ),
          ],
        ],
      ),
    );
  }
}
