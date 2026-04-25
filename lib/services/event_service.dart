import 'package:flutter/foundation.dart';
import 'package:frontend/models/event.dart';
import 'package:frontend/services/api_client.dart';

class EventService {
  final ApiClient _apiClient;

  EventService({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<List<Event>> getEvents() async {
    try {
      final responseData = await _apiClient.get('/events');
      if (responseData is List) {
        return responseData
            .whereType<Map<dynamic, dynamic>>()
            .map((item) => Event.fromJson(Map<String, dynamic>.from(item)))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching events: $e');
      throw Exception('Failed to load events');
    }
  }

  Future<Event> createEvent(EventCreate event) async {
    try {
      final data = {'name': event.name};
      final responseData = await _apiClient.post('/events', data: data);
      if (responseData is Map) {
        return Event.fromJson(Map<String, dynamic>.from(responseData));
      }
      throw Exception('Invalid response format');
    } catch (e) {
      debugPrint('Error creating event: $e');
      throw Exception('Failed to create event');
    }
  }

  Future<void> deleteEvent(String id) async {
    try {
      await _apiClient.delete('/events/$id');
    } catch (e) {
      debugPrint('Error deleting event: $e');
      throw Exception('Failed to delete event');
    }
  }
}
