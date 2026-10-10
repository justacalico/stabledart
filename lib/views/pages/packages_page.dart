import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/installed_package.dart';
import '../../state/installed_packages_store.dart';
import '../../theme/app_theme.dart';
import '../widgets/page_scaffold.dart';
import 'launch_page.dart';
import 'package_browser_page.dart';

class PackagesPage extends StatefulWidget {
  const PackagesPage({super.key});

  @override
  State<PackagesPage> createState() => _PackagesPageState();
}

class _PackagesPageState extends State<PackagesPage> {
  bool _showBrowser = false;

  @override
  Widget build(BuildContext context) {
    if (_showBrowser) {
      return PackageBrowserPage(
        onClose: () => setState(() => _showBrowser = false),
      );
    }
    return PageScaffold(
      title: 'Packages',
      actions: [
        FilledButton.icon(
          onPressed: () => setState(() => _showBrowser = true),
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Add Package'),
        ),
      ],
      child: const _InstalledPackagesView(),
    );
  }
}

class _InstalledPackagesView extends StatelessWidget {
  const _InstalledPackagesView();

  @override
  Widget build(BuildContext context) {
    final store = context.watch<InstalledPackagesStore>();
    if (store.packages.isEmpty) {
      return EmptyState(
        icon: Icons.inventory_2_outlined,
        title: 'No Packages Installed',
        message: 'Install a Stable Diffusion package to get started.',
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(24),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 380,
        mainAxisExtent: 190,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: store.packages.length,
      itemBuilder: (context, i) => PackageCard(package: store.packages[i]),
    );
  }
}

class PackageCard extends StatelessWidget {
  final InstalledPackage package;

  const PackageCard({super.key, required this.package});

  @override
  Widget build(BuildContext context) {
    final store = context.read<InstalledPackagesStore>();
    final definition = store.definitionFor(package);
    final accent = definition != null
        ? Color(definition.accentColor)
        : AppColors.accent;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
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
                        package.displayName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'v${package.version}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (package.isRunning)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.green.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'Running',
                      style: TextStyle(
                        color: AppColors.mediumSeaGreen,
                        fontSize: 11,
                      ),
                    ),
                  ),
              ],
            ),
            const Spacer(),
            Text(
              package.installPath,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                FilledButton.tonalIcon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => LaunchPage(packageId: package.id),
                      ),
                    );
                  },
                  icon: Icon(
                    package.isRunning ? Icons.terminal : Icons.play_arrow,
                  ),
                  label: Text(package.isRunning ? 'Console' : 'Launch'),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Launch options',
                  onPressed: () => showLaunchOptionsDialog(context, package),
                  icon: const Icon(Icons.tune, size: 20),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Uninstall',
                  onPressed: () => _confirmDelete(context, store),
                  icon: const Icon(
                    Icons.delete_outline,
                    size: 20,
                    color: AppColors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, InstalledPackagesStore store) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Uninstall ${package.displayName}?'),
        content: const Text(
          'This will remove the package installation. Your models are kept in the shared Models folder.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.red),
            onPressed: () {
              store.uninstall(package);
              Navigator.of(dialogContext).pop();
            },
            child: const Text('Uninstall'),
          ),
        ],
      ),
    );
  }
}

void showLaunchOptionsDialog(BuildContext context, InstalledPackage package) {
  final store = context.read<InstalledPackagesStore>();
  final definition = store.definitionFor(package);
  final options = definition?.launchOptions() ?? [];
  for (final saved in package.launchArgs) {
    final name = saved['name'] as String?;
    for (final option in options) {
      if (option.name == name) option.applyJson(saved);
    }
  }
  showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text('Launch Options - ${package.displayName}'),
      content: SizedBox(
        width: 460,
        child: StatefulBuilder(
          builder: (context, setState) => ListView(
            shrinkWrap: true,
            children: [
              for (final option in options)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Switch(
                        value: option.enabled,
                        onChanged: (v) => setState(() => option.enabled = v),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              option.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (option.description.isNotEmpty)
                              Text(
                                option.description,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            if (!option.isToggle && option.enabled)
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: SizedBox(
                                  width: 160,
                                  child: TextFormField(
                                    initialValue: option.value ?? '',
                                    decoration: InputDecoration(
                                      hintText: option.flag ?? 'value',
                                    ),
                                    onChanged: (v) => option.value = v,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              if (options.isEmpty)
                const Text('This package has no configurable launch options.'),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            store.saveLaunchArgs(
              package,
              options.map((o) => o.toJson()).toList(),
            );
            Navigator.of(dialogContext).pop();
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
}
