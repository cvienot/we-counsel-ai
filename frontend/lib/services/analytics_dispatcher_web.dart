import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'analytics_dispatcher.dart';

AnalyticsDispatcher createAnalyticsDispatcher() => _WebAnalyticsDispatcher();

class _WebAnalyticsDispatcher implements AnalyticsDispatcher {
  @override
  void trackEvent(String name, Map<String, Object> parameters) {
    try {
      final tags = globalContext.getProperty<JSObject?>('WeConnectTags'.toJS);
      if (tags == null || tags.isUndefinedOrNull) return;

      tags.callMethod<JSAny?>('event'.toJS, name.toJS, parameters.jsify());
    } catch (_) {
      // Analytics must never interrupt the product flow.
    }
  }
}
