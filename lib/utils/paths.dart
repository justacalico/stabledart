import 'dart:io';

String expandHome(String path) {
  if (!path.startsWith('~')) return path;
  final home =
      Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'] ?? '';
  return '$home${path.substring(1)}';
}

String downloadDestination(String dataDirectory, String fileName) =>
    '${expandHome(dataDirectory)}/Models/$fileName';
