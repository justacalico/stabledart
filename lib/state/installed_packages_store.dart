import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../models/installed_package.dart';
import '../models/package_definition.dart';
import '../services/package_registry.dart';
import '../services/process_runner.dart';
import '../services/settings_manager.dart';

class PackageInstallProgress {
  final String packageName;
  final String step;
  final double progress;
  final bool done;
  final String? error;

  const PackageInstallProgress(
    this.packageName,
    this.step,
    this.progress, {
    this.done = false,
    this.error,
  });
}

class InstalledPackagesStore extends ChangeNotifier {
  final SettingsManager _settings;
  final ProcessRunner _runner;
  final List<InstalledPackage> _packages = [];
  final Map<String, PackageInstallProgress> _installs = {};
  int _idCounter = 0;

  InstalledPackagesStore(this._settings, this._runner) {
    _load();
  }

  List<InstalledPackage> get packages => List.unmodifiable(_packages);
  Map<String, PackageInstallProgress> get installs =>
      Map.unmodifiable(_installs);

  void _load() {
    final raw = _settings.readRaw('packages');
    if (raw == null) return;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        for (final item in decoded.whereType<Map<String, dynamic>>()) {
          _packages.add(InstalledPackage.fromJson(item));
        }
        _idCounter = _packages.length;
      }
    } on FormatException {
      // corrupted state -> start fresh
    }
  }

  Future<void> _persist() => _settings.writeRaw(
    'packages',
    jsonEncode(_packages.map((p) => p.toJson()).toList()),
  );

  Future<InstalledPackage> install(
    PackageDefinition definition,
    String version, {
    Duration stepDelay = Duration.zero,
    Future<bool> Function(String step)? runStep,
  }) async {
    final id = 'pkg-${DateTime.now().millisecondsSinceEpoch}-${++_idCounter}';
    final steps = [
      'Resolving version',
      'Cloning repository',
      'Creating virtual environment',
      'Installing dependencies',
      'Configuring shared models',
      'Finalizing',
    ];
    for (var i = 0; i < steps.length; i++) {
      _installs[definition.name] = PackageInstallProgress(
        definition.name,
        steps[i],
        i / steps.length,
      );
      notifyListeners();
      final ok = await (runStep?.call(steps[i]) ?? Future.value(true));
      if (!ok) {
        _installs[definition.name] = PackageInstallProgress(
          definition.name,
          steps[i],
          i / steps.length,
          error: 'Step failed: ${steps[i]}',
        );
        notifyListeners();
        throw StateError('install failed at ${steps[i]}');
      }
      if (stepDelay > Duration.zero) await Future.delayed(stepDelay);
    }
    final pkg = InstalledPackage(
      id: id,
      packageName: definition.name,
      displayName: definition.displayName,
      version: version,
      installPath:
          '${_settings.settings.dataDirectory}/Packages/${definition.name}',
      installedAt: DateTime.now(),
    );
    _packages.add(pkg);
    _installs[definition.name] = PackageInstallProgress(
      definition.name,
      'Done',
      1,
      done: true,
    );
    await _persist();
    notifyListeners();
    return pkg;
  }

  Future<void> uninstall(InstalledPackage package) async {
    _packages.removeWhere((p) => p.id == package.id);
    await _persist();
    notifyListeners();
  }

  InstalledPackage? byId(String id) {
    for (final p in _packages) {
      if (p.id == id) return p;
    }
    return null;
  }

  PackageDefinition? definitionFor(InstalledPackage package) =>
      PackageRegistry.byName(package.packageName);

  Future<void> launch(
    InstalledPackage package, {
    required void Function(String line) onOutput,
  }) async {
    if (package.isRunning) return;
    package.isRunning = true;
    notifyListeners();
    try {
      await for (final line in _runner.start('python', [
        'launch.py',
        for (final arg in package.launchArgs) '$arg',
      ], workingDirectory: package.installPath)) {
        onOutput(line);
      }
    } finally {
      package.isRunning = false;
      notifyListeners();
    }
  }

  Future<void> stop(InstalledPackage package) async {
    if (!package.isRunning) return;
    await _runner.stop(package.id);
    package.isRunning = false;
    notifyListeners();
  }

  Future<void> saveLaunchArgs(
    InstalledPackage package,
    List<Map<String, dynamic>> args,
  ) async {
    final target = byId(package.id);
    if (target == null) return;
    target.launchArgs = List.of(args);
    await _persist();
    notifyListeners();
  }
}
