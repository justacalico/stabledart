import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../state/inference_store.dart';
import '../../../../theme/app_theme.dart';
import '../../../../views/widgets/stack_card.dart';

class UnetModelCard extends StatefulWidget {
  const UnetModelCard({super.key});

  @override
  State<UnetModelCard> createState() => _UnetModelCardState();
}

class _UnetModelCardState extends State<UnetModelCard> {
  String model = 'flux1-dev.safetensors';
  String weightDtype = 'fp8_e4m3fn';
  String vae = 'ae.safetensors';

  static const unets = [
    'flux1-dev.safetensors',
    'flux1-schnell.safetensors',
    'sd3.5_large.safetensors',
    'svd_xt_1_1.safetensors',
  ];

  static const dtypes = ['fp8_e4m3fn', 'fp8_e5m2', 'fp16', 'bf16', 'fp32'];

  static const vaes = ['ae.safetensors', 'sdxl_vae.safetensors', 'taesd'];

  @override
  Widget build(BuildContext context) {
    final store = context.watch<InferenceStore>();
    return StackCard(
      title: 'UNET Model',
      icon: Icons.model_training,
      expanded: store.isCardExpanded('unetModel'),
      onToggle: () => store.toggleCard('unetModel'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'UNET / Diffusion Model',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 4),
          DropdownButtonFormField<String>(
            initialValue: model,
            items: [
              for (final m in unets) DropdownMenuItem(value: m, child: Text(m)),
            ],
            onChanged: (v) => setState(() => model = v ?? model),
          ),
          const SizedBox(height: 12),
          const Text(
            'Weight Dtype',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 4),
          DropdownButtonFormField<String>(
            initialValue: weightDtype,
            items: [
              for (final d in dtypes)
                DropdownMenuItem(value: d, child: Text(d)),
            ],
            onChanged: (v) => setState(() => weightDtype = v ?? weightDtype),
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
        ],
      ),
    );
  }
}
