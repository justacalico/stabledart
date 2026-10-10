import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../state/inference_store.dart';
import '../../../../theme/app_theme.dart';
import '../../../../views/widgets/stack_card.dart';

class WanModelCard extends StatefulWidget {
  const WanModelCard({super.key});

  @override
  State<WanModelCard> createState() => _WanModelCardState();
}

class _WanModelCardState extends State<WanModelCard> {
  String model = 'wan2.1_t2v_1.3B.safetensors';
  String vae = 'wan_2.1_vae.safetensors';
  double shift = 3.0;

  static const wanModels = [
    'wan2.1_t2v_1.3B.safetensors',
    'wan2.1_t2v_14B.safetensors',
    'wan2.1_i2v_480p_14B.safetensors',
    'wan2.1_i2v_720p_14B.safetensors',
    'wan2.2_t2v_5B.safetensors',
  ];

  static const vaes = ['wan_2.1_vae.safetensors', 'wan_2.2_vae.safetensors'];

  @override
  Widget build(BuildContext context) {
    final store = context.watch<InferenceStore>();
    return StackCard(
      title: 'Wan Model',
      icon: Icons.movie_creation_outlined,
      expanded: store.isCardExpanded('wanModel'),
      onToggle: () => store.toggleCard('wanModel'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Diffusion Model',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 4),
          DropdownButtonFormField<String>(
            initialValue: model,
            items: [
              for (final m in wanModels)
                DropdownMenuItem(value: m, child: Text(m)),
            ],
            onChanged: (v) => setState(() => model = v ?? model),
          ),
          const SizedBox(height: 12),
          const Text(
            'VAE',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 4),
          DropdownButtonFormField<String>(
            initialValue: vae,
            items: [
              for (final v in vaes) DropdownMenuItem(value: v, child: Text(v)),
            ],
            onChanged: (v) => setState(() => vae = v ?? vae),
          ),
          const SizedBox(height: 12),
          Text(
            'Shift: ${shift.toStringAsFixed(1)}',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          Slider(
            value: shift,
            min: 0,
            max: 10,
            onChanged: (v) => setState(() => shift = v),
          ),
        ],
      ),
    );
  }
}
