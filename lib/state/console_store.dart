import 'package:flutter/foundation.dart';

import '../models/console_entry.dart';

class ConsoleStore extends ChangeNotifier {
  final List<ConsoleEntry> _entries = [];
  final int maxHistory;

  ConsoleStore({this.maxHistory = 300});

  List<ConsoleEntry> get entries => List.unmodifiable(_entries);
  bool get isEmpty => _entries.isEmpty;

  void log(String text, {ConsoleLevel level = ConsoleLevel.info}) {
    _entries.add(ConsoleEntry(text, level: level));
    if (_entries.length > maxHistory) {
      _entries.removeRange(0, _entries.length - maxHistory);
    }
    notifyListeners();
  }

  void clear() {
    _entries.clear();
    notifyListeners();
  }
}
