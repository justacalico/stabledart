import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../services/download_service.dart';
import '../../../services/huggingface_api.dart';
import '../../../state/model_browser_store.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/file_size.dart';
import '../../../utils/number_format.dart';
import '../../../utils/time_ago.dart';

class HuggingFaceBrowserView extends StatefulWidget {
  const HuggingFaceBrowserView({super.key});

  @override
  State<HuggingFaceBrowserView> createState() => _HuggingFaceBrowserViewState();
}

class _HuggingFaceBrowserViewState extends State<HuggingFaceBrowserView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final store = context.read<HuggingFaceBrowserStore>();
      if (store.status == LoadStatus.idle) store.search();
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<HuggingFaceBrowserStore>();
    return Row(
      children: [
        Expanded(
          flex: 5,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search HuggingFace models',
                    prefixIcon: Icon(Icons.search, size: 20),
                  ),
                  onChanged: store.setQuery,
                  onSubmitted: (_) => store.search(),
                ),
              ),
              Expanded(
                child: switch (store.status) {
                  LoadStatus.idle || LoadStatus.loading => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  LoadStatus.failed => Center(
                    child: Text(
                      store.errorMessage ?? 'Failed',
                      style: const TextStyle(color: AppColors.red),
                    ),
                  ),
                  LoadStatus.success => ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: store.models.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (context, i) {
                      final model = store.models[i];
                      final selected = store.selected?.id == model.id;
                      return Card(
                        color: selected ? AppColors.surfaceAlt : AppColors.card,
                        child: ListTile(
                          dense: true,
                          title: Text(
                            model.id,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            '${formatNumber(model.downloads, NumberFormatMode.comma)} downloads · ${model.likes} likes'
                            '${model.lastModified != null ? ' · ${timeAgo(model.lastModified!)}' : ''}',
                            style: const TextStyle(fontSize: 11),
                          ),
                          onTap: () => store.selectModel(model),
                        ),
                      );
                    },
                  ),
                },
              ),
            ],
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          flex: 4,
          child: store.selected == null
              ? const Center(
                  child: Text(
                    'Select a model to view files',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        store.selected!.id,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: store.files.isEmpty
                          ? const Center(
                              child: Text(
                                'No files',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(12),
                              itemCount: store.files.length,
                              itemBuilder: (context, i) {
                                final file = store.files[i];
                                final isModel =
                                    file.path.endsWith('.safetensors') ||
                                    file.path.endsWith('.ckpt') ||
                                    file.path.endsWith('.pt') ||
                                    file.path.endsWith('.bin');
                                return ListTile(
                                  dense: true,
                                  leading: Icon(
                                    isModel
                                        ? Icons.inventory
                                        : Icons.insert_drive_file,
                                    size: 18,
                                    color: isModel
                                        ? AppColors.accent
                                        : AppColors.textSecondary,
                                  ),
                                  title: Text(
                                    file.path,
                                    style: const TextStyle(fontSize: 12),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: file.size > 0
                                      ? Text(
                                          formatBytes(file.size),
                                          style: const TextStyle(fontSize: 11),
                                        )
                                      : null,
                                  trailing: isModel
                                      ? IconButton(
                                          icon: const Icon(
                                            Icons.download,
                                            size: 18,
                                          ),
                                          onPressed: () {
                                            context
                                                .read<DownloadService>()
                                                .enqueue(
                                                  fileName: file.path
                                                      .split('/')
                                                      .last,
                                                  url:
                                                      HuggingFaceApi.downloadUrl(
                                                        store.selected!.id,
                                                        file.path,
                                                      ),
                                                  totalBytes: file.size,
                                                );
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Download queued',
                                                ),
                                              ),
                                            );
                                          },
                                        )
                                      : null,
                                );
                              },
                            ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}
