import 'package:flutter/foundation.dart';

import 'analytics_dispatcher.dart';
import 'analytics_dispatcher_stub.dart'
    if (dart.library.js) 'analytics_dispatcher_web.dart';

class AnalyticsService {
  static AnalyticsDispatcher _dispatcher = createAnalyticsDispatcher();

  static void trackEvent(String name, Map<String, Object?> parameters) {
    if (name.isEmpty) return;

    final sanitized = _sanitizeParameters(parameters);
    _dispatcher.trackEvent(name, sanitized);
  }

  static void trackAppOpen({
    required String language,
    required String entryPath,
  }) {
    trackEvent('app_open', {'language': language, 'entry_path': entryPath});
  }

  static void trackSignUpStart({
    required String source,
    required String language,
  }) {
    trackEvent('sign_up_start', {'source': source, 'language': language});
  }

  static void trackSignUpComplete({
    required String method,
    required String language,
    required String planTier,
    required bool hasInvitation,
  }) {
    trackEvent('sign_up_complete', {
      'method': method,
      'language': language,
      'plan_tier': planTier,
      'has_invitation': hasInvitation,
    });
  }

  static void trackInvitePartnerStart({required String source}) {
    trackEvent('invite_partner_start', {'source': source});
  }

  static void trackInvitePartnerSent({required String method}) {
    trackEvent('invite_partner_sent', {'method': method});
  }

  static void trackSubscriptionCheckoutStart({
    required String planTier,
    required String billingPeriod,
  }) {
    trackEvent('subscription_checkout_start', {
      'plan_tier': planTier,
      'billing_period': billingPeriod,
      'currency': 'EUR',
      'value': _subscriptionValue(planTier, billingPeriod),
    });
  }

  static void trackSubscriptionPurchase({
    String? planTier,
    String? billingPeriod,
  }) {
    trackEvent('subscription_purchase', {
      if (planTier != null && planTier.isNotEmpty) 'plan_tier': planTier,
      if (billingPeriod != null && billingPeriod.isNotEmpty)
        'billing_period': billingPeriod,
      'currency': 'EUR',
      'value': _subscriptionValue(planTier, billingPeriod),
    });
  }

  static Map<String, Object> _sanitizeParameters(
    Map<String, Object?> parameters,
  ) {
    final sanitized = <String, Object>{};
    final blockedKeyPattern = RegExp(
      'email|name|message|text|content|note|partner',
      caseSensitive: false,
    );

    parameters.forEach((key, value) {
      if (blockedKeyPattern.hasMatch(key)) return;
      if (value is String || value is num || value is bool) {
        sanitized[key] = value as Object;
      }
    });

    return sanitized;
  }

  static double? _subscriptionValue(String? planTier, String? billingPeriod) {
    if (planTier == null || billingPeriod == null) return null;

    final monthlyPrice = switch (planTier) {
      'essential' => 9.99,
      'premium' => 19.99,
      _ => null,
    };
    if (monthlyPrice == null) return null;

    return switch (billingPeriod) {
      'monthly' => monthlyPrice,
      'annual' => double.parse((monthlyPrice * 12 * 0.8).toStringAsFixed(2)),
      _ => null,
    };
  }

  @visibleForTesting
  static void setDispatcherForTesting(AnalyticsDispatcher dispatcher) {
    _dispatcher = dispatcher;
  }

  @visibleForTesting
  static void resetDispatcherForTesting() {
    _dispatcher = createAnalyticsDispatcher();
  }
}
