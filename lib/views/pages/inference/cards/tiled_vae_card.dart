import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../state/inference_store.dart';
import '../../../../theme/app_theme.dart';
import '../../../../views/widgets/stack_card.dart';

class TiledVAECard extends StatefulWidget {
  const TiledVAECard({super.key});

  @override
  State<TiledVAECard> createState() => _TiledVAECardState();
}

class _TiledVAECardState extends State<TiledVAECard> {
  bool enabled = false;
  double tileSize = 512;
  double overlap = 64;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<InferenceStore>();
    return StackCard(
      title: 'Tiled VAE',
      icon: Icons.grid_view,
      expanded: store.isCardExpanded('tiledVae'),
      onToggle: () => store.toggleCard('tiledVae'),
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
              'Tile Size: ${tileSize.round()}px',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            Slider(
              value: tileSize,
              min: 256,
              max: 1024,
              divisions: 12,
              onChanged: (v) => setState(() => tileSize = v),
            ),
            Text(
              'Overlap: ${overlap.round()}px',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            Slider(
              value: overlap,
              min: 16,
              max: 256,
              divisions: 15,
              onChanged: (v) => setState(() => overlap = v),
            ),
          ],
        ],
      ),
    );
  }
}
