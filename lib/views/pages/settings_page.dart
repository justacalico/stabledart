import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../widgets/page_scaffold.dart';
import 'settings/account_settings.dart';
import 'settings/analytics_settings.dart';
import 'settings/inference_settings.dart';
import 'settings/main_settings.dart';
import 'settings/notification_settings.dart';
import 'settings/update_settings.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 6,
      child: PageScaffold(
        title: 'Settings',
        headerExtra: const TabBar(
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: [
            Tab(text: 'General'),
            Tab(text: 'Inference'),
            Tab(text: 'Accounts'),
            Tab(text: 'Updates'),
            Tab(text: 'Notifications'),
            Tab(text: 'Analytics'),
          ],
        ),
        child: const TabBarView(
          children: [
            MainSettingsView(),
            InferenceSettingsView(),
            AccountSettingsView(),
            UpdateSettingsView(),
            NotificationSettingsView(),
            AnalyticsSettingsView(),
          ],
        ),
      ),
    );
  }
}

class SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const SettingsSection({
    super.key,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(height: 8),
          Card(child: Column(children: children)),
        ],
      ),
    );
  }
}

class SettingsTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final IconData? icon;
  final VoidCallback? onTap;

  const SettingsTile({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: icon != null
          ? Icon(icon, size: 20, color: AppColors.textSecondary)
          : null,
      title: Text(title, style: const TextStyle(fontSize: 14)),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            )
          : null,
      trailing: trailing,
      onTap: onTap,
    );
  }
}
