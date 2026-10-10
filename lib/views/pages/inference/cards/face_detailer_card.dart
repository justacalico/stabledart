import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../state/inference_store.dart';
import '../../../../theme/app_theme.dart';
import '../../../../views/widgets/stack_card.dart';

class FaceDetailerCard extends StatefulWidget {
  const FaceDetailerCard({super.key});

  @override
  State<FaceDetailerCard> createState() => _FaceDetailerCardState();
}

class _FaceDetailerCardState extends State<FaceDetailerCard> {
  bool enabled = false;
  double confidence = 0.5;
  double denoise = 0.35;

  static const detectors = [
    'bbox/face_yolov8m',
    'bbox/face_yolov8n',
    'segm/face_yolov8m',
    'person_yolov8m-seg',
  ];

  @override
  Widget build(BuildContext context) {
    final store = context.watch<InferenceStore>();
    return StackCard(
      title: 'Face Detailer',
      icon: Icons.face,
      expanded: store.isCardExpanded('faceDetailer'),
      onToggle: () => store.toggleCard('faceDetailer'),
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
              'Detection Model',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 4),
            DropdownButtonFormField<String>(
              initialValue: detectors.first,
              items: [
                for (final d in detectors)
                  DropdownMenuItem(value: d, child: Text(d)),
              ],
              onChanged: (_) {},
            ),
            const SizedBox(height: 12),
            Text(
              'Confidence: ${confidence.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            Slider(
              value: confidence,
              min: 0.1,
              max: 1,
              onChanged: (v) => setState(() => confidence = v),
            ),
            Text(
              'Denoise: ${denoise.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            Slider(
              value: denoise,
              min: 0,
              max: 1,
              onChanged: (v) => setState(() => denoise = v),
            ),
          ],
        ],
      ),
    );
  }
}
