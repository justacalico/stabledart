import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../services/settings_manager.dart';
import '../../../state/version_store.dart';
import '../settings_page.dart';

class UpdateSettingsView extends StatelessWidget {
  const UpdateSettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsManager>();
    final version = context.watch<VersionStore>();
    final s = settings.settings;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        SettingsSection(
          title: 'Updates',
          children: [
            SettingsTile(
              title: 'Check for updates',
              subtitle: switch (version.status) {
                VersionCheckStatus.idle =>
                  'Check GitLab releases for a newer version',
                VersionCheckStatus.checking => 'Checking...',
                VersionCheckStatus.failed =>
                  'Check failed: ${version.errorMessage ?? ''}',
                VersionCheckStatus.success =>
                  version.lastResult.updateAvailable
                      ? 'Version ${version.lastResult.latestVersion} is available'
                      : 'You are up to date',
              },
              trailing: version.status == VersionCheckStatus.checking
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : FilledButton.tonal(
                      onPressed: version.checkForUpdates,
                      child: const Text('Check Now'),
                    ),
            ),
            if (version.lastResult.updateAvailable)
              SettingsTile(
                title: 'Download version ${version.lastResult.latestVersion}',
                trailing: FilledButton.icon(
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: const Text('Release Page'),
                  onPressed: () =>
                      launchUrl(Uri.parse(version.lastResult.releaseUrl)),
                ),
              ),
            SettingsTile(
              title: 'All releases',
              trailing: TextButton(
                onPressed: () => launchUrl(
                  Uri.parse(
                    'https://gitlab.com/HttpAnimations/stabledart/-/releases',
                  ),
                ),
                child: const Text('View Releases'),
              ),
            ),
            SettingsTile(
              title: 'Check on launch',
              trailing: Switch(
                value: s.updateCheckOnLaunch,
                onChanged: (v) =>
                    settings.update((x) => x.updateCheckOnLaunch = v),
              ),
            ),
            SettingsTile(
              title: 'Include pre-releases',
              trailing: Switch(
                value: s.updatePrerelease,
                onChanged: (v) =>
                    settings.update((x) => x.updatePrerelease = v),
              ),
            ),
          ],
        ),
        const SettingsSection(
          title: 'About',
          children: [
            SettingsTile(
              title: 'Stability Matrix',
              subtitle:
                  'A Flutter port of the Stability Matrix package manager and inference UI.',
            ),
          ],
        ),
      ],
    );
  }
}
