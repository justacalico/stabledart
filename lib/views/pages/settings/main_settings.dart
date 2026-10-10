import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/app_settings.dart';
import '../../../services/settings_manager.dart';
import '../../../state/model_index_service.dart';
import '../../../utils/number_format.dart';
import '../../dialogs/env_vars_dialog.dart';
import '../settings_page.dart';

class MainSettingsView extends StatelessWidget {
  const MainSettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsManager>();
    final s = settings.settings;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        SettingsSection(
          title: 'Appearance',
          children: [
            SettingsTile(
              icon: Icons.dark_mode_outlined,
              title: 'Theme',
              trailing: DropdownButton<AppThemeMode>(
                value: s.themeMode,
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(
                    value: AppThemeMode.dark,
                    child: Text('Dark'),
                  ),
                  DropdownMenuItem(
                    value: AppThemeMode.light,
                    child: Text('Light'),
                  ),
                  DropdownMenuItem(
                    value: AppThemeMode.system,
                    child: Text('System'),
                  ),
                ],
                onChanged: (v) =>
                    settings.update((x) => x.themeMode = v ?? x.themeMode),
              ),
            ),
            SettingsTile(
              icon: Icons.language,
              title: 'Language',
              trailing: DropdownButton<String>(
                value: s.language,
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(value: 'en_US', child: Text('English')),
                  DropdownMenuItem(value: 'zh_CN', child: Text('中文 (简体)')),
                  DropdownMenuItem(value: 'ja_JP', child: Text('日本語')),
                  DropdownMenuItem(value: 'de_DE', child: Text('Deutsch')),
                  DropdownMenuItem(value: 'fr_FR', child: Text('Français')),
                ],
                onChanged: (v) =>
                    settings.update((x) => x.language = v ?? x.language),
              ),
            ),
            SettingsTile(
              icon: Icons.format_list_numbered,
              title: 'Number Format',
              trailing: DropdownButton<NumberFormatMode>(
                value: s.numberFormat,
                underline: const SizedBox(),
                items: [
                  for (final m in NumberFormatMode.values)
                    DropdownMenuItem(
                      value: m,
                      child: Text('${m.displayName} (${m.sample})'),
                    ),
                ],
                onChanged: (v) => settings.update(
                  (x) => x.numberFormat = v ?? x.numberFormat,
                ),
              ),
            ),
            SettingsTile(
              icon: Icons.celebration_outlined,
              title: 'Holiday Mode',
              subtitle: 'Festive theme accents during holidays',
              trailing: DropdownButton<HolidayMode>(
                value: s.holidayMode,
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(value: HolidayMode.off, child: Text('Off')),
                  DropdownMenuItem(
                    value: HolidayMode.auto,
                    child: Text('Automatic'),
                  ),
                  DropdownMenuItem(value: HolidayMode.on, child: Text('On')),
                ],
                onChanged: (v) =>
                    settings.update((x) => x.holidayMode = v ?? x.holidayMode),
              ),
            ),
            SettingsTile(
              icon: Icons.linear_scale,
              title: 'Always Show Scrollbars',
              trailing: Switch(
                value: s.alwaysShowScrollbars,
                onChanged: (v) =>
                    settings.update((x) => x.alwaysShowScrollbars = v),
              ),
            ),
          ],
        ),
        SettingsSection(
          title: 'Model Manager',
          children: [
            SettingsTile(
              icon: Icons.file_copy_outlined,
              title: 'Import Behaviour',
              subtitle: 'Copy or move files on import',
              trailing: SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: false, label: Text('Copy')),
                  ButtonSegment(value: true, label: Text('Move')),
                ],
                selected: {s.importMoveNotCopy},
                onSelectionChanged: (v) =>
                    settings.update((x) => x.importMoveNotCopy = v.first),
              ),
            ),
            SettingsTile(
              icon: Icons.link_off,
              title: 'Remove Symlinks on Shutdown',
              trailing: Switch(
                value: s.removeSymlinksOnShutdown,
                onChanged: (v) =>
                    settings.update((x) => x.removeSymlinksOnShutdown = v),
              ),
            ),
            SettingsTile(
              icon: Icons.refresh,
              title: 'Reset Checkpoints Cache',
              subtitle: 'Rebuild the model index from disk',
              trailing: FilledButton.tonal(
                onPressed: () => context.read<ModelIndexService>().resetCache(),
                child: const Text('Reset'),
              ),
            ),
          ],
        ),
        SettingsSection(
          title: 'Package Environment',
          children: [
            SettingsTile(
              icon: Icons.settings_ethernet,
              title: 'Environment Variables',
              subtitle: '${s.environmentVariables.length} variables configured',
              trailing: FilledButton.tonal(
                onPressed: () => showEnvVarsDialog(context),
                child: const Text('Edit'),
              ),
            ),
            const SettingsTile(
              icon: Icons.terminal,
              title: 'Embedded Python',
              subtitle: 'Python 3.10.11 bundled for package installs',
            ),
            const SettingsTile(
              icon: Icons.merge,
              title: 'Git',
              subtitle: 'Used for cloning package repositories',
            ),
            SettingsTile(
              icon: Icons.warning_amber,
              title: 'Show Unsupported Python Versions',
              trailing: Switch(
                value: s.showUnsupportedPythonVersions,
                onChanged: (v) =>
                    settings.update((x) => x.showUnsupportedPythonVersions = v),
              ),
            ),
          ],
        ),
        SettingsSection(
          title: 'Model Browser',
          children: [
            SettingsTile(
              icon: Icons.search,
              title: 'Auto Search on Load',
              trailing: Switch(
                value: s.autoSearchModelBrowser,
                onChanged: (v) =>
                    settings.update((x) => x.autoSearchModelBrowser = v),
              ),
            ),
            SettingsTile(
              icon: Icons.all_inclusive,
              title: 'Infinite Scrolling',
              subtitle: 'Workflow browser results',
              trailing: Switch(
                value: s.infiniteScrollingWorkflows,
                onChanged: (v) =>
                    settings.update((x) => x.infiniteScrollingWorkflows = v),
              ),
            ),
          ],
        ),
        SettingsSection(
          title: 'Console',
          children: [
            SettingsTile(
              icon: Icons.history,
              title: 'History Size',
              subtitle: '${s.consoleHistorySize} lines',
              trailing: SizedBox(
                width: 180,
                child: Slider(
                  value: s.consoleHistorySize.toDouble(),
                  min: 100,
                  max: 2000,
                  divisions: 19,
                  onChanged: (v) =>
                      settings.update((x) => x.consoleHistorySize = v.round()),
                ),
              ),
            ),
          ],
        ),
        SettingsSection(
          title: 'System',
          children: [
            SettingsTile(
              icon: Icons.download_for_offline,
              title: 'Maximum Simultaneous Downloads',
              subtitle: '${s.maxConcurrentDownloads}',
              trailing: SizedBox(
                width: 180,
                child: Slider(
                  value: s.maxConcurrentDownloads.toDouble(),
                  min: 1,
                  max: 10,
                  divisions: 9,
                  onChanged: (v) => settings.update(
                    (x) => x.maxConcurrentDownloads = v.round(),
                  ),
                ),
              ),
            ),
            SettingsTile(
              icon: Icons.folder_open,
              title: 'Data Directory',
              subtitle: s.dataDirectory.isEmpty ? 'Not set' : s.dataDirectory,
              trailing: FilledButton.tonal(
                onPressed: () => _pickDirectory(context, true),
                child: const Text('Change'),
              ),
            ),
            SettingsTile(
              icon: Icons.folder_special,
              title: 'Models Folder',
              subtitle: s.modelsDirectory.isEmpty
                  ? 'Same as data directory'
                  : s.modelsDirectory,
              trailing: FilledButton.tonal(
                onPressed: () => _pickDirectory(context, false),
                child: const Text('Change'),
              ),
            ),
            SettingsTile(
              icon: Icons.forum_outlined,
              title: 'Discord Rich Presence',
              trailing: Switch(
                value: s.discordRichPresence,
                onChanged: (v) =>
                    settings.update((x) => x.discordRichPresence = v),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _pickDirectory(BuildContext context, bool dataDir) {
    final settings = context.read<SettingsManager>();
    final controller = TextEditingController(
      text: dataDir
          ? settings.settings.dataDirectory
          : settings.settings.modelsDirectory,
    );
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(dataDir ? 'Select Data Directory' : 'Select Models Folder'),
        content: SizedBox(
          width: 460,
          child: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: '/path/to/directory'),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              settings.update((s) {
                if (dataDir) {
                  s.dataDirectory = controller.text.trim();
                } else {
                  s.modelsDirectory = controller.text.trim();
                }
              });
              Navigator.of(dialogContext).pop();
            },
            child: const Text('Select'),
          ),
        ],
      ),
    );
  }
}
