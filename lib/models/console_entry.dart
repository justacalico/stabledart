enum ConsoleLevel { info, warning, error, debug }

class ConsoleEntry {
  final String text;
  final ConsoleLevel level;
  final DateTime timestamp;

  ConsoleEntry(this.text, {this.level = ConsoleLevel.info, DateTime? timestamp})
    : timestamp = timestamp ?? DateTime.now();
}
