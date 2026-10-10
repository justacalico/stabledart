import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/package_definition.dart';
import '../../services/github_versions_api.dart';
import '../../services/package_registry.dart';
import '../../state/installed_packages_store.dart';
import '../../theme/app_theme.dart';
import '../widgets/page_scaffold.dart';

class PackageBrowserPage extends StatefulWidget {
  final VoidCallback? onClose;

  const PackageBrowserPage({super.key, this.onClose});

  @override
  State<PackageBrowserPage> createState() => _PackageBrowserPageState();
}

class _PackageBrowserPageState extends State<PackageBrowserPage> {
  String _query = '';
  String? _tagFilter;
  PackageDefinition? _selected;

  List<PackageDefinition> get _filtered => PackageRegistry.all.where((p) {
    if (_tagFilter != null && !p.tags.contains(_tagFilter)) return false;
    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      if (!p.displayName.toLowerCase().contains(q) &&
          !p.author.toLowerCase().contains(q)) {
        return false;
      }
    }
    return true;
  }).toList();

  @override
  Widget build(BuildContext context) {
    if (_selected != null) {
      return PackageInstallDetailPage(
        definition: _selected!,
        onBack: () => setState(() => _selected = null),
      );
    }
    return PageScaffold(
      title: 'Install Packages',
      actions: [
        if (widget.onClose != null)
          IconButton(onPressed: widget.onClose, icon: const Icon(Icons.close)),
      ],
      headerExtra: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 300,
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Search packages',
                  prefixIcon: Icon(Icons.search, size: 20),
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            FilterChip(
              label: const Text('All'),
              selected: _tagFilter == null,
              onSelected: (_) => setState(() => _tagFilter = null),
            ),
            for (final tag in PackageRegistry.allTags)
              FilterChip(
                label: Text(tag),
                selected: _tagFilter == tag,
                onSelected: (_) => setState(() => _tagFilter = tag),
              ),
          ],
        ),
      ),
      child: GridView.builder(
        padding: const EdgeInsets.all(24),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 400,
          mainAxisExtent: 150,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: _filtered.length,
        itemBuilder: (context, i) {
          final def = _filtered[i];
          final installed = context
              .watch<InstalledPackagesStore>()
              .packages
              .any((p) => p.packageName == def.name);
          return _PackageBrowseCard(
            definition: def,
            installed: installed,
            onTap: () => setState(() => _selected = def),
          );
        },
      ),
    );
  }
}

class _PackageBrowseCard extends StatelessWidget {
  final PackageDefinition definition;
  final bool installed;
  final VoidCallback onTap;

  const _PackageBrowseCard({
    required this.definition,
    required this.installed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = Color(definition.accentColor);
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.widgets_outlined, color: accent),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          definition.displayName,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'by ${definition.author}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (installed)
                    const Icon(
                      Icons.check_circle,
                      color: AppColors.mediumSeaGreen,
                      size: 20,
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Expanded(
                child: Text(
                  definition.description,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Wrap(
                spacing: 6,
                children: [
                  for (final tag in definition.tags)
                    Chip(
                      label: Text(tag, style: const TextStyle(fontSize: 10)),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PackageInstallDetailPage extends StatefulWidget {
  final PackageDefinition definition;
  final VoidCallback onBack;

  const PackageInstallDetailPage({
    super.key,
    required this.definition,
    required this.onBack,
  });

  @override
  State<PackageInstallDetailPage> createState() =>
      _PackageInstallDetailPageState();
}

class _PackageInstallDetailPageState extends State<PackageInstallDetailPage> {
  String _version = 'latest';
  List<String> _versions = ['latest'];
  bool _loadingVersions = false;
  String? _versionsError;

  @override
  void initState() {
    super.initState();
    _loadVersions();
  }

  Future<void> _loadVersions() async {
    setState(() => _loadingVersions = true);
    try {
      final api = context.read<GitHubVersionsApi>();
      final tags = await api.getTags(widget.definition.repositoryUrl);
      final branches = await api.getBranches(widget.definition.repositoryUrl);
      if (!mounted) return;
      setState(() {
        _versions = {
          'latest',
          ...tags.take(20),
          ...branches.where((b) => b == 'main' || b == 'master'),
        }.toList();
        _version = _versions.first;
        _loadingVersions = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _versionsError = '$e';
        _loadingVersions = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final def = widget.definition;
    final accent = Color(def.accentColor);
    final store = context.watch<InstalledPackagesStore>();
    final install = store.installs[def.name];

    return PageScaffold(
      title: def.displayName,
      actions: [
        IconButton(
          onPressed: widget.onBack,
          icon: const Icon(Icons.arrow_back),
        ),
      ],
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.widgets_outlined, color: accent, size: 36),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'by ${def.author}',
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 8),
                      Text(def.description),
                      const SizedBox(height: 8),
                      SelectableText(
                        def.repositoryUrl,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.accent,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (_loadingVersions)
              const Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 8),
                  Text('Loading versions...'),
                ],
              )
            else ...[
              const Text(
                'Version',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _version,
                items: [
                  for (final v in _versions)
                    DropdownMenuItem(value: v, child: Text(v)),
                ],
                onChanged: (v) => setState(() => _version = v ?? 'latest'),
              ),
              if (_versionsError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    'Could not load remote versions: $_versionsError',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.orange,
                    ),
                  ),
                ),
            ],
            const SizedBox(height: 24),
            if (install != null && !install.done) ...[
              Text(
                install.step,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(value: install.progress),
              const SizedBox(height: 4),
              Text(
                '${(install.progress * 100).round()}%',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ] else if (install?.done == true)
              const Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: AppColors.mediumSeaGreen,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text('Installed'),
                ],
              )
            else
              FilledButton.icon(
                onPressed: () => context
                    .read<InstalledPackagesStore>()
                    .install(def, _version)
                    .ignore(),
                icon: const Icon(Icons.download, size: 18),
                label: const Text('Install'),
              ),
            if (install?.error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  install!.error!,
                  style: const TextStyle(color: AppColors.red),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
