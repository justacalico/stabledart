import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../models/workflow.dart';
import '../services/settings_manager.dart';

class WorkflowsStore extends ChangeNotifier {
  final SettingsManager _settings;
  final List<InstalledWorkflow> _workflows = [];

  WorkflowsStore(this._settings) {
    _load();
  }

  List<InstalledWorkflow> get workflows => List.unmodifiable(_workflows);

  void _load() {
    final raw = _settings.readRaw('workflows');
    if (raw == null) return;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        for (final item in decoded.whereType<Map<String, dynamic>>()) {
          _workflows.add(InstalledWorkflow.fromJson(item));
        }
      }
    } on FormatException {
      // corrupted store -> start fresh
    }
  }

  Future<void> _persist() => _settings.writeRaw(
    'workflows',
    jsonEncode(_workflows.map((w) => w.toJson()).toList()),
  );

  Future<InstalledWorkflow> install({
    required String name,
    String description = '',
    String author = '',
    String baseModel = '',
    List<String> requiredNodes = const [],
  }) async {
    final workflow = InstalledWorkflow(
      id: 'wf-${DateTime.now().microsecondsSinceEpoch}',
      name: name,
      description: description,
      author: author,
      baseModel: baseModel,
      requiredNodes: requiredNodes,
      installedAt: DateTime.now(),
    );
    _workflows.add(workflow);
    await _persist();
    notifyListeners();
    return workflow;
  }

  Future<void> remove(InstalledWorkflow workflow) async {
    _workflows.removeWhere((w) => w.id == workflow.id);
    await _persist();
    notifyListeners();
  }
}
