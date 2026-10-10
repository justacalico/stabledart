class Version implements Comparable<Version> {
  final List<int> core;
  final List<String>? pre;

  Version({required this.core, this.pre}) : assert(core.length == 3);

  static final _corePartPattern = RegExp(r'^(0|[1-9]\d*)$');
  static final _prePattern = RegExp(r'^[0-9A-Za-z-]+$');

  static Version? parse(String? input) {
    if (input == null || input.isEmpty) return null;
    var cleaned = input.trim();
    while (cleaned.startsWith('v') || cleaned.startsWith('V')) {
      cleaned = cleaned.substring(1);
    }

    final plus = cleaned.indexOf('+');
    if (plus != -1) cleaned = cleaned.substring(0, plus);

    final dash = cleaned.indexOf('-');
    var corePart = cleaned;
    List<String>? pre;
    if (dash != -1) {
      corePart = cleaned.substring(0, dash);
      pre = cleaned.substring(dash + 1).split('.');
      if (pre.isEmpty) return null;
    }

    final parts = corePart.split('.');
    if (parts.length != 3) return null;
    final core = <int>[];
    for (final p in parts) {
      if (!_corePartPattern.hasMatch(p)) return null;
      final n = int.tryParse(p);
      if (n == null || n < 0) return null;
      core.add(n);
    }

    if (pre != null) {
      for (final p in pre) {
        if (p.isEmpty || !_prePattern.hasMatch(p)) return null;
        if (_isNumeric(p) && p.length > 1 && p.startsWith('0')) return null;
      }
    }

    return Version(core: core, pre: pre);
  }

  static bool _isNumeric(String s) => RegExp(r'^\d+$').hasMatch(s);

  @override
  int compareTo(Version other) {
    for (var i = 0; i < 3; i++) {
      final c = core[i].compareTo(other.core[i]);
      if (c != 0) return c;
    }
    final a = pre;
    final b = other.pre;
    if (a == null && b == null) return 0;
    if (a == null) return 1;
    if (b == null) return -1;
    final len = a.length < b.length ? a.length : b.length;
    for (var i = 0; i < len; i++) {
      final c = _comparePrePart(a[i], b[i]);
      if (c != 0) return c;
    }
    return a.length.compareTo(b.length);
  }

  static int _comparePrePart(String a, String b) {
    final aNum = _isNumeric(a);
    final bNum = _isNumeric(b);
    if (aNum && bNum) {
      final cmp = int.parse(a).compareTo(int.parse(b));
      return cmp != 0 ? cmp : 0;
    }
    if (aNum) return -1;
    if (bNum) return 1;
    return a.compareTo(b);
  }

  @override
  bool operator ==(Object other) =>
      other is Version &&
      core.length == other.core.length &&
      core.every((e) => other.core.contains(e)) &&
      _listEquals(pre, other.pre);

  bool _listEquals(List<String>? a, List<String>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(core[0], core[1], core[2], pre?.join('.'));

  @override
  String toString() =>
      core.join('.') + (pre != null ? '-${pre!.join('.')}' : '');
}
