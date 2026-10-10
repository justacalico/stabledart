import 'package:flutter/material.dart';

import '../../models/output_image.dart';
import '../../theme/app_theme.dart';
import '../../utils/time_ago.dart';

void showImageViewerDialog(BuildContext context, OutputImage image) {
  showDialog<void>(
    context: context,
    builder: (dialogContext) => Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 380,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: const Center(
                child: Icon(Icons.image, size: 96, color: AppColors.accent),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (image.prompt.isNotEmpty)
                    Text(
                      image.prompt,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  if (image.negativePrompt.isNotEmpty)
                    Text(
                      'Negative: ${image.negativePrompt}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    '${image.width}x${image.height} · seed ${image.seed} · '
                    '${image.sampler} · ${image.steps} steps · '
                    'CFG ${image.cfgScale.toStringAsFixed(1)} · '
                    '${timeAgo(image.createdAt)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
