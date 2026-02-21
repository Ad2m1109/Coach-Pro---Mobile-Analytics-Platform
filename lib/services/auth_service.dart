import 'package:flutter/material.dart';
import 'package:frontend/services/api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/models/user.dart'; // Import User model
import 'dart:convert';
import 'package:frontend/models/staff.dart';

class AuthService with ChangeNotifier {
  final ApiClient _apiClient;
  final ApiClient? _analysisApiClient;
  String? _token;
  User? _currentUser;
  
  // Staff RBAC fields
  String? _userType;
  String? _staffId;
  String? _permissionLevel;
  String? _teamId;
  String? _appRole;
  List<String> _appPermissions = [];

  AuthService({required ApiClient apiClient, ApiClient? analysisApiClient}) 
      : _apiClient = apiClient,
        _analysisApiClient = analysisApiClient;

  ApiClient get apiClient => _apiClient;

  String? get token => _token;
  bool get isAuthenticated => _token != null;
  User? get currentUser => _currentUser;
  
  // Staff RBAC getters
  String? get userType => _userType;
  String? get staffId => _staffId;
  String? get permissionLevel => _permissionLevel;
  String? get teamId => _teamId;
  String? get appRole => _appRole;
  List<String> get appPermissions => List.unmodifiable(_appPermissions);
  
  bool get isOwner => _appRole == 'account_manager' || _userType == 'owner';
  bool get isStaff => _userType == 'staff';
  bool get canManageAccounts => _appRole == 'account_manager';
  bool get canManagePlayers => _appRole == 'account_manager' || hasPermission('edit');
  bool get canManageReunions => _appRole == 'account_manager' || hasPermission('edit');
  bool get canManageTeam => _appRole == 'account_manager';
  
  bool hasPermission(String permission) {
    if (_appPermissions.isNotEmpty) {
      if (_appPermissions.contains(permission)) return true;
      const aliasMap = {
        'edit': 'football.write',
        'view': 'football.read',
        'notes': 'notes.write',
      };
      final mapped = aliasMap[permission];
      return mapped != null && _appPermissions.contains(mapped);
    }
    if (isOwner) return true;
    if (_permissionLevel == null) return false;

    final legacyPermissions = {
      'full_access': ['edit', 'view', 'notes'],
      'view_only': ['view'],
      'notes_only': ['notes'],
    };

    return legacyPermissions[_permissionLevel]?.contains(permission) ?? false;
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('jwt_token');
    if (_token != null) {
      _parseJwtClaims(_token!);
      _apiClient.setToken(_token!);
      _analysisApiClient?.setToken(_token!);
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
      _parseJwtClaims(_token!);
      _apiClient.setToken(_token!); // Set token in ApiClient
      _analysisApiClient?.setToken(_token!); // Set token in Analysis ApiClient
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
      _parseJwtClaims(_token!);
      _apiClient.setToken(_token!); // Set token in ApiClient
      _analysisApiClient?.setToken(_token!); // Set token in Analysis ApiClient
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
    _userType = null;
    _staffId = null;
    _permissionLevel = null;
    _teamId = null;
    _appRole = null;
    _appPermissions = [];
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token'); // Remove token
    _apiClient.removeToken(); // Remove token from ApiClient
    _analysisApiClient?.removeToken(); // Remove token from Analysis ApiClient
    notifyListeners();
  }
  
  void _parseJwtClaims(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return;
      
      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final Map<String, dynamic> claims = json.decode(decoded);
      
      _userType = claims['user_type'] as String?;
      _staffId = claims['staff_id'] as String?;
      _permissionLevel = claims['permission_level'] as String?;
      _teamId = claims['team_id'] as String?;
      _appRole = claims['app_role'] as String?;
      final rawPermissions = claims['app_permissions'];
      if (rawPermissions is List) {
        _appPermissions = rawPermissions.map((p) => p.toString()).toList();
      } else {
        _appPermissions = [];
      }
    } catch (e) {
      print('Error parsing JWT claims: $e');
    }
  }
}
