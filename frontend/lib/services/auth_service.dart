import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/constants.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  static const _storage = FlutterSecureStorage();
  static bool _secureStorageAvailable = true;
  static String? _memoryToken;

  static void cacheToken(String? token) {
    _memoryToken = token;
  }

  // Get authentication token
  Future<String?> getToken() async {
    if (!_secureStorageAvailable) {
      return _memoryToken;
    }

    try {
      final token = await _storage.read(key: Constants.authTokenKey);
      if (token != null) {
        _memoryToken = token;
      }
      return token ?? _memoryToken;
    } catch (e) {
      _secureStorageAvailable = false;
      return _memoryToken;
    }
  }

  // Save authentication token
  Future<void> saveToken(String token) async {
    _memoryToken = token;
    if (!_secureStorageAvailable) {
      return;
    }

    try {
      await _storage.write(key: Constants.authTokenKey, value: token);
    } catch (e) {
      _secureStorageAvailable = false;
    }
  }

  // Remove authentication token
  Future<void> removeToken() async {
    _memoryToken = null;
    if (!_secureStorageAvailable) {
      return;
    }

    try {
      await _storage.delete(key: Constants.authTokenKey);
    } catch (e) {
      _secureStorageAvailable = false;
    }
  }

  // Check if user is authenticated
  Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // Get user data from storage
  Future<String?> getUserData() async {
    try {
      return await _storage.read(key: Constants.userDataKey);
    } catch (e) {
      return null;
    }
  }

  // Save user data to storage
  Future<void> saveUserData(String userData) async {
    try {
      await _storage.write(key: Constants.userDataKey, value: userData);
    } catch (e) {
      // Handle error silently
    }
  }

  // Remove user data from storage
  Future<void> removeUserData() async {
    try {
      await _storage.delete(key: Constants.userDataKey);
    } catch (e) {
      // Handle error silently
    }
  }

  // Clear all auth data
  Future<void> clearAll() async {
    await removeToken();
    await removeUserData();
  }
}
