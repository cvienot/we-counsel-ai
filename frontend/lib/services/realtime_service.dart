import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/message.dart';
import '../services/auth_service.dart';
import '../utils/constants.dart';

class RealTimeEvent {
  final String type;
  final Map<String, dynamic> data;
  final DateTime timestamp;

  RealTimeEvent({
    required this.type,
    required this.data,
    required this.timestamp,
  });

  factory RealTimeEvent.fromJson(Map<String, dynamic> json) {
    return RealTimeEvent(
      type: json['type'] ?? 'unknown',
      data: json,
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        json['timestamp'] ?? DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }
}

class RealtimeService extends ChangeNotifier {
  static final RealtimeService _instance = RealtimeService._internal();
  factory RealtimeService() => _instance;
  RealtimeService._internal();

  http.Client? _httpClient;
  StreamSubscription<String>? _streamSubscription;
  bool _isConnected = false;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  static const Duration _reconnectDelay = Duration(seconds: 2);

  // Stream controllers for different event types
  final StreamController<Message> _newMessageController = StreamController<Message>.broadcast();
  final StreamController<Map<String, dynamic>> _typingController = StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _aiStreamController = StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<String> _connectionController = StreamController<String>.broadcast();

  // Getters for streams
  Stream<Message> get newMessageStream => _newMessageController.stream;
  Stream<Map<String, dynamic>> get typingStream => _typingController.stream;
  Stream<Map<String, dynamic>> get aiStreamStream => _aiStreamController.stream;
  Stream<String> get connectionStream => _connectionController.stream;

  bool get isConnected => _isConnected;

  Future<void> connect() async {
    if (_isConnected || _httpClient != null) {
      debugPrint('RealtimeService: Already connected or connecting');
      return;
    }

    try {
      final token = await AuthService().getToken();
      if (token == null) {
        debugPrint('RealtimeService: No auth token available');
        return;
      }

      final uri = Uri.parse('${Constants.apiBaseUrl}/streaming/events');
      debugPrint('RealtimeService: Connecting to $uri');

      _httpClient = http.Client();
      
      final request = http.Request('GET', uri);
      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'text/event-stream',
        'Cache-Control': 'no-cache',
        'Connection': 'keep-alive',
      });

      final response = await _httpClient!.send(request);
      
      if (response.statusCode == 200) {
        _isConnected = true;
        _reconnectAttempts = 0;
        _connectionController.add('connected');
        debugPrint('RealtimeService: Connected successfully');
        notifyListeners();

        // Listen to the stream
        _streamSubscription = response.stream
            .transform(const Utf8Decoder())
            .transform(const LineSplitter())
            .listen(
              _handleRawMessage,
              onError: _handleError,
              onDone: _handleDone,
            );
      } else {
        throw Exception('Failed to connect: ${response.statusCode}');
      }

    } catch (error) {
      debugPrint('RealtimeService: Connection error: $error');
      _handleConnectionError();
    }
  }

  void _handleRawMessage(String line) {
    try {
      if (line.startsWith('data: ')) {
        final jsonData = line.substring(6); // Remove 'data: ' prefix
        if (jsonData.trim().isEmpty) return;

        final data = jsonDecode(jsonData);
        final realtimeEvent = RealTimeEvent.fromJson(data);

        debugPrint('RealtimeService: Received event: ${realtimeEvent.type}');

        switch (realtimeEvent.type) {
          case 'connected':
            debugPrint('RealtimeService: Connection confirmed');
            break;

          case 'newMessage':
            _handleNewMessage(realtimeEvent.data);
            break;

          case 'typing':
            _handleTypingUpdate(realtimeEvent.data);
            break;

          case 'aiStream':
            _handleAIStream(realtimeEvent.data);
            break;

          default:
            debugPrint('RealtimeService: Unknown event type: ${realtimeEvent.type}');
        }
      }
    } catch (error) {
      debugPrint('RealtimeService: Error handling message: $error');
    }
  }

  void _handleNewMessage(Map<String, dynamic> data) {
    try {
      final message = Message.fromJson(data['message']);
      _newMessageController.add(message);
      debugPrint('RealtimeService: New message received: ${message.messageId}');
    } catch (error) {
      debugPrint('RealtimeService: Error handling new message: $error');
    }
  }

  void _handleTypingUpdate(Map<String, dynamic> data) {
    try {
      _typingController.add(data);
      debugPrint('RealtimeService: Typing update: ${data['isTyping']}');
    } catch (error) {
      debugPrint('RealtimeService: Error handling typing update: $error');
    }
  }

  void _handleAIStream(Map<String, dynamic> data) {
    try {
      _aiStreamController.add(data);
      debugPrint('RealtimeService: AI stream chunk received');
    } catch (error) {
      debugPrint('RealtimeService: Error handling AI stream: $error');
    }
  }

  void _handleError(Object error) {
    debugPrint('RealtimeService: EventSource error: $error');
    _handleConnectionError();
  }

  void _handleDone() {
    debugPrint('RealtimeService: EventSource connection closed');
    _isConnected = false;
    _connectionController.add('disconnected');
    notifyListeners();
    _attemptReconnect();
  }

  void _handleConnectionError() {
    _isConnected = false;
    _connectionController.add('error');
    notifyListeners();
    _attemptReconnect();
  }

  void _attemptReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      debugPrint('RealtimeService: Max reconnection attempts reached');
      _connectionController.add('failed');
      return;
    }

    _reconnectAttempts++;
    debugPrint('RealtimeService: Attempting reconnect #$_reconnectAttempts');

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(_reconnectDelay * _reconnectAttempts, () {
      disconnect();
      connect();
    });
  }

  void disconnect() {
    debugPrint('RealtimeService: Disconnecting');
    _reconnectTimer?.cancel();
    _streamSubscription?.cancel();
    _httpClient?.close();
    _streamSubscription = null;
    _httpClient = null;
    _isConnected = false;
    _connectionController.add('disconnected');
    notifyListeners();
  }

  @override
  void dispose() {
    disconnect();
    _newMessageController.close();
    _typingController.close();
    _aiStreamController.close();
    _connectionController.close();
    super.dispose();
  }

  // Helper methods for sending events
  Future<void> sendTypingStatus(String conversationId, bool isTyping) async {
    try {
      debugPrint('📤 SENDING TYPING STATUS: conversationId=$conversationId, isTyping=$isTyping');
      
      final token = await AuthService().getToken();
      if (token == null) {
        debugPrint('❌ No auth token available for typing status');
        return;
      }

      final response = await _makeHttpRequest(
        'POST',
        '/messages/$conversationId/typing',
        body: {
          'isTyping': isTyping,
        },
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        debugPrint('✅ TYPING STATUS SENT SUCCESSFULLY: ${response.body}');
      } else {
        debugPrint('❌ FAILED TO SEND TYPING STATUS: ${response.statusCode} - ${response.body}');
      }
    } catch (error) {
      debugPrint('💥 ERROR SENDING TYPING STATUS: $error');
    }
  }

  Future<http.Response> _makeHttpRequest(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    final uri = Uri.parse('${Constants.apiBaseUrl}$endpoint');
    final defaultHeaders = <String, String>{
      'Content-Type': 'application/json',
      ...?headers,
    };

    switch (method.toUpperCase()) {
      case 'POST':
        return await http.post(
          uri,
          headers: defaultHeaders,
          body: body != null ? jsonEncode(body) : null,
        );
      case 'GET':
        return await http.get(uri, headers: defaultHeaders);
      case 'PUT':
        return await http.put(
          uri,
          headers: defaultHeaders,
          body: body != null ? jsonEncode(body) : null,
        );
      case 'DELETE':
        return await http.delete(uri, headers: defaultHeaders);
      default:
        throw Exception('Unsupported HTTP method: $method');
    }
  }
}
