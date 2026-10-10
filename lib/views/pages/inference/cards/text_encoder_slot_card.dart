import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../state/inference_store.dart';
import '../../../../theme/app_theme.dart';
import '../../../../views/widgets/stack_card.dart';

class TextEncoderSlotCard extends StatefulWidget {
  const TextEncoderSlotCard({super.key});

  @override
  State<TextEncoderSlotCard> createState() => _TextEncoderSlotCardState();
}

class _TextEncoderSlotCardState extends State<TextEncoderSlotCard> {
  String clip1 = 'clip_l.safetensors';
  String clip2 = 't5xxl_fp16.safetensors';
  String dtype = 'default';

  static const encoders = [
    'clip_l.safetensors',
    't5xxl_fp16.safetensors',
    't5xxl_fp8_e4m3fn.safetensors',
    'umt5_xxl_fp8_e4m3fn.safetensors',
    'llava_llama3_fp8.safetensors',
  ];

  static const dtypes = ['default', 'fp16', 'bf16', 'fp8_e4m3fn'];

  @override
  Widget build(BuildContext context) {
    final store = context.watch<InferenceStore>();
    return StackCard(
      title: 'Text Encoders',
      icon: Icons.text_fields,
      expanded: store.isCardExpanded('textEncoders'),
      onToggle: () => store.toggleCard('textEncoders'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'CLIP / T5 Slot 1',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 4),
          DropdownButtonFormField<String>(
            initialValue: clip1,
            items: [
              for (final e in encoders)
                DropdownMenuItem(value: e, child: Text(e)),
            ],
            onChanged: (v) => setState(() => clip1 = v ?? clip1),
          ),
          const SizedBox(height: 12),
          const Text(
            'CLIP / T5 Slot 2',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 4),
          DropdownButtonFormField<String>(
            initialValue: clip2,
            items: [
              for (final e in encoders)
                DropdownMenuItem(value: e, child: Text(e)),
            ],
            onChanged: (v) => setState(() => clip2 = v ?? clip2),
          ),
          const SizedBox(height: 12),
          const Text(
            'Dtype',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 4),
          DropdownButtonFormField<String>(
            initialValue: dtype,
            items: [
              for (final d in dtypes)
                DropdownMenuItem(value: d, child: Text(d)),
            ],
            onChanged: (v) => setState(() => dtype = v ?? dtype),
          ),
        ],
      ),
    );
  }
}
