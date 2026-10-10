import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/civit_models.dart';

class CivitApiException implements Exception {
  final String message;
  const CivitApiException(this.message);
  @override
  String toString() => 'CivitApiException: $message';
}

class CivitModelsPage {
  final List<CivitModel> items;
  final String? nextCursor;

  const CivitModelsPage({required this.items, this.nextCursor});
}

class CivitAiApi {
  static const host = 'civitai.com';
  static const apiBase = 'https://civitai.com/api/v1';

  final http.Client _client;
  final String? Function() _apiKeyProvider;

  CivitAiApi({http.Client? client, String? apiKey, String? Function()? apiKeyProvider})
      : _apiKeyProvider = apiKeyProvider ?? (() => apiKey),
        _client = client ?? http.Client();

  Map<String, String> get _headers => {
    'Accept': 'application/json',
    if (_apiKeyProvider() case final k? when k.isNotEmpty) 'Authorization': 'Bearer $k',
  };

  Future<CivitModelsPage> getModels({
    int limit = 50,
    String? query,
    CivitModelType type = CivitModelType.all,
    CivitSort sort = CivitSort.mostDownloaded,
    CivitPeriod period = CivitPeriod.allTime,
    List<String> baseModels = const [],
    bool nsfw = false,
    String? cursor,
  }) async {
    final params = <String, String>{
      'limit': '$limit',
      'sort': _sortParam(sort),
      'period': _periodParam(period),
      'nsfw': '$nsfw',
    };
    if (query != null && query.isNotEmpty) params['query'] = query;
    if (type.apiValue.isNotEmpty) params['types'] = type.apiValue;
    if (baseModels.isNotEmpty) params['baseModels'] = baseModels.join(',');
    if (cursor != null && cursor.isNotEmpty) params['cursor'] = cursor;

    final uri = Uri.https(host, '/api/v1/models', params);
    final response = await _client.get(uri, headers: _headers).timeout(const Duration(seconds: 30));
    if (response.statusCode != 200) {
      throw CivitApiException('HTTP ${response.statusCode}');
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const CivitApiException('unexpected response shape');
    }
    final items = (decoded['items'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(CivitModel.fromJson)
        .toList();
    final metadata = decoded['metadata'];
    String? nextCursor;
    if (metadata is Map<String, dynamic>) {
      nextCursor = metadata['nextCursor']?.toString();
      final nextPage = metadata['nextPage'] as String?;
      if (nextCursor == null && nextPage != null) {
        nextCursor = Uri.tryParse(nextPage)?.queryParameters['cursor'];
      }
    }
    return CivitModelsPage(items: items, nextCursor: nextCursor);
  }

  Future<CivitModel> getModel(int id) async {
    final uri = Uri.https(host, '/api/v1/models/$id');
    final response = await _client.get(uri, headers: _headers).timeout(const Duration(seconds: 30));
    if (response.statusCode != 200) {
      throw CivitApiException('HTTP ${response.statusCode}');
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const CivitApiException('unexpected response shape');
    }
    return CivitModel.fromJson(decoded);
  }

  Future<CivitModelVersion> getModelVersion(int id) async {
    final uri = Uri.https(host, '/api/v1/model-versions/$id');
    final response = await _client.get(uri, headers: _headers).timeout(const Duration(seconds: 30));
    if (response.statusCode != 200) {
      throw CivitApiException('HTTP ${response.statusCode}');
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const CivitApiException('unexpected response shape');
    }
    return CivitModelVersion.fromJson(decoded);
  }

  static String _sortParam(CivitSort sort) => switch (sort) {
    CivitSort.highestRated => 'Highest Rated',
    CivitSort.mostDownloaded => 'Most Downloaded',
    CivitSort.mostLiked => 'Most Liked',
    CivitSort.mostDiscussed => 'Most Discussed',
    CivitSort.newest => 'Newest',
    CivitSort.oldest => 'Oldest',
  };

  static String _periodParam(CivitPeriod period) => switch (period) {
    CivitPeriod.allTime => 'AllTime',
    CivitPeriod.year => 'Year',
    CivitPeriod.month => 'Month',
    CivitPeriod.week => 'Week',
    CivitPeriod.day => 'Day',
  };
}
