import 'dart:async';

import 'package:flutter/material.dart';
import 'package:frontend/services/api_client.dart';
import 'package:provider/provider.dart';

class AnalysisProgressWidget extends StatefulWidget {
  final String jobId;
  final VoidCallback onComplete;

  const AnalysisProgressWidget({
    super.key,
    required this.jobId,
    required this.onComplete,
  });

  @override
  State<AnalysisProgressWidget> createState() => _AnalysisProgressWidgetState();
}

class _AnalysisProgressWidgetState extends State<AnalysisProgressWidget> {
  Timer? _timer;
  double _progress = 0.0;
  String _status = 'PENDING';
  String _message = 'Waiting to start';
  bool _isCancelled = false;

  @override
  void initState() {
    super.initState();
    _pollStatus();
    _timer = Timer.periodic(const Duration(seconds: 2), (_) => _pollStatus());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _pollStatus() async {
    if (_isCancelled) return;
    final apiClient = Provider.of<ApiClient>(context, listen: false);

    try {
      final response = await apiClient.get('/analysis/${widget.jobId}/status');
      final status = (response['status'] ?? 'PENDING').toString().toUpperCase();
      final progress = ((response['progress'] ?? 0) as num).toDouble();
      final message = (response['message'] ?? '').toString();

      if (!mounted) return;
      setState(() {
        _status = status;
        _progress = progress.clamp(0.0, 1.0);
        _message = message.isEmpty ? status : message;
      });

      if (status == 'COMPLETED') {
        _timer?.cancel();
        widget.onComplete();
      } else if (status == 'FAILED') {
        _timer?.cancel();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _message = 'Status check error: $e';
      });
    }
  }

  void _cancelPolling() {
    _timer?.cancel();
    setState(() {
      _isCancelled = true;
      _message = 'Progress monitoring stopped';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LinearProgressIndicator(value: _progress),
            const SizedBox(height: 8),
            Text('Status: $_status'),
            const SizedBox(height: 4),
            Text('Progress: ${(_progress * 100).toStringAsFixed(0)}%'),
            const SizedBox(height: 4),
            Text(_message),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _isCancelled ? null : _cancelPolling,
                child: const Text('Stop Monitoring'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
