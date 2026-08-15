import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:we_counsel/services/attribution_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('captures UTM and Google Ads click parameters separately', () async {
    final service = AttributionService();

    await service.captureUriForTesting(
      Uri.parse(
        'https://app.entrelace.app/?utm_source=google&utm_medium=cpc&utm_campaign=fr_search_launch&gclid=test-gclid&gbraid=test-gbraid&gad_source=1&gad_campaignid=12345',
      ),
    );

    final attribution = await service.buildSignupAttribution();

    expect(attribution, isNotNull);
    expect(attribution!['firstTouchUtm'], {
      'utm_source': 'google',
      'utm_medium': 'cpc',
      'utm_campaign': 'fr_search_launch',
    });
    expect(attribution['lastTouchUtm'], attribution['firstTouchUtm']);
    expect(attribution['firstTouchAdParams'], {
      'gclid': 'test-gclid',
      'gbraid': 'test-gbraid',
      'gad_source': '1',
      'gad_campaignid': '12345',
    });
    expect(attribution['lastTouchAdParams'], attribution['firstTouchAdParams']);
    expect(attribution['landingPage'], contains('gclid=test-gclid'));
    expect(attribution['campaignCapturedAt'], isA<String>());
  });

  test('keeps original first touch while updating last touch', () async {
    final service = AttributionService();

    await service.captureUriForTesting(
      Uri.parse(
        'https://app.entrelace.app/?utm_source=google&gclid=first-click',
      ),
    );
    await service.captureUriForTesting(
      Uri.parse(
        'https://app.entrelace.app/?utm_source=google&gclid=last-click',
      ),
    );

    final attribution = await service.buildSignupAttribution();

    expect(attribution!['firstTouchAdParams'], {'gclid': 'first-click'});
    expect(attribution['lastTouchAdParams'], {'gclid': 'last-click'});
  });
}
