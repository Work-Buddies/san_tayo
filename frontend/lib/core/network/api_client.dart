import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/api_response.dart';

String? auth_token;

/// Centralized API request function — call this for all frontend-backend connections.
Future<ApiResponse> api_request(
  String method,
  String endpoint, {
  Map<String, dynamic>? body,
  Map<String, String>? query,
}) async {
  try {
    final uri = _build_uri(endpoint, query);
    final headers = {
      'Content-Type': 'application/json',
      'Accept':       'application/json',
      'X-Client-Key': ApiConfig.client_key,
    };

    if (auth_token != null && auth_token!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $auth_token';
    }

    http.Response response;

    switch (method.toUpperCase()) {
      case 'GET':
        response = await http
            .get(uri, headers: headers)
            .timeout(Duration(seconds: ApiConfig.timeout_seconds));
        break;
      case 'POST':
        response = await http
            .post(uri, headers: headers, body: jsonEncode(body ?? {}))
            .timeout(Duration(seconds: ApiConfig.timeout_seconds));
        break;
      case 'PUT':
        response = await http
            .put(uri, headers: headers, body: jsonEncode(body ?? {}))
            .timeout(Duration(seconds: ApiConfig.timeout_seconds));
        break;
      case 'PATCH':
        response = await http
            .patch(uri, headers: headers, body: jsonEncode(body ?? {}))
            .timeout(Duration(seconds: ApiConfig.timeout_seconds));
        break;
      case 'DELETE':
        response = await http
            .delete(uri, headers: headers, body: body != null ? jsonEncode(body) : null)
            .timeout(Duration(seconds: ApiConfig.timeout_seconds));
        break;
      default:
        return ApiResponse.error('Unsupported HTTP method: $method');
    }

    final decoded = jsonDecode(response.body);

    if (decoded is Map<String, dynamic>) {
      return ApiResponse.from_json(decoded);
    }

    return ApiResponse.error('Invalid response format from server.');
  } catch (e) {
    return ApiResponse.error('Network error: $e');
  }
}

Uri _build_uri(String endpoint, Map<String, String>? query) {
  final base = ApiConfig.base_url.endsWith('/')
      ? ApiConfig.base_url.substring(0, ApiConfig.base_url.length - 1)
      : ApiConfig.base_url;

  final path = endpoint.startsWith('/') ? endpoint : '/$endpoint';

  return Uri.parse('$base$path').replace(queryParameters: query);
}
