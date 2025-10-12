import 'package:frontend/models/player.dart';
import 'package:frontend/services/api_client.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PlayerService {
  final ApiClient _apiClient;

  PlayerService({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<List<Player>> getPlayers() async {
    try {
      final responseData = await _apiClient.get('/players');
      final List<Player> players = (responseData as List)
          .map((item) => Player.fromJson(item as Map<String, dynamic>))
          .toList();
      return players;
    } catch (e) {
      print('Error fetching players: $e');
      throw Exception('Failed to load players');
    }
  }

  Future<Player> createPlayer(Player player) async {
    try {
      // The backend PlayerCreate model does not have an id, so we don't send it.
      final playerData = {
        'team_id': player.teamId,
        'name': player.name,
        'position': player.position,
        'jersey_number': player.jerseyNumber,
        'birth_date': player.birthDate?.toIso8601String(),
        'dominant_foot': player.dominantFoot,
        'height_cm': player.heightCm,
        'weight_kg': player.weightKg,
        'image_url': player.imageUrl,
      };
      final responseData = await _apiClient.post('/players', data: playerData);
      return Player.fromJson(responseData as Map<String, dynamic>);
    } catch (e) {
      print('Error creating player: $e');
      throw Exception('Failed to create player');
    }
  }

  Future<Player> updatePlayer(Player player) async {
    try {
      final responseData = await _apiClient.put('/players/${player.id}', data: player.toJson());
      return Player.fromJson(responseData as Map<String, dynamic>);
    } catch (e) {
      print('Error updating player: $e');
      throw Exception('Failed to update player');
    }
  }

  Future<Player> uploadPlayerImage(String playerId, XFile imageFile) async {
    final uri = Uri.parse('${_apiClient.baseUrl}/players/$playerId/upload_image');
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
        return Player.fromJson(jsonDecode(responseBody));
      } else {
        final errorBody = await response.stream.bytesToString();
        throw ApiException('Failed to upload image: ${response.statusCode} - $errorBody', statusCode: response.statusCode);
      }
    } catch (e) {
      print('Error uploading player image: $e');
      throw Exception('Failed to upload player image');
    }
  }
}
