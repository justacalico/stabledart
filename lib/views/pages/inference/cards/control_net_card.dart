import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../state/inference_store.dart';
import '../../../../theme/app_theme.dart';
import '../../../../views/widgets/stack_card.dart';

class ControlNetCard extends StatelessWidget {
  const ControlNetCard({super.key});

  static const models = [
    'control_v11p_sd15_canny',
    'control_v11p_sd15_openpose',
    'control_v11p_sd15_depth',
    'control_v11f1p_sd15_tile',
    'control_v11p_sd15_lineart',
    'control_v11e_sd15_ip2p',
  ];

  static const preprocessors = [
    'none',
    'canny',
    'depth_midas',
    'depth_zoe',
    'openpose',
    'lineart_standard',
    'tile_resample',
    'scribble_hed',
  ];

  @override
  Widget build(BuildContext context) {
    final store = context.watch<InferenceStore>();
    return StackCard(
      title: 'ControlNet',
      icon: Icons.account_tree_outlined,
      expanded: store.isCardExpanded('controlNet'),
      onToggle: () => store.toggleCard('controlNet'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Model',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 4),
          DropdownButtonFormField<String>(
            initialValue: models.first,
            items: [
              for (final m in models)
                DropdownMenuItem(value: m, child: Text(m)),
            ],
            onChanged: (_) {},
          ),
          const SizedBox(height: 12),
          const Text(
            'Preprocessor',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 4),
          DropdownButtonFormField<String>(
            initialValue: preprocessors.first,
            items: [
              for (final p in preprocessors)
                DropdownMenuItem(value: p, child: Text(p)),
            ],
            onChanged: (_) {},
          ),
          const SizedBox(height: 12),
          const Text(
            'Weight: 1.00',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          Slider(value: 1.0, min: 0, max: 2, onChanged: (_) {}),
        ],
      ),
    );
  }
}
