bool isValidEmail(String value) {
  final email = value.trim();
  if (email.isEmpty || email.length > 254) return false;

  final parts = email.split('@');
  if (parts.length != 2) return false;

  final local = parts[0];
  final domain = parts[1];
  if (local.isEmpty || domain.isEmpty || local.length > 64) return false;
  if (local.startsWith('.') || local.endsWith('.') || local.contains('..')) {
    return false;
  }
  if (domain.startsWith('.') || domain.endsWith('.') || domain.contains('..')) {
    return false;
  }

  final localPattern = RegExp(r"^[A-Za-z0-9.!#$%&'*+/=?^_`{|}~-]+$");
  final domainPattern = RegExp(
    r'^(?=.{1,253}$)([A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?\.)+[A-Za-z]{2,63}$',
  );

  return localPattern.hasMatch(local) && domainPattern.hasMatch(domain);
}
