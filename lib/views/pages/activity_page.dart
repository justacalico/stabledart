import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/download_task.dart';
import '../../services/download_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/file_size.dart';
import '../../utils/time_ago.dart';
import '../widgets/page_scaffold.dart';

class ActivityPage extends StatelessWidget {
  const ActivityPage({super.key});

  @override
  Widget build(BuildContext context) {
    final downloads = context.watch<DownloadService>();
    return PageScaffold(
      title: 'Activity',
      actions: [
        OutlinedButton.icon(
          onPressed: downloads.tasks.any((t) => t.isFinished)
              ? downloads.clearCompleted
              : null,
          icon: const Icon(Icons.clear_all, size: 18),
          label: const Text('Clear Finished'),
        ),
      ],
      child: downloads.tasks.isEmpty
          ? const EmptyState(
              icon: Icons.download_done,
              title: 'No Activity',
              message: 'Downloads and background tasks will appear here.',
            )
          : ListView.separated(
              padding: const EdgeInsets.all(24),
              itemCount: downloads.tasks.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) =>
                  _DownloadTile(task: downloads.tasks[i]),
            ),
    );
  }
}

class _DownloadTile extends StatelessWidget {
  final DownloadTask task;

  const _DownloadTile({required this.task});

  @override
  Widget build(BuildContext context) {
    final downloads = context.read<DownloadService>();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    task.fileName,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _StatusChip(status: task.status),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: task.status == DownloadStatus.completed
                  ? 1
                  : (task.totalBytes > 0 ? task.progress : null),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  '${formatBytes(task.receivedBytes)} / ${task.totalBytes > 0 ? formatBytes(task.totalBytes) : '?'}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 12),
                if (task.status == DownloadStatus.downloading)
                  Text(
                    formatSpeed(task.bytesPerSecond),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                const SizedBox(width: 12),
                Text(
                  timeAgo(task.createdAt),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (task.errorMessage != null) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      task.errorMessage!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.red,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ] else
                  const Spacer(),
                if (task.status == DownloadStatus.downloading)
                  IconButton(
                    tooltip: 'Pause',
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.pause, size: 18),
                    onPressed: () => downloads.pause(task),
                  ),
                if (task.status == DownloadStatus.paused ||
                    task.status == DownloadStatus.failed)
                  IconButton(
                    tooltip: 'Resume',
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.play_arrow, size: 18),
                    onPressed: () => downloads.resume(task),
                  ),
                if (task.isActive)
                  IconButton(
                    tooltip: 'Cancel',
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => downloads.cancel(task),
                  ),
                if (task.isFinished)
                  IconButton(
                    tooltip: 'Remove',
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.delete_outline, size: 18),
                    onPressed: () => downloads.remove(task),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final DownloadStatus status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      DownloadStatus.queued => ('Queued', AppColors.grey),
      DownloadStatus.downloading => ('Downloading', AppColors.accent),
      DownloadStatus.paused => ('Paused', AppColors.orange),
      DownloadStatus.completed => ('Completed', AppColors.mediumSeaGreen),
      DownloadStatus.failed => ('Failed', AppColors.red),
      DownloadStatus.cancelled => ('Cancelled', AppColors.grey),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 11)),
    );
  }
}
