import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class ExerciseService {
  final String baseUrl = AppConfig.apiBaseUrl;

  // Get available exercises
  Future<List<Map<String, dynamic>>> getExercises(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/exercises'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['exercises']);
    } else {
      throw Exception('Failed to load exercises');
    }
  }

  // Start an exercise
  Future<Map<String, dynamic>> startExercise({
    required String token,
    required String conversationId,
    required String exerciseId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/exercises/start'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'conversationId': conversationId,
        'exerciseId': exerciseId,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data;
    } else {
      throw Exception('Failed to start exercise');
    }
  }

  // Progress to next step
  Future<Map<String, dynamic>> progressExercise({
    required String token,
    required String sessionId,
    required String response,
  }) async {
    final httpResponse = await http.post(
      Uri.parse('$baseUrl/api/exercises/$sessionId/progress'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'response': response,
      }),
    );

    if (httpResponse.statusCode == 200) {
      final data = jsonDecode(httpResponse.body);
      return data;
    } else {
      throw Exception('Failed to progress exercise');
    }
  }

  // Get exercise summary
  Future<String> getExerciseSummary({
    required String token,
    required String sessionId,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/exercises/$sessionId/summary'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['summary'];
    } else {
      throw Exception('Failed to get summary');
    }
  }

  // Get active exercise session for conversation
  // Returns full response: { session: {...}, exercise: {...} } or null if no active session
  Future<Map<String, dynamic>?> getActiveSession({
    required String token,
    required String conversationId,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/exercises/active/$conversationId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['session'] == null) return null;
      return data; // { session, exercise }
    } else {
      throw Exception('Failed to get active session');
    }
  }

  // Get exercise history for the couple
  Future<List<Map<String, dynamic>>> getExerciseHistory(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/exercises/history'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['sessions']);
    } else {
      throw Exception('Failed to load exercise history');
    }
  }
}
