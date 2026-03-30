import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/environment.dart';

class ProgressService {
  final String baseUrl = Environment.apiBaseUrl;

  /// Get full progress dashboard data
  Future<Map<String, dynamic>> getDashboard(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/progress/dashboard'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load progress dashboard');
    }
  }

  /// Get exercise statistics only
  Future<Map<String, dynamic>> getExerciseStats(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/progress/exercises'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load exercise stats');
    }
  }

  /// Get weekly activity data
  Future<Map<String, dynamic>> getActivityData(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/progress/activity'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load activity data');
    }
  }
}
