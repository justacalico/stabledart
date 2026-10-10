import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/omdb_models.dart';

class OpenModelDbApiException implements Exception {
  final String message;
  const OpenModelDbApiException(this.message);
  @override
  String toString() => 'OpenModelDbApiException: $message';
}

class OpenModelDbApi {
  static const modelsUrl = 'https://openmodeldb.info/api/v1/models.json';

  final http.Client _client;

  OpenModelDbApi({http.Client? client}) : _client = client ?? http.Client();

  Future<List<OpenModelDbModel>> getModels() async {
    final response = await _client.get(
      Uri.parse(modelsUrl),
      headers: {'Accept': 'application/json'},
    ).timeout(const Duration(seconds: 30));
    if (response.statusCode != 200) {
      throw OpenModelDbApiException('HTTP ${response.statusCode}');
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const OpenModelDbApiException('unexpected response shape');
    }
    final result = <OpenModelDbModel>[];
    decoded.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        result.add(OpenModelDbModel.fromJson(key, value));
      }
    });
    return result;
  }
}
