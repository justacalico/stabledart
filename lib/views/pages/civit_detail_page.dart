import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/settings_manager.dart';
import '../../utils/paths.dart';

import '../../models/civit_models.dart';
import '../../services/download_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/file_size.dart';
import '../../utils/number_format.dart';
import '../widgets/app_network_image.dart';

class CivitDetailPage extends StatefulWidget {
  final CivitModel model;

  const CivitDetailPage({super.key, required this.model});

  @override
  State<CivitDetailPage> createState() => _CivitDetailPageState();
}

class _CivitDetailPageState extends State<CivitDetailPage> {
  late CivitModelVersion _version;
  int _imageIndex = 0;

  @override
  void initState() {
    super.initState();
    _version = widget.model.versions.isNotEmpty
        ? widget.model.versions.first
        : const CivitModelVersion(id: 0, name: 'default');
  }

  @override
  Widget build(BuildContext context) {
    final model = widget.model;
    final images = _version.images;
    return Scaffold(
      appBar: AppBar(title: Text(model.name)),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceAlt,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: images.isEmpty
                        ? const Center(
                            child: Icon(
                              Icons.image_outlined,
                              size: 64,
                              color: AppColors.textSecondary,
                            ),
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: AppNetworkImage(
                              url:
                                  images[_imageIndex.clamp(
                                        0,
                                        images.length - 1,
                                      )]
                                      .url,
                              fit: BoxFit.contain,
                            ),
                          ),
                  ),
                ),
                if (images.length > 1)
                  SizedBox(
                    height: 72,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: images.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, i) => InkWell(
                        onTap: () => setState(() => _imageIndex = i),
                        child: Container(
                          width: 56,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: i == _imageIndex
                                  ? AppColors.accent
                                  : AppColors.border,
                              width: i == _imageIndex ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(5),
                            child: AppNetworkImage(url: images[i].url),
                          ),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
              ],
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            flex: 4,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  model.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'by ${model.creator}',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _StatChip(
                      Icons.download,
                      formatNumber(model.downloadCount, NumberFormatMode.comma),
                    ),
                    _StatChip(
                      Icons.favorite,
                      formatNumber(model.favoriteCount, NumberFormatMode.comma),
                    ),
                    _StatChip(
                      Icons.chat_bubble,
                      formatNumber(model.commentCount, NumberFormatMode.comma),
                    ),
                    _StatChip(Icons.star, model.rating.toStringAsFixed(1)),
                    if (model.nsfw) const _StatChip(Icons.warning, 'NSFW'),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final tag in model.tags.take(10))
                      Chip(
                        label: Text(tag, style: const TextStyle(fontSize: 11)),
                        visualDensity: VisualDensity.compact,
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Version',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<int>(
                  initialValue: _version.id,
                  items: [
                    for (final v in model.versions)
                      DropdownMenuItem(
                        value: v.id,
                        child: Text(
                          '${v.name} (${v.baseModel})',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (id) {
                    setState(() {
                      _version = model.versions.firstWhere((v) => v.id == id);
                      _imageIndex = 0;
                    });
                  },
                ),
                const SizedBox(height: 16),
                const Text(
                  'Files',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                if (_version.files.isEmpty)
                  const Text(
                    'No files available',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                for (final file in _version.files)
                  Card(
                    child: ListTile(
                      dense: true,
                      title: Text(
                        file.name,
                        style: const TextStyle(fontSize: 13),
                      ),
                      subtitle: Text(
                        formatBytes(file.sizeBytes) +
                            (file.sha256.isNotEmpty
                                ? ' · sha256 ${file.sha256.substring(0, file.sha256.length.clamp(0, 10))}...'
                                : ''),
                        style: const TextStyle(fontSize: 11),
                      ),
                      trailing: FilledButton.tonalIcon(
                        icon: const Icon(Icons.download, size: 16),
                        label: const Text('Download'),
                        onPressed: () {
                          final settings = context.read<SettingsManager>();
                          context.read<DownloadService>().enqueue(
                            fileName: file.name,
                            url: file.downloadUrl,
                            totalBytes: file.sizeBytes,
                            destinationPath: downloadDestination(
                                settings.settings.dataDirectory, file.name),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Download queued')),
                          );
                        },
                      ),
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

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _StatChip(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
