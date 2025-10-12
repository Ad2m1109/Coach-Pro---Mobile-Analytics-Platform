import 'package:frontend/models/player_match_statistics.dart';
import 'package:frontend/services/api_client.dart';

class PlayerMatchStatisticsService {
  final ApiClient _apiClient;

  PlayerMatchStatisticsService({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<List<PlayerMatchStatistics>> getPlayerMatchStatistics({String? matchId}) async {
    try {
      String queryString = '/player_match_statistics';
      if (matchId != null) {
        queryString += '?match_id=$matchId';
      }
      final responseData = await _apiClient.get(queryString);
      final List<PlayerMatchStatistics> stats = (responseData as List)
          .map((item) => PlayerMatchStatistics.fromJson(item as Map<String, dynamic>))
          .toList();
      return stats;
    } catch (e) {
      print('Error fetching player match statistics: $e');
      throw Exception('Failed to load player match statistics');
    }
  }

  Future<List<PlayerMatchStatistics>> getPlayerMatchStatisticsByPlayerId(String playerId) async {
    try {
      final responseData = await _apiClient.get('/player_match_statistics/player/$playerId');
      final List<PlayerMatchStatistics> stats = (responseData as List)
          .map((item) => PlayerMatchStatistics.fromJson(item as Map<String, dynamic>))
          .toList();
      return stats;
    } catch (e) {
      print('Error fetching player match statistics for player $playerId: $e');
      throw Exception('Failed to load player match statistics for player $playerId');
    }
  }
}
