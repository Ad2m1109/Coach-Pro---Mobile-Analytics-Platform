import 'package:frontend/models/match.dart';
import 'package:frontend/models/match_details.dart';
import 'package:frontend/models/team.dart';
import 'package:frontend/services/api_client.dart';
import 'package:frontend/services/team_service.dart';

class MatchService {
  final ApiClient _apiClient;
  final TeamService _teamService;

  MatchService({required ApiClient apiClient, required TeamService teamService})
      : _apiClient = apiClient,
        _teamService = teamService;

  Future<List<Match>> getMatches({String? status, String? eventId}) async {
    try {
      String queryString = '/matches';
      Map<String, String> queryParameters = {};
      if (status != null) {
        queryParameters['status'] = status;
      }
      if (eventId != null) {
        queryParameters['event_id'] = eventId;
      }
      if (queryParameters.isNotEmpty) {
        queryString += '?' + Uri(queryParameters: queryParameters).query;
      }
      final responseData = await _apiClient.get(queryString);
      final List<Match> matches = (responseData as List)
          .map((item) => Match.fromJson(item as Map<String, dynamic>))
          .toList();
      return matches;
    } catch (e) {
      print('Error fetching matches: $e');
      throw Exception('Failed to load matches');
    }
  }

  Future<Match> createMatch({
    required String opponentName,
    required DateTime date,
    required bool isHome,
    required String eventId,
  }) async {
    try {
      // 1. Get user's teams and pick one (e.g., the first)
      final userTeams = await _teamService.getTeams();
      if (userTeams.isEmpty) {
        throw Exception("User has no teams. Please create a team first.");
      }
      final userTeamId = userTeams.first.id;

      // 2. Get or create opponent team to get its ID.
      Team opponentTeam;
      try {
        opponentTeam = await _teamService.getTeamByName(opponentName);
      } catch (e) {
        // If not found, create it
        opponentTeam = await _teamService.createTeam(Team(id: '', name: opponentName));
      }
      final opponentTeamId = opponentTeam.id;

      // 3. Prepare match data with correct IDs
      final matchData = {
        'home_team_id': isHome ? userTeamId : opponentTeamId,
        'away_team_id': isHome ? opponentTeamId : userTeamId,
        'date_time': date.toIso8601String(),
        'status': 'upcoming',
        'event_id': eventId,
        'home_score': 0,
        'away_score': 0,
      };
      final responseData = await _apiClient.post('/matches', data: matchData);
      return Match.fromJson(responseData as Map<String, dynamic>);
    } catch (e) {
      print('Error creating match: $e');
      throw Exception('Failed to create match');
    }
  }

  Future<MatchDetails> getMatchDetails(String matchId) async {
    try {
      final responseData = await _apiClient.get('/matches/$matchId/details');
      return MatchDetails.fromJson(responseData as Map<String, dynamic>);
    } catch (e) {
      print('Error fetching match details: $e');
      throw Exception('Failed to load match details');
    }
  }
}
