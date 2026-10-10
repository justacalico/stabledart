import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/local_model.dart';
import '../../state/model_index_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/file_size.dart';
import '../dialogs/model_metadata_editor.dart';
import '../widgets/app_network_image.dart';
import '../widgets/page_scaffold.dart';

class CheckpointsPage extends StatelessWidget {
  const CheckpointsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final index = context.watch<ModelIndexService>();
    return PageScaffold(
      title: 'Model Manager',
      actions: [
        OutlinedButton.icon(
          onPressed: () => _importDialog(context),
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Import Model'),
        ),
      ],
      headerExtra: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 280,
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Search models',
                  prefixIcon: Icon(Icons.search, size: 20),
                ),
                onChanged: index.setQuery,
              ),
            ),
            FilterChip(
              label: const Text('All'),
              selected: index.categoryFilter == null,
              onSelected: (_) => index.setCategoryFilter(null),
            ),
            for (final c in ModelCategory.values)
              if (index.countFor(c) > 0)
                FilterChip(
                  label: Text('${c.displayName} (${index.countFor(c)})'),
                  selected: index.categoryFilter == c,
                  onSelected: (_) => index.setCategoryFilter(c),
                ),
          ],
        ),
      ),
      child: index.filtered.isEmpty
          ? EmptyState(
              icon: Icons.layers_outlined,
              title: 'No Models Found',
              message:
                  'Import checkpoints, LoRAs, and other models or download them from the Model Browser.',
              action: OutlinedButton.icon(
                onPressed: () => _importDialog(context),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Import Model'),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(24),
              children: [
                for (final entry in index.byCategory.entries) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8, top: 8),
                    child: Text(
                      '${entry.key.displayName} (${entry.value.length})',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  for (final model in entry.value)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _ModelRow(model: model),
                    ),
                ],
              ],
            ),
    );
  }

  void _importDialog(BuildContext context) {
    final index = context.read<ModelIndexService>();
    final nameController = TextEditingController();
    var category = ModelCategory.stableDiffusion;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Import Model'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'File name',
                    hintText: 'model.safetensors',
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<ModelCategory>(
                  initialValue: category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: [
                    for (final c in ModelCategory.values)
                      DropdownMenuItem(value: c, child: Text(c.displayName)),
                  ],
                  onChanged: (v) => setState(() => category = v ?? category),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (nameController.text.trim().isNotEmpty) {
                  index.importFile(
                    fileName: nameController.text.trim(),
                    category: category,
                  );
                }
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Import'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModelRow extends StatelessWidget {
  final LocalModelFile model;

  const _ModelRow({required this.model});

  @override
  Widget build(BuildContext context) {
    final index = context.read<ModelIndexService>();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            SizedBox(
              width: 56,
              height: 56,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: AppNetworkImage(url: model.thumbnailUrl),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    model.displayTitle,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${model.fileName} · ${formatBytes(model.sizeBytes)}'
                    '${model.author != null ? ' · ${model.author}' : ''}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (!model.isShared)
              const Padding(
                padding: EdgeInsets.only(right: 8),
                child: Tooltip(
                  message: 'Not shared with packages',
                  child: Icon(
                    Icons.link_off,
                    size: 16,
                    color: AppColors.orange,
                  ),
                ),
              ),
            IconButton(
              tooltip: 'Edit metadata',
              icon: const Icon(Icons.edit_outlined, size: 18),
              onPressed: () => showModelMetadataEditor(context, model),
            ),
            IconButton(
              tooltip: 'Delete',
              icon: const Icon(
                Icons.delete_outline,
                size: 18,
                color: AppColors.red,
              ),
              onPressed: () => _confirmDelete(context, index),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, ModelIndexService index) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Delete ${model.fileName}?'),
        content: const Text(
          'This removes the model from your library. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.red),
            onPressed: () {
              index.remove(model);
              Navigator.of(dialogContext).pop();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
