import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:frontend/models/tracking_profile.dart';
import 'package:frontend/services/analysis_service.dart';

class TrackingProfileService {
  final String baseUrl;
  final AnalysisService analysisService;

  TrackingProfileService({required this.baseUrl, required this.analysisService});

  Future<TrackingProfile> createProfile(TrackingProfile profile) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/tracking-profiles'),
      headers: analysisService.fileHeaders()..addAll({'Content-Type': 'application/json'}),
      body: jsonEncode(profile.toJson()),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return TrackingProfile.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create tracking profile: ${response.body}');
    }
  }

  Future<List<TrackingProfile>> getMatchProfiles(String matchId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/matches/$matchId/tracking-profiles'),
      headers: analysisService.fileHeaders(),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => TrackingProfile.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load tracking profiles: ${response.body}');
    }
  }
}
