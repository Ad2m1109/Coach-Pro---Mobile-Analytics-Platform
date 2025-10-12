import 'package:frontend/models/formation.dart';
import 'package:frontend/services/api_client.dart';

class FormationService {
  final ApiClient _apiClient;

  FormationService({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<List<Formation>> getFormations() async {
    try {
      final responseData = await _apiClient.get('/formations');
      final List<Formation> formations = (responseData as List)
          .map((item) => Formation.fromJson(item as Map<String, dynamic>))
          .toList();
      return formations;
    } catch (e) {
      print('Error fetching formations: $e');
      throw Exception('Failed to load formations');
    }
  }
}
