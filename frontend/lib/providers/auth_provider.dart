import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/environment.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/realtime_service.dart';

// Auth state
class AuthState {
  final User? user;
  final bool isLoading;
  final String? error;
  final bool isAuthenticated;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.isAuthenticated = false,
  });

  AuthState copyWith({
    User? user,
    bool? isLoading,
    String? error,
    bool? isAuthenticated,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }
}

// Auth provider
class AuthNotifier extends StateNotifier<AuthState> {
  final ApiService _apiService;
  final RealtimeService _realtimeService = RealtimeService();
  static const Duration _startupTokenReadTimeout = Duration(seconds: 4);

  AuthNotifier(this._apiService) : super(const AuthState()) {
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    Environment.log('AUTH: Starting auth initialization...');
    state = state.copyWith(isLoading: true);

    try {
      final tokenRead = _apiService.getToken();
      final token = Environment.isProduction
          ? await tokenRead.timeout(
              _startupTokenReadTimeout,
              onTimeout: () {
                Environment.log(
                  'AUTH: Token read timed out, continuing logged out',
                );
                return null;
              },
            )
          : await tokenRead;
      Environment.log(
        'AUTH: Token check - ${token != null ? "Token found" : "No token"}',
      );

      if (token != null && token.isNotEmpty) {
        // Token exists, verify it's still valid by getting current user
        Environment.log('AUTH: Verifying token with server...');
        await getCurrentUser();
        Environment.log('AUTH: Token verified successfully');
      } else {
        // No token, user is not authenticated
        Environment.log('AUTH: No token found, user not authenticated');
        state = state.copyWith(isLoading: false, isAuthenticated: false);
      }
    } catch (e) {
      // Token is invalid or expired, clear it and logout
      Environment.log('AUTH: Token verification failed: $e');
      await _apiService.clearToken();
      _realtimeService.disconnect();
      state = state.copyWith(
        user: null,
        isLoading: false,
        isAuthenticated: false,
        error: null,
      );
      Environment.log(
        'AUTH: State updated - isAuthenticated: ${state.isAuthenticated}, isLoading: ${state.isLoading}',
      );
    }
  }

  Future<void> checkAuthStatus() async {
    await _initializeAuth();
  }

  Future<void> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? invitationId,
    String? language,
    bool termsAccepted = false,
    String? subscriptionTier,
    Map<String, dynamic>? attribution,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _apiService.register(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        language: language,
        termsAccepted: termsAccepted,
        subscriptionTier: subscriptionTier,
        attribution: attribution,
      );

      Environment.log(
        'AUTH: Register result success=${response['success']}, hasUser=${response['user'] != null}',
      );

      if (response['success'] == true && response['user'] != null) {
        final user = User.fromJson(response['user']);
        Environment.log('AUTH: Setting auth state - isAuthenticated: true');
        state = state.copyWith(
          user: user,
          isLoading: false,
          isAuthenticated: true,
        );
        Environment.log(
          'AUTH: State updated - isAuth: ${state.isAuthenticated}',
        );

        // Connect to realtime service after successful registration.
        _connectRealtimeInBackground('registration');

        // If there's a pending invitation, accept it automatically
        if (invitationId != null) {
          try {
            await acceptInvitation(invitationId);
          } catch (e) {
            // Log the error but don't fail the registration
            Environment.log('Failed to auto-accept invitation: $e');
          }
        }
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> login({
    required String email,
    required String password,
    String? invitationId,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _apiService.login(
        email: email,
        password: password,
      );

      if (response['success'] == true && response['user'] != null) {
        final user = User.fromJson(response['user']);
        state = state.copyWith(
          user: user,
          isLoading: false,
          isAuthenticated: true,
        );

        // Connect to realtime service after successful login
        _connectRealtimeInBackground('login');

        // If there's a pending invitation, accept it automatically
        if (invitationId != null) {
          try {
            await acceptInvitation(invitationId);
          } catch (e) {
            // Log the error but don't fail the login
            Environment.log('Failed to auto-accept invitation: $e');
          }
        }
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> getCurrentUser() async {
    try {
      final response = await _apiService.getCurrentUser();

      if (response['success'] == true && response['user'] != null) {
        final user = User.fromJson(response['user']);
        state = state.copyWith(
          user: user,
          isAuthenticated: true,
          isLoading: false,
          error: null,
        );

        // Connect to realtime service if not connected
        _connectRealtimeInBackground('auth restore');
      } else {
        // Invalid response, treat as unauthenticated
        state = state.copyWith(
          user: null,
          isAuthenticated: false,
          isLoading: false,
          error: null,
        );
      }
    } catch (e) {
      state = state.copyWith(
        user: null,
        isAuthenticated: false,
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  Future<void> updateProfile({
    required String firstName,
    required String lastName,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _apiService.updateProfile(
        firstName: firstName,
        lastName: lastName,
      );

      if (response['success'] == true && response['user'] != null) {
        final updatedUser = User.fromJson(response['user']);
        state = state.copyWith(user: updatedUser, isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> invitePartner({required String email, String? message}) async {
    try {
      await _apiService.invitePartner(email: email, message: message);

      // Refresh user data to get pendingInvitation info
      await getCurrentUser();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> acceptInvitation(String invitationId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _apiService.acceptInvitation(invitationId);

      // Refresh user data to get updated partner info
      await getCurrentUser();

      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> logout() async {
    await _apiService.clearToken();
    _realtimeService.disconnect();
    state = const AuthState();
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  void _connectRealtimeInBackground(String source) {
    unawaited(
      _realtimeService.connect().catchError((Object error) {
        Environment.log(
          'AUTH: Realtime service connection failed after $source: $error',
        );
      }),
    );
  }
}

// Providers
final apiServiceProvider = Provider((ref) => ApiService());

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(apiServiceProvider));
});

// Helper providers
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authProvider).user;
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isAuthenticated;
});

final hasPartnerProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  return user?.hasPartner ?? false;
});

// Provider to store pending invitation ID
final pendingInvitationProvider = StateProvider<String?>((ref) => null);
