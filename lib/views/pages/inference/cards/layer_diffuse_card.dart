import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../state/inference_store.dart';
import '../../../../theme/app_theme.dart';
import '../../../../views/widgets/stack_card.dart';

class LayerDiffuseCard extends StatefulWidget {
  const LayerDiffuseCard({super.key});

  @override
  State<LayerDiffuseCard> createState() => _LayerDiffuseCardState();
}

class _LayerDiffuseCardState extends State<LayerDiffuseCard> {
  bool enabled = false;
  String method = 'Foreground';
  bool stopAt = false;

  static const methods = [
    'Foreground',
    'Background',
    'Blend',
    'Foreground to Blend',
    'Background to Blend',
  ];

  @override
  Widget build(BuildContext context) {
    final store = context.watch<InferenceStore>();
    return StackCard(
      title: 'LayerDiffuse',
      icon: Icons.layers_outlined,
      expanded: store.isCardExpanded('layerDiffuse'),
      onToggle: () => store.toggleCard('layerDiffuse'),
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
              'Method',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 4),
            DropdownButtonFormField<String>(
              initialValue: method,
              items: [
                for (final m in methods)
                  DropdownMenuItem(value: m, child: Text(m)),
              ],
              onChanged: (v) => setState(() => method = v ?? method),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Stop at full layer',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
                Switch(
                  value: stopAt,
                  onChanged: (v) => setState(() => stopAt = v),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
