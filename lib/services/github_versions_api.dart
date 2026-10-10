import 'dart:convert';

import 'package:http/http.dart' as http;

class GitHubApiException implements Exception {
  final String message;
  const GitHubApiException(this.message);
  @override
  String toString() => 'GitHubApiException: $message';
}

class GitHubVersionsApi {
  final http.Client _client;

  GitHubVersionsApi({http.Client? client}) : _client = client ?? http.Client();

  Future<List<String>> getTags(String repositoryUrl) async {
    final repoPath = _repoPath(repositoryUrl);
    if (repoPath == null) {
      throw const GitHubApiException('not a GitHub repository');
    }
    final uri = Uri.https('api.github.com', '/repos/$repoPath/tags', {
      'per_page': '100',
    });
    final response = await _client.get(
      uri,
      headers: {'Accept': 'application/json'},
    );
    if (response.statusCode != 200) {
      throw GitHubApiException('HTTP ${response.statusCode}');
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! List) {
      throw const GitHubApiException('unexpected response shape');
    }
    return decoded
        .whereType<Map<String, dynamic>>()
        .map((t) => t['name'] as String? ?? '')
        .where((n) => n.isNotEmpty)
        .toList();
  }

  Future<List<String>> getBranches(String repositoryUrl) async {
    final repoPath = _repoPath(repositoryUrl);
    if (repoPath == null) {
      throw const GitHubApiException('not a GitHub repository');
    }
    final uri = Uri.https('api.github.com', '/repos/$repoPath/branches', {
      'per_page': '100',
    });
    final response = await _client.get(
      uri,
      headers: {'Accept': 'application/json'},
    );
    if (response.statusCode != 200) {
      throw GitHubApiException('HTTP ${response.statusCode}');
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! List) {
      throw const GitHubApiException('unexpected response shape');
    }
    return decoded
        .whereType<Map<String, dynamic>>()
        .map((b) => b['name'] as String? ?? '')
        .where((n) => n.isNotEmpty)
        .toList();
  }

  static String? _repoPath(String repositoryUrl) {
    final uri = Uri.tryParse(repositoryUrl);
    if (uri == null || !uri.host.contains('github.com')) return null;
    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    if (segments.length < 2) return null;
    return '${segments[0]}/${segments[1]}';
  }
}
