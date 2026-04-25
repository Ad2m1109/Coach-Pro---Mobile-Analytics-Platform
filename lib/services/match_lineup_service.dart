import 'package:flutter/foundation.dart';
import 'package:frontend/models/match_lineup.dart';
import 'package:frontend/services/api_client.dart';

class MatchLineupService {
  final ApiClient _apiClient;

  MatchLineupService({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<List<MatchLineup>> getLineups({String? matchId}) async {
    try {
      String queryString = '/match_lineups';
      if (matchId != null) {
        queryString += '?match_id=$matchId';
      }
      final responseData = await _apiClient.get(queryString);
      if (responseData is List) {
        return responseData
            .whereType<Map<dynamic, dynamic>>()
            .map(
              (item) => MatchLineup.fromJson(Map<String, dynamic>.from(item)),
            )
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching lineups: $e');
      throw Exception('Failed to load lineups');
    }
  }

  Future<MatchLineup> createLineup(MatchLineup lineup) async {
    try {
      final responseData = await _apiClient.post(
        '/match_lineups',
        data: lineup.toJson(),
      );
      if (responseData is Map) {
        return MatchLineup.fromJson(Map<String, dynamic>.from(responseData));
      }
      throw Exception('Invalid response format');
    } catch (e) {
      debugPrint('Error creating lineup: $e');
      throw Exception('Failed to create lineup');
    }
  }

  Future<void> deleteLineup(String id) async {
    try {
      await _apiClient.delete('/match_lineups/$id');
    } catch (e) {
      debugPrint('Error deleting lineup: $e');
      throw Exception('Failed to delete lineup');
    }
  }
}
