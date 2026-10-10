import '../widgets/app_logo.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../state/navigation_store.dart';
import '../../state/version_store.dart';
import '../../theme/app_theme.dart';
import '../pages/activity_page.dart';
import '../pages/banana_vision_page.dart';
import '../pages/checkpoints_page.dart';
import '../pages/documentation_page.dart';
import '../pages/inference_page.dart';
import '../pages/model_browser_page.dart';
import '../pages/outputs_page.dart';
import '../pages/packages_page.dart';
import '../pages/settings_page.dart';
import '../pages/workflows_page.dart';

class _NavDestination {
  final IconData icon;
  final String label;
  const _NavDestination(this.icon, this.label);
}

const _destinations = [
  _NavDestination(Icons.inventory_2_outlined, 'Packages'),
  _NavDestination(Icons.auto_awesome_outlined, 'Inference'),
  _NavDestination(Icons.science_outlined, 'Image Lab'),
  _NavDestination(Icons.layers_outlined, 'Model Manager'),
  _NavDestination(Icons.travel_explore_outlined, 'Model Browser'),
  _NavDestination(Icons.photo_library_outlined, 'Outputs'),
  _NavDestination(Icons.account_tree_outlined, 'Workflows'),
  _NavDestination(Icons.book_outlined, 'Documentation'),
];

const _pages = [
  PackagesPage(),
  InferencePage(),
  BananaVisionPage(),
  CheckpointsPage(),
  ModelBrowserPage(),
  OutputsPage(),
  WorkflowsPage(),
  DocumentationPage(),
];

class MainShell extends StatelessWidget {
  const MainShell({super.key});

  static const int settingsIndex = -1;
  static const int activityIndex = -2;

  @override
  Widget build(BuildContext context) {
    final nav = context.watch<NavigationStore>();
    final version = context.watch<VersionStore>();
    final selected = nav.index;
    final isSettings = selected == settingsIndex;
    final isActivity = selected == activityIndex;

    return Scaffold(
      body: Row(
        children: [
          Container(
            width: 220,
            color: AppColors.surface,
            child: Column(
              children: [
                const SizedBox(height: 16),
                const _AppTitle(),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    children: [
                      for (var i = 0; i < _destinations.length; i++)
                        _NavTile(
                          icon: _destinations[i].icon,
                          label: _destinations[i].label,
                          selected: selected == i,
                          badge:
                              i ==
                                  _destinations.indexWhere(
                                    (d) => d.label == 'Documentation',
                                  )
                              ? null
                              : null,
                          onTap: () => nav.goTo(i),
                        ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                if (version.lastResult.updateAvailable)
                  _NavTile(
                    icon: Icons.system_update_alt,
                    label: 'Update Available',
                    accent: AppColors.mediumSeaGreen,
                    selected: false,
                    onTap: () {
                      launchUrl(Uri.parse(version.lastResult.releaseUrl));
                    },
                  ),
                _NavTile(
                  icon: Icons.history,
                  label: 'Activity',
                  selected: isActivity,
                  badge: nav.activityBadgeCount > 0
                      ? nav.activityBadgeCount
                      : null,
                  onTap: () => nav.goTo(activityIndex),
                ),
                _NavTile(
                  icon: Icons.favorite_outline,
                  label: 'Support Us',
                  selected: false,
                  onTap: () => launchUrl(Uri.parse('https://lykos.ai/support')),
                ),
                _NavTile(
                  icon: Icons.forum_outlined,
                  label: 'Join Discord',
                  selected: false,
                  onTap: () =>
                      launchUrl(Uri.parse('https://discord.gg/TuZ6b9mSfh')),
                ),
                _NavTile(
                  icon: Icons.settings_outlined,
                  label: 'Settings',
                  selected: isSettings,
                  onTap: () => nav.goTo(settingsIndex),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
          const VerticalDivider(width: 1, color: AppColors.border),
          Expanded(
            child: isSettings
                ? const SettingsPage()
                : isActivity
                ? const ActivityPage()
                : IndexedStack(index: selected, children: _pages),
          ),
        ],
      ),
    );
  }
}

class _AppTitle extends StatelessWidget {
  const _AppTitle();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const AppLogo(size: 28),
        const SizedBox(width: 10),
        const Flexible(
          child: Text(
            'Stability Matrix',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _NavTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final int? badge;
  final Color? accent;
  final VoidCallback onTap;

  const _NavTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.badge,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        accent ?? (selected ? AppColors.accent : AppColors.textSecondary);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: selected ? AppColors.surfaceAlt : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(icon, size: 20, color: color),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: selected
                          ? AppColors.text
                          : (accent ?? AppColors.textSecondary),
                      fontSize: 13.5,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$badge',
                      style: const TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
