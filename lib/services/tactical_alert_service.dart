import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:frontend/models/tactical_alert.dart';
import 'package:frontend/services/api_client.dart';

class TacticalAlertService extends ChangeNotifier {
  final ApiClient _apiClient;
  WebSocket? _socket;
  final _alertController = StreamController<TacticalAlert>.broadcast();
  List<TacticalAlert> _history = [];
  Map<String, dynamic> _decisionMetrics = const {};
  bool _isConnected = false;

  TacticalAlertService(this._apiClient);

  Stream<TacticalAlert> get alertStream => _alertController.stream;
  List<TacticalAlert> get history => _history;
  Map<String, dynamic> get decisionMetrics => _decisionMetrics;
  bool get isConnected => _isConnected;

  /// Fetch previous alerts for the match and clear local history
  Future<void> initForMatch(String matchId) async {
    _history.clear();
    await _refreshDecisionData(matchId);
    
    // Connect to WebSocket for real-time updates
    _connectWebSocket(matchId);
  }

  void _connectWebSocket(String matchId) async {
    if (_socket != null) {
      _socket!.close();
    }

    // Derive WS URL from ApiClient baseUrl
    // baseUrl: http://localhost:8000/api -> ws://localhost:8000/ws/alerts/{match_id}
    final wsBase = _apiClient.baseUrl.replaceFirst('http', 'ws').replaceFirst('/api', '');
    final wsUrl = '$wsBase/ws/alerts/$matchId';

    debugPrint('Connecting to Tactical Alerts WebSocket: $wsUrl');

    try {
      _socket = await WebSocket.connect(wsUrl);
      _isConnected = true;
      notifyListeners();

      _socket!.listen(
        (data) {
          try {
            final Map<String, dynamic> json = jsonDecode(data);
            final alert = TacticalAlert.fromJson(json);
            
            // Deduplicate/Update history
            final index = _history.indexWhere((a) => a.id == alert.id);
            if (index != -1) {
              _history[index] = alert;
            } else {
              _history.add(alert);
            }
            
            _alertController.add(alert);
            notifyListeners();
          } catch (e) {
            debugPrint('Error parsing WebSocket alert: $e');
          }
        },
        onDone: () {
          debugPrint('Tactical Alerts WebSocket closed');
          _isConnected = false;
          notifyListeners();
          // Optional: Reconnect logic
        },
        onError: (error) {
          debugPrint('Tactical Alerts WebSocket error: $error');
          _isConnected = false;
          notifyListeners();
        },
      );
    } catch (e) {
      debugPrint('Failed to connect to Tactical Alerts WebSocket: $e');
      _isConnected = false;
      notifyListeners();
    }
  }

  /// Submit feedback for an alert (accepted/dismissed)
  Future<void> submitFeedback(String matchId, String alertId, String feedback) async {
    try {
      final normalizedFeedback = feedback.toLowerCase();
      final action = normalizedFeedback == 'accepted' ? 'ACCEPT' : 'DISMISS';
      final alert = _history.cast<TacticalAlert?>().firstWhere(
            (a) => a?.id == alertId || a?.decisionId == alertId,
            orElse: () => null,
          );

      await _apiClient.post(
        '/decision/feedback',
        data: {
          'decision_id': alert?.decisionId ?? alertId,
          'action': action,
          'match_time': alert?.matchTime,
          'match_id': matchId,
        },
      );

      // Immediate optimistic state update.
      if (alert != null) {
        final index = _history.indexWhere((a) => a.id == alert.id);
        if (index != -1) {
          final current = _history[index];
          _history[index] = TacticalAlert(
            id: current.id,
            decisionId: current.decisionId,
            matchId: current.matchId,
            timestamp: current.timestamp,
            matchTime: current.matchTime,
            severityScore: current.severityScore,
            severityLabel: current.severityLabel,
            category: current.category,
            decisionType: current.decisionType,
            status: current.status,
            action: current.action,
            reviewCountdown: current.reviewCountdown,
            categoryTriggerCount: current.categoryTriggerCount,
            triggerMetric: current.triggerMetric,
            recommendedAction: current.recommendedAction,
            feedback: normalizedFeedback,
            decisionEffective: current.decisionEffective,
            decisionFailed: current.decisionFailed,
          );
          notifyListeners();
        }
      }

      await _refreshDecisionData(matchId);
      Future<void>.delayed(const Duration(seconds: 8), () => _refreshDecisionData(matchId));
    } catch (e) {
      debugPrint('Error submitting feedback: $e');
      rethrow;
    }
  }

  Future<void> _refreshDecisionData(String matchId) async {
    try {
      final List<dynamic> data = await _apiClient.get('/matches/$matchId/alerts');
      _history = data.map((json) => TacticalAlert.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error fetching alert history: $e');
    }

    try {
      final dynamic metrics = await _apiClient.get('/decision/metrics', queryParameters: {'match_id': matchId});
      if (metrics is Map<String, dynamic>) {
        _decisionMetrics = metrics;
      }
    } catch (e) {
      debugPrint('Error fetching decision metrics: $e');
    }

    notifyListeners();
  }

  @override
  void dispose() {
    _socket?.close();
    _alertController.close();
    super.dispose();
  }
}
