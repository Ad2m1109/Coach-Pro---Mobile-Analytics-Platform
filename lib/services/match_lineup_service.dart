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
      final List<MatchLineup> lineups = (responseData as List)
          .map((item) => MatchLineup.fromJson(item as Map<String, dynamic>))
          .toList();
      return lineups;
    } catch (e) {
      print('Error fetching lineups: $e');
      throw Exception('Failed to load lineups');
    }
  }

  Future<MatchLineup> createLineup(MatchLineup lineup) async {
    try {
      final responseData = await _apiClient.post('/match_lineups', data: lineup.toJson());
      return MatchLineup.fromJson(responseData as Map<String, dynamic>);
    } catch (e) {
      print('Error creating lineup: $e');
      throw Exception('Failed to create lineup');
    }
  }

  Future<void> deleteLineup(String id) async {
    try {
      await _apiClient.delete('/match_lineups/$id');
    } catch (e) {
      print('Error deleting lineup: $e');
      throw Exception('Failed to delete lineup');
    }
  }
}
