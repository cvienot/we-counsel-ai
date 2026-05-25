String? safeInternalRedirect(String? target) {
  if (target == null || target.isEmpty) return null;

  final uri = Uri.tryParse(target);
  if (uri == null || uri.hasScheme || uri.hasAuthority) return null;

  final path = uri.path.isEmpty ? '/' : uri.path;
  if (!path.startsWith('/') || path.startsWith('//')) return null;
  if (path == '/' ||
      path == '/splash' ||
      path == '/login' ||
      path == '/register') {
    return null;
  }

  return uri.toString();
}

String routeWithFrom(String route, String? from) {
  final safeFrom = safeInternalRedirect(from);
  if (safeFrom == null) return route;

  return '$route?from=${Uri.encodeComponent(safeFrom)}';
}

String postAuthRedirect(Uri uri) {
  return safeInternalRedirect(uri.queryParameters['from']) ?? '/main-thread';
}
