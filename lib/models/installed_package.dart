class InstalledPackage {
  final String id;
  final String packageName;
  final String displayName;
  final String version;
  final String installPath;
  final DateTime installedAt;
  List<Map<String, dynamic>> launchArgs;
  bool isRunning;

  InstalledPackage({
    required this.id,
    required this.packageName,
    required this.displayName,
    required this.version,
    required this.installPath,
    required this.installedAt,
    this.launchArgs = const [],
    this.isRunning = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'packageName': packageName,
    'displayName': displayName,
    'version': version,
    'installPath': installPath,
    'installedAt': installedAt.toIso8601String(),
    'launchArgs': launchArgs,
  };

  factory InstalledPackage.fromJson(Map<String, dynamic> json) =>
      InstalledPackage(
        id: json['id'] as String,
        packageName: json['packageName'] as String,
        displayName: json['displayName'] as String,
        version: json['version'] as String? ?? '',
        installPath: json['installPath'] as String? ?? '',
        installedAt:
            DateTime.tryParse(json['installedAt'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
        launchArgs: (json['launchArgs'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .toList(),
      );
}
