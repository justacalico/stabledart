import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../state/inference_store.dart';
import '../../../../theme/app_theme.dart';
import '../../../../views/widgets/stack_card.dart';

class VideoOutputSettingsCard extends StatelessWidget {
  const VideoOutputSettingsCard({super.key});

  static const formats = ['mp4', 'webm', 'gif', 'webp', 'frames'];

  @override
  Widget build(BuildContext context) {
    final store = context.watch<InferenceStore>();
    final params = store.params;
    return StackCard(
      title: 'Video Output',
      icon: Icons.videocam_outlined,
      expanded: store.isCardExpanded('videoOutput'),
      onToggle: () => store.toggleCard('videoOutput'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Frames: ${params.frameCount}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Slider(
                      value: params.frameCount.toDouble(),
                      min: 8,
                      max: 240,
                      divisions: 29,
                      onChanged: (v) =>
                          store.updateParams((p) => p.frameCount = v.round()),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'FPS: ${params.fps}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Slider(
                      value: params.fps.toDouble(),
                      min: 4,
                      max: 60,
                      divisions: 56,
                      onChanged: (v) =>
                          store.updateParams((p) => p.fps = v.round()),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Text(
            'Format',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 4),
          DropdownButtonFormField<String>(
            initialValue: formats.first,
            items: [
              for (final f in formats)
                DropdownMenuItem(value: f, child: Text(f)),
            ],
            onChanged: (_) {},
          ),
        ],
      ),
    );
  }
}
