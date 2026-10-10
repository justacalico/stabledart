import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../services/settings_manager.dart';
import '../settings_page.dart';

class AnalyticsSettingsView extends StatelessWidget {
  const AnalyticsSettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsManager>();
    final s = settings.settings;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        SettingsSection(
          title: 'Analytics',
          children: [
            const SettingsTile(
              title: 'Anonymous usage analytics',
              subtitle:
                  'Helps improve Stability Matrix by reporting feature '
                  'usage and crash diagnostics. No personal data or '
                  'prompts are collected.',
            ),
            SettingsTile(
              title: 'Enable Analytics',
              trailing: Switch(
                value: s.analyticsEnabled,
                onChanged: (v) =>
                    settings.update((x) => x.analyticsEnabled = v),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
