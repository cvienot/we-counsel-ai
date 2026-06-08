import 'analytics_dispatcher.dart';

AnalyticsDispatcher createAnalyticsDispatcher() => _NoopAnalyticsDispatcher();

class _NoopAnalyticsDispatcher implements AnalyticsDispatcher {
  @override
  void trackEvent(String name, Map<String, Object> parameters) {}
}
