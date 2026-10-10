import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../services/settings_manager.dart';
import '../settings_page.dart';

class AccountSettingsView extends StatelessWidget {
  const AccountSettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsManager>();
    final s = settings.settings;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        SettingsSection(
          title: 'Lykos Account',
          children: [
            SettingsTile(
              title: s.lykosAccountName ?? 'Not signed in',
              subtitle: s.lykosAccountName != null
                  ? 'Signed in to Lykos AI'
                  : 'Sign in to sync preferences and Supporter features',
              trailing: FilledButton.tonal(
                onPressed: () => _lykosLogin(context),
                child: Text(s.lykosAccountName != null ? 'Manage' : 'Sign In'),
              ),
            ),
          ],
        ),
        SettingsSection(
          title: 'API Keys',
          children: [
            SettingsTile(
              title: 'CivitAI API Key',
              subtitle: s.civitAiApiKey != null
                  ? 'Configured'
                  : 'Required for some downloads',
              trailing: FilledButton.tonal(
                onPressed: () => _apiKeyDialog(
                  context,
                  'CivitAI API Key',
                  s.civitAiApiKey,
                  (v) => settings.update((x) => x.civitAiApiKey = v),
                ),
                child: const Text('Edit'),
              ),
            ),
            SettingsTile(
              title: 'HuggingFace Token',
              subtitle: s.huggingFaceApiKey != null
                  ? 'Configured'
                  : 'For gated models',
              trailing: FilledButton.tonal(
                onPressed: () => _apiKeyDialog(
                  context,
                  'HuggingFace Token',
                  s.huggingFaceApiKey,
                  (v) => settings.update((x) => x.huggingFaceApiKey = v),
                ),
                child: const Text('Edit'),
              ),
            ),
            SettingsTile(
              title: 'Gemini API Key',
              subtitle: s.geminiApiKey != null
                  ? 'Configured'
                  : 'Used by Image Lab',
              trailing: FilledButton.tonal(
                onPressed: () => _apiKeyDialog(
                  context,
                  'Gemini API Key',
                  s.geminiApiKey,
                  (v) => settings.update((x) => x.geminiApiKey = v),
                ),
                child: const Text('Edit'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _lykosLogin(BuildContext context) {
    final settings = context.read<SettingsManager>();
    final controller = TextEditingController(
      text: settings.settings.lykosAccountName ?? '',
    );
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Lykos Account'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                decoration: const InputDecoration(labelText: 'Account name'),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () => launchUrl(Uri.parse('https://lykos.ai')),
                  child: const Text('Open lykos.ai'),
                ),
              ),
            ],
          ),
        ),
        actions: [
          if (settings.settings.lykosAccountName != null)
            TextButton(
              onPressed: () {
                settings.update((s) => s.lykosAccountName = null);
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Sign Out'),
            ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final name = controller.text.trim();
              settings.update(
                (s) => s.lykosAccountName = name.isEmpty ? null : name,
              );
              Navigator.of(dialogContext).pop();
            },
            child: const Text('Sign In'),
          ),
        ],
      ),
    );
  }

  void _apiKeyDialog(
    BuildContext context,
    String title,
    String? current,
    void Function(String?) save,
  ) {
    final controller = TextEditingController(text: current ?? '');
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: 420,
          child: TextField(
            controller: controller,
            obscureText: true,
            decoration: const InputDecoration(hintText: 'Paste key'),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              save(null);
              Navigator.of(dialogContext).pop();
            },
            child: const Text('Clear'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final v = controller.text.trim();
              save(v.isEmpty ? null : v);
              Navigator.of(dialogContext).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
