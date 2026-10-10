import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/download_task.dart';

typedef BytesSink = StreamSink<List<int>>;

abstract class DownloadFileWriter {
  Future<StreamSink<List<int>>> openWrite(String path);
}

class IoFileWriter implements DownloadFileWriter {
  @override
  Future<StreamSink<List<int>>> openWrite(String path) async {
    final file = File(path);
    await file.parent.create(recursive: true);
    return file.openWrite();
  }
}

class DownloadService extends ChangeNotifier {
  final DownloadFileWriter? _fileWriter;
  final int maxConcurrent;

  final List<DownloadTask> _tasks = [];
  final Map<String, http.Client> _taskClients = {};
  final Map<String, bool> _pauseRequests = {};
  int _idCounter = 0;

  final http.Client Function() _clientFactory;
  bool _disposed = false;

  DownloadService({
    http.Client? client,
    http.Client Function()? clientFactory,
    DownloadFileWriter? fileWriter,
    this.maxConcurrent = 3,
  })  : _clientFactory = clientFactory ?? (() => client ?? http.Client()),
        _fileWriter = fileWriter;

  List<DownloadTask> get tasks => List.unmodifiable(_tasks);

  int get activeCount => _tasks.where((t) => t.isActive).length;

  DownloadTask enqueue({
    required String fileName,
    required String url,
    String destinationPath = '',
    int totalBytes = 0,
  }) {
    if (destinationPath.isNotEmpty) {
      for (final existing in _tasks) {
        if (existing.destinationPath == destinationPath &&
            !existing.isFinished) {
          return existing;
        }
      }
    }
    final task = DownloadTask(
      id: 'dl-${++_idCounter}',
      fileName: fileName,
      url: url,
      destinationPath: destinationPath,
      totalBytes: totalBytes,
    );
    _tasks.insert(0, task);
    notifyListeners();
    _pumpQueue();
    return task;
  }

  void _pumpQueue() {
    final running = _tasks
        .where((t) => t.status == DownloadStatus.downloading)
        .length;
    if (running >= maxConcurrent) return;
    for (final task in _tasks.reversed) {
      if (_tasks.where((t) => t.status == DownloadStatus.downloading).length >=
          maxConcurrent) {
        break;
      }
      if (task.status == DownloadStatus.queued) {
        unawaited(_start(task));
      }
    }
  }

  Future<void> _start(DownloadTask task) async {
    if (_disposed) return;
    task.status = DownloadStatus.downloading;
    _pauseRequests[task.id] = false;
    notifyListeners();
    final client = _taskClients.putIfAbsent(task.id, _clientFactory);
    StreamSink<List<int>>? sink;
    try {
      final request = http.Request('GET', Uri.parse(task.url));
      final response = await client.send(request).timeout(const Duration(seconds: 30));
      if (response.statusCode != 200) {
        task.status = DownloadStatus.failed;
        task.errorMessage = 'HTTP ${response.statusCode}';
        notifyListeners();
        _cleanup(task.id);
        _pumpQueue();
        return;
      }
      if (response.contentLength != null && response.contentLength! > 0) {
        task.totalBytes = response.contentLength!;
      }
      if (task.destinationPath.isNotEmpty) {
        sink = await _fileWriter?.openWrite(task.destinationPath);
      }
      final stopwatch = Stopwatch()..start();
      var lastBytes = 0;
      var lastTick = 0;
      await for (final chunk in response.stream) {
        if (task.status == DownloadStatus.cancelled) break;
        if (_pauseRequests[task.id] == true) {
          task.status = DownloadStatus.paused;
          notifyListeners();
          await sink?.close();
          _cleanup(task.id);
          _pumpQueue();
          return;
        }
        sink?.add(chunk);
        task.receivedBytes += chunk.length;
        final elapsed = stopwatch.elapsedMilliseconds;
        if (elapsed - lastTick >= 500) {
          task.bytesPerSecond =
              (task.receivedBytes - lastBytes) / ((elapsed - lastTick) / 1000);
          lastBytes = task.receivedBytes;
          lastTick = elapsed;
          notifyListeners();
        }
      }
      await sink?.close();
      if (task.status == DownloadStatus.downloading) {
        task.status = DownloadStatus.completed;
        task.bytesPerSecond = 0;
      }
    } catch (e) {
      await sink?.close();
      if (task.status == DownloadStatus.downloading) {
        task.status = DownloadStatus.failed;
        task.errorMessage = '$e';
      }
    }
    if (!_disposed) notifyListeners();
    _cleanup(task.id);
    _pumpQueue();
  }

  void _cleanup(String taskId) {
    _taskClients.remove(taskId)?.close();
  }

  void pause(DownloadTask task) {
    if (task.status != DownloadStatus.downloading) return;
    _pauseRequests[task.id] = true;
    task.status = DownloadStatus.paused;
    _taskClients[task.id]?.close();
    notifyListeners();
  }

  void resume(DownloadTask task) {
    if (task.status != DownloadStatus.paused &&
        task.status != DownloadStatus.failed) {
      return;
    }
    _pauseRequests[task.id] = false;
    task.status = DownloadStatus.queued;
    task.receivedBytes = 0;
    task.bytesPerSecond = 0;
    task.errorMessage = null;
    notifyListeners();
    _pumpQueue();
  }

  void cancel(DownloadTask task) {
    if (task.status == DownloadStatus.downloading) {
      task.status = DownloadStatus.cancelled;
      _taskClients[task.id]?.close();
    } else if (task.status == DownloadStatus.queued ||
        task.status == DownloadStatus.paused) {
      task.status = DownloadStatus.cancelled;
    }
    notifyListeners();
    _pumpQueue();
  }

  void remove(DownloadTask task) {
    if (task.isActive) cancel(task);
    _tasks.remove(task);
    notifyListeners();
  }

  void clearCompleted() {
    _tasks.removeWhere((t) => t.isFinished);
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    for (final client in _taskClients.values) {
      client.close();
    }
    _taskClients.clear();
    super.dispose();
  }
}
