import 'package:flutter/foundation.dart';
import 'package:frontend/models/reunion.dart';
import 'package:frontend/services/api_client.dart';

class ReunionService {
  final ApiClient _apiClient;

  ReunionService({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<List<Reunion>> getReunions() async {
    try {
      final responseData = await _apiClient.get('/reunions');
      if (responseData is List) {
        return responseData
            .whereType<Map<dynamic, dynamic>>()
            .map((item) => Reunion.fromJson(Map<String, dynamic>.from(item)))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching reunions: $e');
      throw Exception('Failed to load reunions');
    }
  }

  Future<Reunion> createReunion(Reunion reunion) async {
    try {
      final data = {
        'title': reunion.title,
        'date': reunion.date.toIso8601String(),
        'location': reunion.location,
        'icon_name': reunion.iconName,
      };
      final responseData = await _apiClient.post('/reunions', data: data);
      if (responseData is Map) {
        return Reunion.fromJson(Map<String, dynamic>.from(responseData));
      }
      throw Exception('Invalid response format');
    } catch (e) {
      debugPrint('Error creating reunion: $e');
      throw Exception('Failed to create reunion');
    }
  }

  Future<void> deleteReunion(String id) async {
    try {
      await _apiClient.delete('/reunions/$id');
    } catch (e) {
      debugPrint('Error deleting reunion: $e');
      throw Exception('Failed to delete reunion');
    }
  }
}
