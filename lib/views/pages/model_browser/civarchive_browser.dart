import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../state/model_browser_store.dart';
import '../../../theme/app_theme.dart';
import '../../widgets/app_network_image.dart';
import '../civit_detail_page.dart';

class CivArchiveBrowserView extends StatefulWidget {
  const CivArchiveBrowserView({super.key});

  @override
  State<CivArchiveBrowserView> createState() => _CivArchiveBrowserViewState();
}

class _CivArchiveBrowserViewState extends State<CivArchiveBrowserView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final store = context.read<CivArchiveBrowserStore>();
      if (store.status == LoadStatus.idle) store.search();
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<CivArchiveBrowserStore>();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
          child: Row(
            children: [
              SizedBox(
                width: 300,
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search CivArchive',
                    prefixIcon: Icon(Icons.search, size: 20),
                  ),
                  onChanged: store.setQuery,
                  onSubmitted: (_) => store.search(),
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                onPressed: store.page > 1
                    ? () => store.setPage(store.page - 1)
                    : null,
                icon: const Icon(Icons.chevron_left),
              ),
              Text(
                'Page ${store.page}',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              IconButton(
                onPressed: () => store.setPage(store.page + 1),
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ),
        Expanded(
          child: switch (store.status) {
            LoadStatus.idle || LoadStatus.loading => const Center(
              child: CircularProgressIndicator(),
            ),
            LoadStatus.failed => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    store.errorMessage ?? 'Failed to load',
                    style: const TextStyle(color: AppColors.red),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: store.search,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
            LoadStatus.success =>
              store.models.isEmpty
                  ? const Center(child: Text('No archived models found'))
                  : ListView.separated(
                      padding: const EdgeInsets.all(24),
                      itemCount: store.models.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        final model = store.models[i];
                        return Card(
                          child: ListTile(
                            leading: SizedBox(
                              width: 48,
                              height: 48,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: AppNetworkImage(url: model.thumbnailUrl),
                              ),
                            ),
                            title: Text(
                              model.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              '${model.type} · ${model.creator}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => CivitDetailPage(model: model),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
          },
        ),
      ],
    );
  }
}
