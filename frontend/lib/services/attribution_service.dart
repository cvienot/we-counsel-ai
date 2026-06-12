import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AttributionService {
  static final AttributionService _instance = AttributionService._internal();
  factory AttributionService() => _instance;
  AttributionService._internal();

  static const _firstTouchKey = 'we_connect_first_touch_attribution';
  static const _lastTouchKey = 'we_connect_last_touch_attribution';
  static const _adAttributionKeys = {
    'gclid',
    'gbraid',
    'wbraid',
    'gad_campaignid',
    'gad_source',
  };

  Future<void> captureCurrentUri() async {
    await _captureUri(Uri.base);
  }

  @visibleForTesting
  Future<void> captureUriForTesting(Uri uri) async {
    await _captureUri(uri);
  }

  Future<void> _captureUri(Uri uri) async {
    final utmParams = _extractUtmParams(uri);
    final adParams = _extractAdAttributionParams(uri);

    if (utmParams.isEmpty && adParams.isEmpty) return;

    final now = DateTime.now().toUtc().toIso8601String();
    final record = <String, dynamic>{
      if (utmParams.isNotEmpty) 'utm': utmParams,
      if (adParams.isNotEmpty) 'ad': adParams,
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
    final firstAd = firstTouch?['ad'];
    final lastAd = lastTouch?['ad'];

    if (firstUtm is Map && firstUtm.isNotEmpty) {
      payload['firstTouchUtm'] = Map<String, dynamic>.from(firstUtm);
    }

    if (lastUtm is Map && lastUtm.isNotEmpty) {
      payload['lastTouchUtm'] = Map<String, dynamic>.from(lastUtm);
    }

    if (firstAd is Map && firstAd.isNotEmpty) {
      payload['firstTouchAdParams'] = Map<String, dynamic>.from(firstAd);
    }

    if (lastAd is Map && lastAd.isNotEmpty) {
      payload['lastTouchAdParams'] = Map<String, dynamic>.from(lastAd);
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

  Map<String, String> _extractAdAttributionParams(Uri uri) {
    final params = <String, String>{};

    uri.queryParameters.forEach((key, value) {
      if ((_adAttributionKeys.contains(key) || key.startsWith('gad_')) &&
          value.isNotEmpty) {
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
