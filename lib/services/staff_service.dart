import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/staff.dart';
import 'api_client.dart';

class StaffService {
  final ApiClient _apiClient;

  StaffService({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<List<Staff>> getAllStaff() async {
    try {
      final responseData = await _apiClient.get('/staff');
      final List<Staff> staff = (responseData as List)
          .map((item) => Staff.fromJson(item as Map<String, dynamic>))
          .toList();
      return staff;
    } catch (e) {
      throw Exception('Failed to load staff: $e');
    }
  }

  Future<Staff> getStaff(String staffId) async {
    try {
      final responseData = await _apiClient.get('/staff/$staffId');
      return Staff.fromJson(responseData as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to load staff: $e');
    }
  }

  Future<Staff> createStaffWithAccount(
    StaffCreateRequest request,
  ) async {
    try {
      final responseData = await _apiClient.post(
        '/staff/create_with_account',
        data: request.toJson(),
      );
      return Staff.fromJson(responseData as Map<String, dynamic>);
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
      return Staff.fromJson(responseData as Map<String, dynamic>);
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
