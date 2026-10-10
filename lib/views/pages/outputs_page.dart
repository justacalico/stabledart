import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/outputs_store.dart';
import '../../theme/app_theme.dart';
import '../../utils/time_ago.dart';
import '../dialogs/image_viewer_dialog.dart';
import '../widgets/page_scaffold.dart';

class OutputsPage extends StatelessWidget {
  const OutputsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<OutputsStore>();
    return PageScaffold(
      title: 'Outputs',
      actions: [
        if (store.outputs.isNotEmpty)
          OutlinedButton.icon(
            onPressed: store.clear,
            icon: const Icon(Icons.delete_sweep, size: 18),
            label: const Text('Clear All'),
          ),
      ],
      child: Row(
        children: [
          Container(
            width: 220,
            decoration: const BoxDecoration(
              border: Border(right: BorderSide(color: AppColors.border)),
            ),
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                _FolderTile(
                  label: 'All',
                  count: store.outputs.length,
                  selected: store.folderFilter == null,
                  onTap: () => store.setFolderFilter(null),
                ),
                for (final folder in store.folders)
                  _FolderTile(
                    label: folder,
                    count: store.outputs
                        .where((o) {
                          final idx = o.filePath.lastIndexOf('/');
                          return (idx > 0
                                  ? o.filePath.substring(0, idx)
                                  : o.filePath) ==
                              folder;
                        })
                        .length,
                    selected: store.folderFilter == folder,
                    onTap: () => store.setFolderFilter(folder),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search prompts',
                      prefixIcon: Icon(Icons.search, size: 20),
                    ),
                    onChanged: store.setQuery,
                  ),
                ),
                Expanded(
                  child: store.filtered.isEmpty
                      ? const EmptyState(
                          icon: Icons.photo_library_outlined,
                          title: 'No Outputs',
                          message:
                              'Generated images and package outputs appear here.',
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate:
                              const SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 220,
                                mainAxisExtent: 250,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                              ),
                          itemCount: store.filtered.length,
                          itemBuilder: (context, i) {
                            final image = store.filtered[i];
                            return Card(
                              clipBehavior: Clip.antiAlias,
                              child: InkWell(
                                onTap: () =>
                                    showImageViewerDialog(context, image),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Container(
                                        color: AppColors.surfaceAlt,
                                        child: const Center(
                                          child: Icon(
                                            Icons.image,
                                            size: 48,
                                            color: AppColors.accent,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            image.prompt.isEmpty
                                                ? 'Seed ${image.seed}'
                                                : image.prompt,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 11,
                                            ),
                                          ),
                                          Text(
                                            '${image.width}x${image.height} · ${timeAgo(image.createdAt)}',
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FolderTile extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  const _FolderTile({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.surfaceAlt : Colors.transparent,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              Icon(
                label == 'All'
                    ? Icons.photo_library_outlined
                    : Icons.folder_outlined,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '$count',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
