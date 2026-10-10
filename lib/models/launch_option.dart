class LaunchOption {
  final String name;
  final String? flag;
  final String description;
  final String? initialValue;
  final List<String>? choices;
  final bool isToggle;
  bool enabled;
  String? value;

  LaunchOption({
    required this.name,
    this.flag,
    this.description = '',
    this.initialValue,
    this.choices,
    this.isToggle = false,
    this.enabled = false,
    this.value,
  });

  factory LaunchOption.toggle(
    String name,
    String flag, {
    String description = '',
    bool enabled = false,
  }) => LaunchOption(
    name: name,
    flag: flag,
    description: description,
    isToggle: true,
    enabled: enabled,
  );

  String? toArgString() {
    if (!enabled) return null;
    if (isToggle) return flag;
    if (value == null || value!.isEmpty) return null;
    return flag != null ? '$flag $value' : value;
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'enabled': enabled,
    'value': value,
  };

  void applyJson(Map<String, dynamic> json) {
    enabled = json['enabled'] as bool? ?? enabled;
    value = json['value'] as String? ?? value;
  }
}
