import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/civit_models.dart';

class CivArchiveApiException implements Exception {
  final String message;
  const CivArchiveApiException(this.message);
  @override
  String toString() => 'CivArchiveApiException: $message';
}

class CivArchiveApi {
  static const base = 'https://civarchive.com/api';

  final http.Client _client;

  CivArchiveApi({http.Client? client}) : _client = client ?? http.Client();

  Future<List<CivitModel>> getModels({String? query, int page = 1}) async {
    final params = <String, String>{'page': '$page'};
    if (query != null && query.isNotEmpty) params['q'] = query;
    final uri = Uri.parse('$base/models').replace(queryParameters: params);
    final response = await _client.get(
      uri,
      headers: {'Accept': 'application/json'},
    );
    if (response.statusCode != 200) {
      throw CivArchiveApiException('HTTP ${response.statusCode}');
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! List) {
      throw const CivArchiveApiException('unexpected response shape');
    }
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(CivitModel.fromJson)
        .toList();
  }
}
