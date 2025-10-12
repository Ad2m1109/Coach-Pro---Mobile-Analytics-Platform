import 'package:frontend/models/team.dart';
import 'package:frontend/services/api_client.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class TeamService {
  final ApiClient _apiClient;

  TeamService({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<List<Team>> getTeams() async {
    try {
      final responseData = await _apiClient.get('/teams');
      final List<Team> teams = (responseData as List)
          .map((item) => Team.fromJson(item as Map<String, dynamic>))
          .toList();
      return teams;
    } catch (e) {
      print('Error fetching teams: $e');
      throw Exception('Failed to load teams');
    }
  }

  Future<Team> getTeam(String id) async {
    try {
      final responseData = await _apiClient.get('/teams/$id');
      return Team.fromJson(responseData as Map<String, dynamic>);
    } catch (e) {
      print('Error fetching team: $e');
      throw Exception('Failed to load team');
    }
  }

  Future<Team> getTeamByName(String name) async {
    try {
      final responseData = await _apiClient.get('/teams/by_name/$name');
      return Team.fromJson(responseData as Map<String, dynamic>);
    } catch (e) {
      print('Error fetching team by name: $e');
      throw Exception('Failed to load team by name');
    }
  }

  Future<Team> createTeam(Team team) async {
    try {
      // The backend will derive the user_id from the authenticated user
      final teamData = {
        'name': team.name,
        'primary_color': team.primaryColor,
        'secondary_color': team.secondaryColor,
        'logo_url': team.logoUrl,
      };
      final responseData = await _apiClient.post('/teams', data: teamData);
      return Team.fromJson(responseData as Map<String, dynamic>);
    } catch (e) {
      print('Error creating team: $e');
      throw Exception('Failed to create team');
    }
  }

  Future<Team> updateTeam(String teamId, Team teamData) async {
    try {
      final responseData = await _apiClient.put('/teams/$teamId', data: teamData.toJson());
      return Team.fromJson(responseData as Map<String, dynamic>);
    } catch (e) {
      print('Error updating team: $e');
      throw Exception('Failed to update team');
    }
  }

  Future<Team> uploadTeamLogo(String teamId, XFile imageFile) async {
    final uri = Uri.parse('${_apiClient.baseUrl}/teams/$teamId/upload_logo');
    final request = http.MultipartRequest('POST', uri);

    // Add the file
    request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    // Add headers, including the auth token
    if (_apiClient.token != null) {
      request.headers['Authorization'] = 'Bearer ${_apiClient.token}';
    }

    try {
      final response = await request.send();

      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        return Team.fromJson(jsonDecode(responseBody));
      } else {
        final errorBody = await response.stream.bytesToString();
        throw ApiException('Failed to upload logo: ${response.statusCode} - $errorBody', statusCode: response.statusCode);
      }
    } catch (e) {
      print('Error uploading team logo: $e');
      throw Exception('Failed to upload team logo');
    }
  }
}
