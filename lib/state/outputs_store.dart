import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../models/output_image.dart';
import '../services/settings_manager.dart';

class OutputsStore extends ChangeNotifier {
  final SettingsManager _settings;
  final List<OutputImage> _outputs = [];
  String _query = '';
  String? _folderFilter;

  OutputsStore(this._settings) {
    _load();
  }

  List<OutputImage> get outputs => List.unmodifiable(_outputs);
  String get query => _query;
  String? get folderFilter => _folderFilter;

  List<String> get folders {
    final set = <String>{};
    for (final o in _outputs) {
      final idx = o.filePath.lastIndexOf('/');
      set.add(idx > 0 ? o.filePath.substring(0, idx) : o.filePath);
    }
    final list = set.toList()..sort();
    return list;
  }

  List<OutputImage> get filtered {
    return _outputs.where((o) {
      if (_folderFilter != null) {
        final idx = o.filePath.lastIndexOf('/');
        final folder = idx > 0 ? o.filePath.substring(0, idx) : o.filePath;
        if (folder != _folderFilter) return false;
      }
      if (_query.isNotEmpty &&
          !o.prompt.toLowerCase().contains(_query.toLowerCase())) {
        return false;
      }
      return true;
    }).toList();
  }

  void setQuery(String q) {
    _query = q;
    notifyListeners();
  }

  void setFolderFilter(String? folder) {
    _folderFilter = folder;
    notifyListeners();
  }

  void _load() {
    final raw = _settings.readRaw('outputs');
    if (raw == null) return;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        for (final item in decoded.whereType<Map<String, dynamic>>()) {
          _outputs.add(OutputImage.fromJson(item));
        }
      }
    } on FormatException {
      // corrupted store -> start fresh
    }
  }

  Future<void> _persist() => _settings.writeRaw(
    'outputs',
    jsonEncode(_outputs.map((o) => o.toJson()).toList()),
  );

  Future<void> add(OutputImage image) async {
    _outputs.insert(0, image);
    await _persist();
    notifyListeners();
  }

  Future<void> remove(OutputImage image) async {
    _outputs.removeWhere((o) => o.id == image.id);
    await _persist();
    notifyListeners();
  }

  Future<void> clear() async {
    _outputs.clear();
    await _persist();
    notifyListeners();
  }
}
