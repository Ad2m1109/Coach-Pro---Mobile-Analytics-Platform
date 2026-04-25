import 'package:flutter/foundation.dart';
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
      if (responseData is List) {
        return responseData
            .whereType<Map<dynamic, dynamic>>()
            .map((item) => Player.fromJson(Map<String, dynamic>.from(item)))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching players: $e');
      throw Exception('Failed to load players');
    }
  }

  Future<Player> createPlayer(Player player) async {
    try {
      // The backend PlayerCreate model does not have an id, so we don't send it.
      final playerData = player.toJson();
      playerData.remove('id');

      final responseData = await _apiClient.post('/players', data: playerData);
      if (responseData is Map) {
        return Player.fromJson(Map<String, dynamic>.from(responseData));
      }
      throw Exception('Invalid response format');
    } catch (e) {
      debugPrint('Error creating player: $e');
      throw Exception('Failed to create player');
    }
  }

  Future<Player> updatePlayer(Player player) async {
    try {
      final responseData = await _apiClient.put(
        '/players/${player.id}',
        data: player.toJson(),
      );
      if (responseData is Map) {
        return Player.fromJson(Map<String, dynamic>.from(responseData));
      }
      throw Exception('Invalid response format');
    } catch (e) {
      debugPrint('Error updating player: $e');
      throw Exception('Failed to update player');
    }
  }

  Future<Player> uploadPlayerImage(String playerId, XFile imageFile) async {
    final uri = Uri.parse(
      '${_apiClient.baseUrl}/players/$playerId/upload_image',
    );
    final request = http.MultipartRequest('POST', uri);

    // Add the file
    request.files.add(
      await http.MultipartFile.fromPath('file', imageFile.path),
    );

    // Add headers, including the auth token
    if (_apiClient.token != null) {
      request.headers['Authorization'] = 'Bearer ${_apiClient.token}';
    }

    try {
      final response = await request.send();

      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        return Player.fromJson(
          Map<String, dynamic>.from(jsonDecode(responseBody)),
        );
      } else {
        final errorBody = await response.stream.bytesToString();
        throw ApiException(
          'Failed to upload image: ${response.statusCode} - $errorBody',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      debugPrint('Error uploading player image: $e');
      throw Exception('Failed to upload player image');
    }
  }
}
