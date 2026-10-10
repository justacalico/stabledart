import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../state/model_browser_store.dart';
import '../../../theme/app_theme.dart';
import '../../widgets/app_network_image.dart';

class OpenModelDbBrowserView extends StatefulWidget {
  const OpenModelDbBrowserView({super.key});

  @override
  State<OpenModelDbBrowserView> createState() => _OpenModelDbBrowserViewState();
}

class _OpenModelDbBrowserViewState extends State<OpenModelDbBrowserView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final store = context.read<OpenModelDbBrowserStore>();
      if (store.status == LoadStatus.idle) store.load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<OpenModelDbBrowserStore>();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 260,
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search OpenModelDB',
                    prefixIcon: Icon(Icons.search, size: 20),
                  ),
                  onChanged: store.setQuery,
                ),
              ),
              FilterChip(
                label: const Text('All'),
                selected: store.tagFilter == null,
                onSelected: (_) => store.setTagFilter(null),
              ),
              for (final tag in store.allTags.take(8))
                FilterChip(
                  label: Text(tag),
                  selected: store.tagFilter == tag,
                  onSelected: (_) => store.setTagFilter(tag),
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
                    onPressed: store.load,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
            LoadStatus.success =>
              store.filtered.isEmpty
                  ? const Center(child: Text('No models found'))
                  : GridView.builder(
                      padding: const EdgeInsets.all(24),
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 260,
                            mainAxisExtent: 220,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                          ),
                      itemCount: store.filtered.length,
                      itemBuilder: (context, i) {
                        final model = store.filtered[i];
                        return Card(
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: () => _showDetails(context, model),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: SizedBox(
                                    width: double.infinity,
                                    child: AppNetworkImage(
                                      url: model.thumbnailUrl,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        model.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        '${model.scale}x · ${model.architecture}',
                                        style: const TextStyle(
                                          fontSize: 11,
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
          },
        ),
      ],
    );
  }

  void _showDetails(BuildContext context, model) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(model.name),
        content: SizedBox(
          width: 460,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${model.scale}x upscale · ${model.architecture}'),
              const SizedBox(height: 8),
              Text(
                model.description,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'by ${model.author}',
                style: const TextStyle(fontSize: 12, color: AppColors.accent),
              ),
              if (model.resources.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text(
                  'Resources',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                for (final r in model.resources)
                  SelectableText(
                    r,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
