import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/constants.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  static const _storage = FlutterSecureStorage();

  // Get authentication token
  Future<String?> getToken() async {
    try {
      return await _storage.read(key: Constants.authTokenKey);
    } catch (e) {
      return null;
    }
  }

  // Save authentication token
  Future<void> saveToken(String token) async {
    try {
      await _storage.write(key: Constants.authTokenKey, value: token);
    } catch (e) {
      // Handle error silently
    }
  }

  // Remove authentication token
  Future<void> removeToken() async {
    try {
      await _storage.delete(key: Constants.authTokenKey);
    } catch (e) {
      // Handle error silently
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
