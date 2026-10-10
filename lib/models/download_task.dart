enum DownloadStatus {
  queued,
  downloading,
  paused,
  completed,
  failed,
  cancelled,
}

class DownloadTask {
  final String id;
  final String fileName;
  final String url;
  final String destinationPath;
  DownloadStatus status;
  int receivedBytes;
  int totalBytes;
  double bytesPerSecond;
  String? errorMessage;
  final DateTime createdAt;

  DownloadTask({
    required this.id,
    required this.fileName,
    required this.url,
    this.destinationPath = '',
    this.status = DownloadStatus.queued,
    this.receivedBytes = 0,
    this.totalBytes = 0,
    this.bytesPerSecond = 0,
    this.errorMessage,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  double get progress => totalBytes > 0 ? receivedBytes / totalBytes : 0;

  bool get isActive =>
      status == DownloadStatus.queued || status == DownloadStatus.downloading;

  bool get isFinished =>
      status == DownloadStatus.completed ||
      status == DownloadStatus.failed ||
      status == DownloadStatus.cancelled;
}
