import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/message.dart';
import '../services/auth_service.dart';
import '../utils/constants.dart';

class StreamingMessageService extends ChangeNotifier {
  static final StreamingMessageService _instance = StreamingMessageService._internal();
  factory StreamingMessageService() => _instance;
  StreamingMessageService._internal();

  final Map<String, StreamController<String>> _aiStreamControllers = {};
  final Map<String, String> _streamingMessages = {};
  final Map<String, bool> _streamingComplete = {};

  // Get or create a stream controller for AI message streaming
  StreamController<String> _getStreamController(String messageId) {
    if (!_aiStreamControllers.containsKey(messageId)) {
      _aiStreamControllers[messageId] = StreamController<String>.broadcast();
      _streamingMessages[messageId] = '';
      _streamingComplete[messageId] = false;
    }
    return _aiStreamControllers[messageId]!;
  }

  // Get the stream for a specific AI message
  Stream<String> getAIMessageStream(String messageId) {
    return _getStreamController(messageId).stream;
  }

  // Get the current accumulated content for a streaming message
  String getStreamingContent(String messageId) {
    return _streamingMessages[messageId] ?? '';
  }

  // Check if streaming is complete for a message
  bool isStreamingComplete(String messageId) {
    return _streamingComplete[messageId] ?? false;
  }

  // Handle AI stream chunks
  void handleAIStreamChunk(String messageId, String chunk, bool isComplete) {
    final controller = _getStreamController(messageId);
    
    if (!isComplete && chunk.isNotEmpty) {
      _streamingMessages[messageId] = (_streamingMessages[messageId] ?? '') + chunk;
      controller.add(chunk);
    }
    
    if (isComplete) {
      _streamingComplete[messageId] = true;
      controller.close();
      notifyListeners();
    }
  }

  // Send a message with streaming AI response
  Future<Message?> sendMessageWithStreaming(
    String conversationId,
    String content, {
    String recipientType = 'both',
  }) async {
    try {
      final token = await AuthService().getToken();
      if (token == null) {
        throw Exception('No authentication token');
      }

      final uri = Uri.parse('${Constants.apiBaseUrl}/messages/$conversationId/ai-stream');
      
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'content': content,
          'recipientType': recipientType,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return Message.fromJson(data['userMessage']);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Failed to send message');
      }
    } catch (error) {
      debugPrint('StreamingMessageService: Error sending message: $error');
      rethrow;
    }
  }

  // Clean up completed streams
  void cleanupStream(String messageId) {
    if (_aiStreamControllers.containsKey(messageId)) {
      _aiStreamControllers[messageId]?.close();
      _aiStreamControllers.remove(messageId);
      _streamingMessages.remove(messageId);
      _streamingComplete.remove(messageId);
    }
  }

  @override
  void dispose() {
    for (final controller in _aiStreamControllers.values) {
      controller.close();
    }
    _aiStreamControllers.clear();
    _streamingMessages.clear();
    _streamingComplete.clear();
    super.dispose();
  }
}
