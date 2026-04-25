import 'package:flutter/foundation.dart';
import 'package:frontend/models/formation.dart';
import 'package:frontend/services/api_client.dart';

class FormationService {
  final ApiClient _apiClient;

  FormationService({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<List<Formation>> getFormations() async {
    try {
      final responseData = await _apiClient.get('/formations');
      if (responseData is List) {
        return responseData
            .whereType<Map<dynamic, dynamic>>()
            .map((item) => Formation.fromJson(Map<String, dynamic>.from(item)))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching formations: $e');
      throw Exception('Failed to load formations');
    }
  }
}
