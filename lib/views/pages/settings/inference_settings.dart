import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../services/settings_manager.dart';
import '../settings_page.dart';

class InferenceSettingsView extends StatelessWidget {
  const InferenceSettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsManager>();
    final s = settings.settings;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        SettingsSection(
          title: 'Defaults',
          children: [
            SettingsTile(
              title: 'Default Steps',
              subtitle: '${s.defaultSteps}',
              trailing: SizedBox(
                width: 180,
                child: Slider(
                  value: s.defaultSteps.toDouble(),
                  min: 1,
                  max: 150,
                  divisions: 149,
                  onChanged: (v) =>
                      settings.update((x) => x.defaultSteps = v.round()),
                ),
              ),
            ),
            SettingsTile(
              title: 'Default CFG Scale',
              subtitle: s.defaultCfgScale.toStringAsFixed(1),
              trailing: SizedBox(
                width: 180,
                child: Slider(
                  value: s.defaultCfgScale,
                  min: 1,
                  max: 30,
                  divisions: 58,
                  onChanged: (v) =>
                      settings.update((x) => x.defaultCfgScale = v),
                ),
              ),
            ),
            SettingsTile(
              title: 'Default Width',
              subtitle: '${s.defaultWidth}px',
              trailing: SizedBox(
                width: 180,
                child: Slider(
                  value: s.defaultWidth.toDouble(),
                  min: 64,
                  max: 2048,
                  divisions: 31,
                  onChanged: (v) =>
                      settings.update((x) => x.defaultWidth = v.round()),
                ),
              ),
            ),
            SettingsTile(
              title: 'Default Height',
              subtitle: '${s.defaultHeight}px',
              trailing: SizedBox(
                width: 180,
                child: Slider(
                  value: s.defaultHeight.toDouble(),
                  min: 64,
                  max: 2048,
                  divisions: 31,
                  onChanged: (v) =>
                      settings.update((x) => x.defaultHeight = v.round()),
                ),
              ),
            ),
          ],
        ),
        SettingsSection(
          title: 'Output',
          children: [
            SettingsTile(
              title: 'Model Directory',
              subtitle: s.inferenceModelDirectory.isEmpty
                  ? 'Shared models folder'
                  : s.inferenceModelDirectory,
            ),
            SettingsTile(
              title: 'Shared Outputs Folder',
              subtitle: 'Save generated images to the shared outputs directory',
              trailing: Switch(
                value: s.inferenceSharedOutput,
                onChanged: (v) =>
                    settings.update((x) => x.inferenceSharedOutput = v),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
