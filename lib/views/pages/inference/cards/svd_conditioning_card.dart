import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../state/inference_store.dart';
import '../../../../theme/app_theme.dart';
import '../../../../views/widgets/stack_card.dart';

class SvdConditioningCard extends StatefulWidget {
  const SvdConditioningCard({super.key});

  @override
  State<SvdConditioningCard> createState() => _SvdConditioningCardState();
}

class _SvdConditioningCardState extends State<SvdConditioningCard> {
  double motionBucket = 127;
  double fps = 6;
  double augmentation = 0.0;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<InferenceStore>();
    return StackCard(
      title: 'SVD Conditioning',
      icon: Icons.video_settings,
      expanded: store.isCardExpanded('svdConditioning'),
      onToggle: () => store.toggleCard('svdConditioning'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Motion Bucket ID: ${motionBucket.round()}',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          Slider(
            value: motionBucket,
            min: 1,
            max: 255,
            onChanged: (v) => setState(() => motionBucket = v),
          ),
          Text(
            'FPS: ${fps.round()}',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          Slider(
            value: fps,
            min: 1,
            max: 30,
            onChanged: (v) => setState(() => fps = v),
          ),
          Text(
            'Noise Augmentation: ${augmentation.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          Slider(
            value: augmentation,
            min: 0,
            max: 1,
            onChanged: (v) => setState(() => augmentation = v),
          ),
        ],
      ),
    );
  }
}
