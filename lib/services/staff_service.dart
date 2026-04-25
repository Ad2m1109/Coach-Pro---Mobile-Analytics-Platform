import '../models/staff.dart';
import 'api_client.dart';

class StaffService {
  final ApiClient _apiClient;

  StaffService({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<List<Staff>> getAllStaff() async {
    try {
      final responseData = await _apiClient.get('/staff');
      if (responseData is List) {
        return responseData
            .whereType<Map<dynamic, dynamic>>()
            .map((item) => Staff.fromJson(Map<String, dynamic>.from(item)))
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load staff: $e');
    }
  }

  Future<Staff> getStaff(String staffId) async {
    try {
      final responseData = await _apiClient.get('/staff/$staffId');
      if (responseData is Map) {
        return Staff.fromJson(Map<String, dynamic>.from(responseData));
      }
      throw Exception('Invalid response format');
    } catch (e) {
      throw Exception('Failed to load staff: $e');
    }
  }

  Future<Staff> createStaffWithAccount(StaffCreateRequest request) async {
    try {
      final responseData = await _apiClient.post(
        '/staff/create_with_account',
        data: request.toJson(),
      );
      if (responseData is Map) {
        return Staff.fromJson(Map<String, dynamic>.from(responseData));
      }
      throw Exception('Invalid response format');
    } catch (e) {
      throw Exception('Failed to create staff: $e');
    }
  }

  Future<Staff> updateStaff(String staffId, Staff staffData) async {
    try {
      final responseData = await _apiClient.put(
        '/staff/$staffId',
        data: staffData.toJson(),
      );
      if (responseData is Map) {
        return Staff.fromJson(Map<String, dynamic>.from(responseData));
      }
      throw Exception('Invalid response format');
    } catch (e) {
      throw Exception('Failed to update staff: $e');
    }
  }

  Future<void> deleteStaff(String staffId) async {
    try {
      await _apiClient.delete('/staff/$staffId');
    } catch (e) {
      throw Exception('Failed to delete staff: $e');
    }
  }
}
