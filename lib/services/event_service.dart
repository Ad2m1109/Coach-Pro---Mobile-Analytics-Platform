import 'package:frontend/models/event.dart';
import 'package:frontend/services/api_client.dart';

class EventService {
  final ApiClient _apiClient;

  EventService({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<List<Event>> getEvents() async {
    try {
      final responseData = await _apiClient.get('/events');
      final List<Event> events = (responseData as List)
          .map((item) => Event.fromJson(item as Map<String, dynamic>))
          .toList();
      return events;
    } catch (e) {
      print('Error fetching events: $e');
      throw Exception('Failed to load events');
    }
  }

  Future<Event> createEvent(EventCreate event) async {
    try {
      final data = {
        'name': event.name,
      };
      final responseData = await _apiClient.post('/events', data: data);
      return Event.fromJson(responseData as Map<String, dynamic>);
    } catch (e) {
      print('Error creating event: $e');
      throw Exception('Failed to create event');
    }
  }

  Future<void> deleteEvent(String id) async {
    try {
      await _apiClient.delete('/events/$id');
    } catch (e) {
      print('Error deleting event: $e');
      throw Exception('Failed to delete event');
    }
  }
}