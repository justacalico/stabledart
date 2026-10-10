import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/hf_models.dart';

class HuggingFaceApiException implements Exception {
  final String message;
  const HuggingFaceApiException(this.message);
  @override
  String toString() => 'HuggingFaceApiException: $message';
}

class HuggingFaceApi {
  static const host = 'huggingface.co';

  final http.Client _client;
  final String? Function() _apiKeyProvider;

  HuggingFaceApi({http.Client? client, String? apiKey, String? Function()? apiKeyProvider})
      : _apiKeyProvider = apiKeyProvider ?? (() => apiKey),
        _client = client ?? http.Client();

  Map<String, String> get _headers => {
    'Accept': 'application/json',
    if (_apiKeyProvider() case final k? when k.isNotEmpty) 'Authorization': 'Bearer $k',
  };

  Future<List<HuggingFaceModel>> searchModels({
    String? query,
    String? author,
    String sort = 'downloads',
    int limit = 50,
  }) async {
    final params = <String, String>{
      'sort': sort,
      'direction': '-1',
      'limit': '$limit',
    };
    if (query != null && query.isNotEmpty) params['search'] = query;
    if (author != null && author.isNotEmpty) params['author'] = author;
    final uri = Uri.https(host, '/api/models', params);
    final response = await _client.get(uri, headers: _headers).timeout(const Duration(seconds: 30));
    if (response.statusCode != 200) {
      throw HuggingFaceApiException('HTTP ${response.statusCode}');
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! List) {
      throw const HuggingFaceApiException('unexpected response shape');
    }
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(HuggingFaceModel.fromJson)
        .toList();
  }

  Future<List<HuggingFaceFile>> listFiles(String modelId) async {
    final uri = Uri.https(host, '/api/models/$modelId/tree/main');
    final response = await _client.get(uri, headers: _headers).timeout(const Duration(seconds: 30));
    if (response.statusCode != 200) {
      throw HuggingFaceApiException('HTTP ${response.statusCode}');
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! List) {
      throw const HuggingFaceApiException('unexpected response shape');
    }
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(HuggingFaceFile.fromJson)
        .toList();
  }

  static String downloadUrl(String modelId, String path) =>
      'https://$host/$modelId/resolve/main/$path';
}
