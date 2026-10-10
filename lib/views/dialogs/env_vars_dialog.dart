import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/settings_manager.dart';
import '../../theme/app_theme.dart';

void showEnvVarsDialog(BuildContext context) {
  final settings = context.read<SettingsManager>();
  final entries = settings.settings.environmentVariables.entries
      .map(
        (e) => MapEntry(
          TextEditingController(text: e.key),
          TextEditingController(text: e.value),
        ),
      )
      .toList();
  if (entries.isEmpty) {
    entries.add(MapEntry(TextEditingController(), TextEditingController()));
  }

  showDialog<void>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('Environment Variables'),
        content: SizedBox(
          width: 520,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 320),
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (var i = 0; i < entries.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: entries[i].key,
                                decoration: const InputDecoration(
                                  hintText: 'NAME',
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: entries[i].value,
                                decoration: const InputDecoration(
                                  hintText: 'value',
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.remove_circle_outline,
                                size: 18,
                                color: AppColors.red,
                              ),
                              onPressed: () =>
                                  setState(() => entries.removeAt(i)),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => setState(
                    () => entries.add(
                      MapEntry(
                        TextEditingController(),
                        TextEditingController(),
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Variable'),
                ),
              ),
            ],
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
                s.environmentVariables = {
                  for (final e in entries)
                    if (e.key.text.trim().isNotEmpty)
                      e.key.text.trim(): e.value.text,
                };
              });
              Navigator.of(dialogContext).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    ),
  );
}
