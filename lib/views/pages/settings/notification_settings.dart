import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/app_settings.dart';
import '../../../services/settings_manager.dart';
import '../settings_page.dart';

class NotificationSettingsView extends StatelessWidget {
  const NotificationSettingsView({super.key});

  static const events = [
    'Package install finished',
    'Download completed',
    'Download failed',
    'Inference completed',
    'Update available',
    'Package update available',
  ];

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsManager>();
    final s = settings.settings;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        SettingsSection(
          title: 'Notifications',
          children: [
            SettingsTile(
              title: 'Notification Level',
              trailing: DropdownButton<NotificationLevel>(
                value: s.notificationLevel,
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(
                    value: NotificationLevel.none,
                    child: Text('None'),
                  ),
                  DropdownMenuItem(
                    value: NotificationLevel.important,
                    child: Text('Important'),
                  ),
                  DropdownMenuItem(
                    value: NotificationLevel.all,
                    child: Text('All'),
                  ),
                ],
                onChanged: (v) => settings.update(
                  (x) => x.notificationLevel = v ?? x.notificationLevel,
                ),
              ),
            ),
            for (final event in events)
              SettingsTile(
                title: event,
                trailing: Switch(
                  value: s.notificationLevel != NotificationLevel.none,
                  onChanged: s.notificationLevel == NotificationLevel.none
                      ? null
                      : (_) {},
                ),
              ),
          ],
        ),
      ],
    );
  }
}
