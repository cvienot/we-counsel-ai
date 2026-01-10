import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class PaymentService {
  final String baseUrl;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  PaymentService({required this.baseUrl});

  Future<String?> _getToken() async {
    return await _storage.read(key: 'auth_token');
  }

  /// Create Stripe checkout session
  Future<Map<String, dynamic>> createCheckoutSession({
    required String tier,
    required String billingPeriod,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {
          'success': false,
          'error': 'Not authenticated',
        };
      }

      final response = await http.post(
        Uri.parse('$baseUrl/api/payments/create-checkout-session'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'tier': tier,
          'billingPeriod': billingPeriod,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'sessionId': data['sessionId'],
          'url': data['url'],
        };
      } else {
        return {
          'success': false,
          'error': data['error'] ?? 'Failed to create checkout session',
          'message': data['message'],
        };
      }
    } catch (e) {
      print('❌ Error creating checkout session: $e');
      return {
        'success': false,
        'error': 'Network error',
        'message': e.toString(),
      };
    }
  }

  /// Create Stripe customer portal session
  Future<Map<String, dynamic>> createPortalSession() async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {
          'success': false,
          'error': 'Not authenticated',
        };
      }

      final response = await http.post(
        Uri.parse('$baseUrl/api/payments/create-portal-session'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'url': data['url'],
        };
      } else {
        return {
          'success': false,
          'error': data['error'] ?? 'Failed to create portal session',
          'message': data['message'],
        };
      }
    } catch (e) {
      print('❌ Error creating portal session: $e');
      return {
        'success': false,
        'error': 'Network error',
        'message': e.toString(),
      };
    }
  }

  /// Get billing history (invoices)
  Future<Map<String, dynamic>> getInvoices({int limit = 10}) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {
          'success': false,
          'error': 'Not authenticated',
        };
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/payments/invoices?limit=$limit'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'invoices': data['invoices'] ?? [],
        };
      } else {
        return {
          'success': false,
          'error': data['error'] ?? 'Failed to get invoices',
          'message': data['message'],
        };
      }
    } catch (e) {
      print('❌ Error getting invoices: $e');
      return {
        'success': false,
        'error': 'Network error',
        'message': e.toString(),
      };
    }
  }

  /// Get current subscription usage
  Future<Map<String, dynamic>> getSubscriptionUsage() async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {
          'success': false,
          'error': 'Not authenticated',
        };
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/subscriptions/usage'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'usage': data['usage'],
        };
      } else {
        return {
          'success': false,
          'error': data['error'] ?? 'Failed to get subscription usage',
          'message': data['message'],
        };
      }
    } catch (e) {
      print('❌ Error getting subscription usage: $e');
      return {
        'success': false,
        'error': 'Network error',
        'message': e.toString(),
      };
    }
  }
}
