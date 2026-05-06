import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class AttributionService {
  static final AttributionService _instance = AttributionService._internal();
  factory AttributionService() => _instance;
  AttributionService._internal();

  static const _firstTouchKey = 'we_connect_first_touch_attribution';
  static const _lastTouchKey = 'we_connect_last_touch_attribution';

  Future<void> captureCurrentUri() async {
    final uri = Uri.base;
    final utmParams = _extractUtmParams(uri);

    if (utmParams.isEmpty) return;

    final now = DateTime.now().toUtc().toIso8601String();
    final record = <String, dynamic>{
      'utm': utmParams,
      'landingPage': _truncate(uri.toString(), 2048),
      'campaignCapturedAt': now,
    };

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastTouchKey, jsonEncode(record));

    if (!prefs.containsKey(_firstTouchKey)) {
      await prefs.setString(_firstTouchKey, jsonEncode(record));
    }
  }

  Future<Map<String, dynamic>?> buildSignupAttribution() async {
    final prefs = await SharedPreferences.getInstance();
    final firstTouch = _decodeRecord(prefs.getString(_firstTouchKey));
    final lastTouch = _decodeRecord(prefs.getString(_lastTouchKey));

    if (firstTouch == null && lastTouch == null) return null;

    final payload = <String, dynamic>{};
    final firstUtm = firstTouch?['utm'];
    final lastUtm = lastTouch?['utm'];

    if (firstUtm is Map && firstUtm.isNotEmpty) {
      payload['firstTouchUtm'] = Map<String, dynamic>.from(firstUtm);
    }

    if (lastUtm is Map && lastUtm.isNotEmpty) {
      payload['lastTouchUtm'] = Map<String, dynamic>.from(lastUtm);
    }

    final landingPage = firstTouch?['landingPage'] ?? lastTouch?['landingPage'];
    if (landingPage is String && landingPage.isNotEmpty) {
      payload['landingPage'] = landingPage;
    }

    final capturedAt =
        firstTouch?['campaignCapturedAt'] ?? lastTouch?['campaignCapturedAt'];
    if (capturedAt is String && capturedAt.isNotEmpty) {
      payload['campaignCapturedAt'] = capturedAt;
    }

    return payload.isEmpty ? null : payload;
  }

  Map<String, String> _extractUtmParams(Uri uri) {
    final params = <String, String>{};

    uri.queryParameters.forEach((key, value) {
      if (key.startsWith('utm_') && value.isNotEmpty) {
        params[_truncate(key, 128)] = _truncate(value, 512);
      }
    });

    return params;
  }

  Map<String, dynamic>? _decodeRecord(String? raw) {
    if (raw == null || raw.isEmpty) return null;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {
      return null;
    }

    return null;
  }

  String _truncate(String value, int maxLength) {
    if (value.length <= maxLength) return value;
    return value.substring(0, maxLength);
  }
}
