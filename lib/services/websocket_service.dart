import 'dart:async';
import 'dart:convert';
import 'package:aureascan_app/models/analysis_response.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketService {
  // Default to production API, can be overridden via .env file
  final String apiUrl = dotenv.env['API_BASE_URL'] ?? 'https://aureascan.ai';
  final Map<String, WebSocketChannel> _channels = {};
  final Map<String, StreamSubscription> _subscriptions = {};
  final Map<String, StreamController<AnalysisStatusResponse>> _controllers = {};

  /// Connect to WebSocket for a specific job ID
  Stream<AnalysisStatusResponse> connectToJob(String jobId) {
    if (_controllers.containsKey(jobId)) {
      return _controllers[jobId]!.stream;
    }

    final controller = StreamController<AnalysisStatusResponse>();
    _controllers[jobId] = controller;

    // Convert http:// to ws:// or https:// to wss://
    final wsUrl = apiUrl.replaceFirst('http://', 'ws://').replaceFirst('https://', 'wss://');
    // WebSocket endpoint: /ws/{job_id} or /api/v1/ws/{job_id}
    // Try both paths - adjust based on actual API documentation
    final uri = Uri.parse('$wsUrl/ws/$jobId');

    try {
      debugPrint('Connecting to WebSocket: $uri');
      final channel = WebSocketChannel.connect(uri);
      _channels[jobId] = channel;
      
      final subscription = channel.stream.listen(
        (data) {
          try {
            final jsonData = jsonDecode(data as String);
            final statusResponse = AnalysisStatusResponse.fromJson(jsonData);
            debugPrint('WebSocket message received for job $jobId: ${statusResponse.status}');
            controller.add(statusResponse);

            // Close connection if job is completed or failed
            if (statusResponse.isCompleted || statusResponse.isFailed) {
              debugPrint('Job $jobId completed/failed, disconnecting WebSocket');
              _disconnect(jobId);
            }
          } catch (e) {
            debugPrint('Error parsing WebSocket message: $e');
            controller.addError(e);
          }
        },
        onError: (error) {
          debugPrint('WebSocket error for job $jobId: $error');
          controller.addError(error);
        },
        onDone: () {
          debugPrint('WebSocket connection closed for job $jobId');
          _disconnect(jobId);
        },
      );
      _subscriptions[jobId] = subscription;
    } catch (e) {
      debugPrint('Error connecting to WebSocket: $e');
      controller.addError(e);
    }

    return controller.stream;
  }

  /// Disconnect from a specific job
  void _disconnect(String jobId) {
    _subscriptions[jobId]?.cancel();
    _subscriptions.remove(jobId);
    _channels[jobId]?.sink.close();
    _channels.remove(jobId);
    _controllers[jobId]?.close();
    _controllers.remove(jobId);
  }

  /// Disconnect all
  void disconnectAll() {
    for (final jobId in _controllers.keys.toList()) {
      _disconnect(jobId);
    }
  }

  /// Dispose
  void dispose() {
    disconnectAll();
  }
}

