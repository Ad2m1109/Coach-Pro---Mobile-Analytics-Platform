import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => 'ApiException: $message (Status: $statusCode)';
}

class ApiClient {
  final http.Client _httpClient;
  final String baseUrl;
  String? _token;

  String? get token => _token;

  ApiClient({http.Client? httpClient, required this.baseUrl}) : _httpClient = httpClient ?? http.Client();

  void setToken(String token) {
    _token = token;
  }

  void removeToken() {
    _token = null;
  }

  Map<String, String> _getHeaders({bool isAuth = false, String contentType = 'application/json'}) {
    final Map<String, String> headers = {
      'Content-Type': contentType + '; charset=UTF-8',
    };
    if (_token != null && !isAuth) { // Don't send token for auth endpoints
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  Future<Map<String, String>> getAuthHeaders() async {
    return _getHeaders();
  }

  Future<dynamic> get(String path) async {
    final uri = Uri.parse('$baseUrl$path');
    try {
      final response = await _httpClient.get(uri, headers: _getHeaders());
      return _handleResponse(response);
    } on http.ClientException catch (e) {
      throw ApiException('Network error: ${e.message}');
    } catch (e) {
      throw ApiException('An unexpected error occurred: $e');
    }
  }

  Future<dynamic> post(String path, {Map<String, dynamic>? data, bool isAuth = false, String contentType = 'application/json'}) async {
    final uri = Uri.parse('$baseUrl$path');
    try {
      final response = await _httpClient.post(
        uri,
        headers: _getHeaders(isAuth: isAuth, contentType: contentType),
        body: contentType == 'application/json' ? jsonEncode(data) : (data != null ? Uri(queryParameters: data.map((key, value) => MapEntry(key, value.toString()))).query : null),
      );
      return _handleResponse(response);
    } on http.ClientException catch (e) {
      throw ApiException('Network error: ${e.message}');
    } catch (e) {
      throw ApiException('An unexpected error occurred: $e');
    }
  }

  Future<dynamic> put(String path, {Map<String, dynamic>? data}) async {
    final uri = Uri.parse('$baseUrl$path');
    try {
      final response = await _httpClient.put(
        uri,
        headers: _getHeaders(),
        body: jsonEncode(data),
      );
      return _handleResponse(response);
    } on http.ClientException catch (e) {
      throw ApiException('Network error: ${e.message}');
    } catch (e) {
      throw ApiException('An unexpected error occurred: $e');
    }
  }

  Future<dynamic> delete(String path) async {
    final uri = Uri.parse('$baseUrl$path');
    try {
      final response = await _httpClient.delete(uri, headers: _getHeaders());
      return _handleResponse(response);
    } on http.ClientException catch (e) {
      throw ApiException('Network error: ${e.message}');
    } catch (e) {
      throw ApiException('An unexpected error occurred: $e');
    }
  }

  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      // For token endpoint, response is not always JSON
      if (response.body.isEmpty) return null; // Handle empty response
      return jsonDecode(response.body);
    } else {
      String errorMessage = 'Request failed with status: ${response.statusCode}';
      try {
        final errorBody = jsonDecode(response.body);
        if (errorBody != null && errorBody is Map && errorBody.containsKey('detail')) {
          errorMessage = errorBody['detail'];
        }
      } catch (e) {
        // Ignore JSON decode error if response body is not JSON
      }
      
      // If after trying to parse, the message is still the default and status is 401, provide a better default.
      if (errorMessage == 'Request failed with status: ${response.statusCode}' && response.statusCode == 401) {
          errorMessage = 'Unauthorized: Invalid credentials or token expired.';
      }

      throw ApiException(errorMessage, statusCode: response.statusCode);
    }
  }
}
