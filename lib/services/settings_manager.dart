import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../models/app_settings.dart';
import 'settings_backend.dart';

class SettingsManager extends ChangeNotifier {
  static const _settingsKey = 'stabledart.settings';
  static const _packagesKey = 'stabledart.packages';
  static const _modelsKey = 'stabledart.models';
  static const _outputsKey = 'stabledart.outputs';
  static const _workflowsKey = 'stabledart.workflows';
  static const _conversationsKey = 'stabledart.conversations';

  final SettingsBackend _backend;
  late AppSettings settings;

  SettingsManager(this._backend) {
    _load();
  }

  void _load() {
    final raw = _backend.getString(_settingsKey);
    if (raw != null) {
      try {
        settings = AppSettings.fromJson(
          jsonDecode(raw) as Map<String, dynamic>,
        );
        return;
      } catch (_) {
        // fall through to defaults
      }
    }
    settings = AppSettings();
  }

  Future<void> save() async {
    try {
      await _backend.setString(
          _settingsKey, jsonEncode(settings.toJson()));
    } finally {
      notifyListeners();
    }
  }

  void update(void Function(AppSettings) mutate) {
    mutate(settings);
    save();
  }

  String? readRaw(String key) => _backend.getString(switch (key) {
    'settings' => _settingsKey,
    'packages' => _packagesKey,
    'models' => _modelsKey,
    'outputs' => _outputsKey,
    'workflows' => _workflowsKey,
    'conversations' => _conversationsKey,
    _ => key,
  });

  Future<void> writeRaw(String key, String value) =>
      _backend.setString(switch (key) {
        'settings' => _settingsKey,
        'packages' => _packagesKey,
        'models' => _modelsKey,
        'outputs' => _outputsKey,
        'workflows' => _workflowsKey,
        'conversations' => _conversationsKey,
        _ => key,
      }, value);
}
