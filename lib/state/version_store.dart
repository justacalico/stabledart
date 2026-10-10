import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/app_update.dart';
import '../services/version_checker.dart';

enum VersionCheckStatus { idle, checking, success, failed }

class VersionStore extends ChangeNotifier {
  final VersionChecker _checker;
  final String Function() _currentVersion;

  VersionCheckStatus status = VersionCheckStatus.idle;
  AppUpdate lastResult = const AppUpdate();
  String? errorMessage;
  Future<void>? _inFlight;

  VersionStore(this._checker, this._currentVersion);

  Future<void> checkForUpdates() {
    final existing = _inFlight;
    if (existing != null) return existing;
    final future = _check();
    _inFlight = future;
    return future;
  }

  Future<void> _check() async {
    status = VersionCheckStatus.checking;
    errorMessage = null;
    notifyListeners();
    try {
      lastResult = await _checker.check(_currentVersion());
      status = VersionCheckStatus.success;
    } catch (e) {
      status = VersionCheckStatus.failed;
      errorMessage = '$e';
    } finally {
      _inFlight = null;
      notifyListeners();
    }
  }
}
