abstract class SettingsBackend {
  String? getString(String key);
  Future<void> setString(String key, String value);
}

class SharedPreferencesBackend implements SettingsBackend {
  final dynamic _prefs;

  SharedPreferencesBackend(this._prefs);

  @override
  String? getString(String key) => _prefs.getString(key) as String?;

  @override
  Future<void> setString(String key, String value) async {
    await _prefs.setString(key, value);
  }
}

class MemorySettingsBackend implements SettingsBackend {
  final Map<String, String> _values = {};

  @override
  String? getString(String key) => _values[key];

  @override
  Future<void> setString(String key, String value) async {
    _values[key] = value;
  }
}
