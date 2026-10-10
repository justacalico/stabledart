import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../state/inference_store.dart';
import '../../../../theme/app_theme.dart';
import '../../../../views/widgets/stack_card.dart';

class SelectImageCard extends StatelessWidget {
  const SelectImageCard({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<InferenceStore>();
    final params = store.params;
    return StackCard(
      title: 'Input Image',
      icon: Icons.add_photo_alternate_outlined,
      expanded: store.isCardExpanded('inputImage'),
      onToggle: () => store.toggleCard('inputImage'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () {
              store.updateParams(
                (p) => p.inputImagePath = 'input/selected-image.png',
              );
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.border,
                  style: BorderStyle.solid,
                ),
              ),
              child: Center(
                child: params.inputImagePath == null
                    ? const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.upload_file,
                            color: AppColors.textSecondary,
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Drop an image or click to select',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.image, color: AppColors.accent),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              params.inputImagePath!,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 16),
                            onPressed: () => store.updateParams(
                              (p) => p.inputImagePath = null,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Denoise Strength: ${params.denoiseStrength.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          Slider(
            value: params.denoiseStrength,
            min: 0,
            max: 1,
            divisions: 100,
            onChanged: (v) => store.updateParams((p) => p.denoiseStrength = v),
          ),
        ],
      ),
    );
  }
}
