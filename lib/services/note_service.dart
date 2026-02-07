import 'package:frontend/models/match_note.dart';
import 'package:frontend/services/api_client.dart';

class NoteService {
  final ApiClient apiClient;

  NoteService({required this.apiClient});

  Future<MatchNote> createNote(MatchNote note) async {
    final response = await apiClient.post(
      '/matches/${note.matchId}/notes',
      data: note.toJson(),
    );
    return MatchNote.fromJson(response);
  }

  Future<List<MatchNote>> getMatchNotes(String matchId) async {
    final response = await apiClient.get('/matches/$matchId/notes');
    if (response is List) {
      return response.map((json) => MatchNote.fromJson(json)).toList();
    }
    return [];
  }

  Future<void> deleteNote(String noteId) async {
    await apiClient.delete('/notes/$noteId');
  }
}
