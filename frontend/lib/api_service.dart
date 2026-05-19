import 'dart:convert';
import 'dart:io';

import 'models.dart';

class ApiService {
  static Future<List<Call>> fetchRecentCalls(
    String baseUrl, {
    int limit = 10,
  }) async {
    final base = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;

    final uri = Uri.parse('$base/api/v1/calls/recent')
        .replace(queryParameters: {'limit': limit.toString()});

    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 10);

    try {
      final request = await client.getUrl(uri);
      request.headers.set('Accept', 'application/json');
      final response = await request.close().timeout(
        const Duration(seconds: 10),
        onTimeout: () =>
            throw Exception('Timeout: Server antwortet nicht (10 s).'),
      );

      final body = await response.transform(utf8.decoder).join();

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(body);
        return jsonList
            .whereType<Map<String, dynamic>>()
            .map(Call.fromJson)
            .toList();
      } else {
        throw Exception('Serverfehler: HTTP ${response.statusCode}\n$body');
      }
    } on SocketException catch (e) {
      throw Exception('Verbindungsfehler: ${e.message}');
    } on FormatException {
      throw Exception('Ungültiges JSON vom Server.');
    } finally {
      client.close();
    }
  }
}
