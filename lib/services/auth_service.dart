import 'package:flutter/material.dart';
import 'package:frontend/services/api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/models/user.dart'; // Import User model

class AuthService with ChangeNotifier {
  final ApiClient _apiClient;
  String? _token;
  User? _currentUser;

  AuthService({required ApiClient apiClient}) : _apiClient = apiClient;

  String? get token => _token;
  bool get isAuthenticated => _token != null;
  User? get currentUser => _currentUser;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('jwt_token');
    if (_token != null) {
      _apiClient.setToken(_token!);
      await fetchCurrentUser(); // This will handle all notifications
    }
    // If token is null, initial state is correct, no notification needed.
  }

  Future<void> login(String email, String password) async {
    try {
      final response = await _apiClient.post(
        '/token',
        data: {
          'username': email,
          'password': password,
        },
        isAuth: true,
        contentType: 'application/x-www-form-urlencoded',
      );
      _token = response['access_token'];
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('jwt_token', _token!); // Store token
      _apiClient.setToken(_token!); // Set token in ApiClient
      await fetchCurrentUser(); // Fetch user details after login
    } catch (e) {
      _token = null;
      _currentUser = null;
      rethrow;
    }
  }

  Future<void> register(String email, String password, String? fullName) async {
    try {
      final response = await _apiClient.post(
        '/register',
        data: {
          'email': email,
          'password': password,
          'full_name': fullName,
        },
        isAuth: true,
      );
      _token = response['access_token'];
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('jwt_token', _token!); // Store token
      _apiClient.setToken(_token!); // Set token in ApiClient
      await fetchCurrentUser(); // Fetch user details after registration
    } catch (e) {
      _token = null;
      _currentUser = null;
      rethrow;
    }
  }

  Future<void> fetchCurrentUser() async {
    if (_token == null) return; // Guard clause

    try {
      final userData = await _apiClient.get('/users/me');
      _currentUser = User.fromJson(userData);
      notifyListeners(); // Success: notify listeners that user is loaded
    } catch (e) {
      print('Error fetching current user with token. Logging out. Error: $e');
      await logout(); // Failure: logout will clear everything and notify listeners
    }
  }

  Future<void> logout() async {
    _token = null;
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token'); // Remove token
    _apiClient.removeToken(); // Remove token from ApiClient
    notifyListeners();
  }
}
