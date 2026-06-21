import 'package:flutter_test/flutter_test.dart';
import 'package:we_counsel/services/analytics_dispatcher.dart';
import 'package:we_counsel/services/analytics_service.dart';

void main() {
  late _RecordingAnalyticsDispatcher dispatcher;

  setUp(() {
    dispatcher = _RecordingAnalyticsDispatcher();
    AnalyticsService.setDispatcherForTesting(dispatcher);
  });

  tearDown(AnalyticsService.resetDispatcherForTesting);

  test('tracks sign up completion without sensitive fields', () {
    AnalyticsService.trackSignUpComplete(
      method: 'email',
      language: 'fr',
      planTier: 'essential',
      hasInvitation: true,
    );

    expect(dispatcher.events, hasLength(1));
    expect(dispatcher.events.single.name, 'sign_up_complete');
    expect(dispatcher.events.single.parameters, {
      'method': 'email',
      'language': 'fr',
      'plan_tier': 'essential',
      'has_invitation': true,
    });
  });

  test('tracks app open metadata', () {
    AnalyticsService.trackAppOpen(language: 'fr', entryPath: '/register');

    expect(dispatcher.events.single.name, 'app_open');
    expect(dispatcher.events.single.parameters, {
      'language': 'fr',
      'entry_path': '/register',
    });
  });

  test('tracks sign up start source', () {
    AnalyticsService.trackSignUpStart(source: 'invitation', language: 'fr');

    expect(dispatcher.events.single.name, 'sign_up_start');
    expect(dispatcher.events.single.parameters, {
      'source': 'invitation',
      'language': 'fr',
    });
  });

  test('tracks invite funnel events without partner data', () {
    AnalyticsService.trackInvitePartnerStart(source: 'invite_screen');
    AnalyticsService.trackInvitePartnerSent(method: 'email');

    expect(dispatcher.events, hasLength(2));
    expect(dispatcher.events.first.name, 'invite_partner_start');
    expect(dispatcher.events.first.parameters, {'source': 'invite_screen'});
    expect(dispatcher.events.last.name, 'invite_partner_sent');
    expect(dispatcher.events.last.parameters, {'method': 'email'});
  });

  test('tracks checkout start with subscription value', () {
    AnalyticsService.trackSubscriptionCheckoutStart(
      planTier: 'premium',
      billingPeriod: 'annual',
    );

    expect(dispatcher.events.single.name, 'subscription_checkout_start');
    expect(dispatcher.events.single.parameters, {
      'plan_tier': 'premium',
      'billing_period': 'annual',
      'currency': 'EUR',
      'value': 191.9,
    });
  });

  test('tracks purchase with known plan metadata', () {
    AnalyticsService.trackSubscriptionPurchase(
      planTier: 'essential',
      billingPeriod: 'monthly',
    );

    expect(dispatcher.events.single.name, 'subscription_purchase');
    expect(dispatcher.events.single.parameters, {
      'plan_tier': 'essential',
      'billing_period': 'monthly',
      'currency': 'EUR',
      'value': 9.99,
    });
  });

  test('filters sensitive and unsupported custom parameters', () {
    AnalyticsService.trackEvent('custom_event', {
      'email': 'person@example.com',
      'first_name': 'Private',
      'message_text': 'Private text',
      'plan_tier': 'essential',
      'value': 9.99,
      'enabled': true,
      'nested': {'unsafe': true},
    });

    expect(dispatcher.events.single.parameters, {
      'plan_tier': 'essential',
      'value': 9.99,
      'enabled': true,
    });
  });
}

class _RecordingAnalyticsDispatcher implements AnalyticsDispatcher {
  final events = <_AnalyticsEvent>[];

  @override
  void trackEvent(String name, Map<String, Object> parameters) {
    events.add(_AnalyticsEvent(name, parameters));
  }
}

class _AnalyticsEvent {
  final String name;
  final Map<String, Object> parameters;

  _AnalyticsEvent(this.name, this.parameters);
}
