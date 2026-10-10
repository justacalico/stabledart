import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../models/local_model.dart';
import '../services/settings_manager.dart';

class ModelIndexService extends ChangeNotifier {
  final SettingsManager _settings;
  final List<LocalModelFile> _models = [];
  String _query = '';
  ModelCategory? _categoryFilter;

  ModelIndexService(this._settings) {
    _load();
  }

  List<LocalModelFile> get models => List.unmodifiable(_models);
  String get query => _query;
  ModelCategory? get categoryFilter => _categoryFilter;

  List<LocalModelFile> get filtered {
    return _models.where((m) {
      if (_categoryFilter != null && m.category != _categoryFilter) {
        return false;
      }
      if (_query.isNotEmpty) {
        final q = _query.toLowerCase();
        if (!m.displayTitle.toLowerCase().contains(q) &&
            !m.fileName.toLowerCase().contains(q)) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  Map<ModelCategory, List<LocalModelFile>> get byCategory {
    final map = <ModelCategory, List<LocalModelFile>>{};
    for (final m in filtered) {
      map.putIfAbsent(m.category, () => []).add(m);
    }
    return map;
  }

  int countFor(ModelCategory category) =>
      _models.where((m) => m.category == category).length;

  void setQuery(String value) {
    _query = value;
    notifyListeners();
  }

  void setCategoryFilter(ModelCategory? category) {
    _categoryFilter = category;
    notifyListeners();
  }

  void _load() {
    final raw = _settings.readRaw('models');
    if (raw == null) return;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        for (final item in decoded.whereType<Map<String, dynamic>>()) {
          _models.add(LocalModelFile.fromJson(item));
        }
      }
    } catch (_) {
      // corrupted index -> start fresh
    }
  }

  Future<void> _persist() => _settings.writeRaw(
    'models',
    jsonEncode(_models.map((m) => m.toJson()).toList()),
  );

  Future<LocalModelFile> importFile({
    required String fileName,
    ModelCategory category = ModelCategory.unknown,
    int sizeBytes = 0,
    String? thumbnailUrl,
  }) async {
    final model = LocalModelFile(
      id: 'model-${DateTime.now().microsecondsSinceEpoch}',
      fileName: fileName,
      category: category,
      sizeBytes: sizeBytes,
      thumbnailUrl: thumbnailUrl,
    );
    _models.add(model);
    await _persist();
    notifyListeners();
    return model;
  }

  Future<void> remove(LocalModelFile model) async {
    _models.removeWhere((m) => m.id == model.id);
    await _persist();
    notifyListeners();
  }

  Future<void> updateMetadata(
    LocalModelFile model, {
    String? title,
    String? author,
    String? description,
    String? thumbnailUrl,
    ModelCategory? category,
    bool? isShared,
  }) async {
    if (title != null) model.title = title;
    if (author != null) model.author = author;
    if (description != null) model.description = description;
    if (thumbnailUrl != null) model.thumbnailUrl = thumbnailUrl;
    if (category != null) model.category = category;
    if (isShared != null) model.isShared = isShared;
    await _persist();
    notifyListeners();
  }

  Future<void> resetCache() async {
    _models.clear();
    await _persist();
    notifyListeners();
  }

  List<LocalModelFile> whereType(ModelCategory category) =>
      _models.where((m) => m.category == category).toList();
}
