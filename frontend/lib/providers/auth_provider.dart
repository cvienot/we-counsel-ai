import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  AuthNotifier(this._apiService) : super(const AuthState()) {
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    print('🔐 AUTH: Starting auth initialization...');
    state = state.copyWith(isLoading: true);

    try {
      final token = await _apiService.getToken();
      print(
        '🔐 AUTH: Token check - ${token != null ? "Token found" : "No token"}',
      );

      if (token != null && token.isNotEmpty) {
        // Token exists, verify it's still valid by getting current user
        print('🔐 AUTH: Verifying token with server...');
        await getCurrentUser();
        print('🔐 AUTH: Token verified successfully');
      } else {
        // No token, user is not authenticated
        print('🔐 AUTH: No token found, user not authenticated');
        state = state.copyWith(isLoading: false, isAuthenticated: false);
      }
    } catch (e) {
      // Token is invalid or expired, clear it and logout
      print('🔐 AUTH: Token verification failed: $e');
      await _apiService.clearToken();
      _realtimeService.disconnect();
      state = state.copyWith(
        user: null,
        isLoading: false,
        isAuthenticated: false,
        error: null,
      );
      print(
        '🔐 AUTH: State updated - isAuthenticated: ${state.isAuthenticated}, isLoading: ${state.isLoading}',
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

      print('🔵 AUTH: Register response: ${response.toString()}');
      print(
        '🔵 AUTH: success=${response['success']}, user=${response['user'] != null}',
      );

      if (response['success'] == true && response['user'] != null) {
        final user = User.fromJson(response['user']);
        print('🔵 AUTH: Setting auth state - isAuthenticated: true');
        state = state.copyWith(
          user: user,
          isLoading: false,
          isAuthenticated: true,
        );
        print('🔵 AUTH: State updated - isAuth: ${state.isAuthenticated}');

        // Connect to realtime service after successful registration
        try {
          print('🔵 AUTH: Connecting to realtime service...');
          await _realtimeService.connect();
          print('🔵 AUTH: Realtime service connected');
        } catch (e) {
          print(
            '🔵 AUTH: Realtime service connection failed: $e (non-critical)',
          );
          // Don't fail registration if realtime connection fails
        }

        // If there's a pending invitation, accept it automatically
        if (invitationId != null) {
          try {
            await acceptInvitation(invitationId);
          } catch (e) {
            // Log the error but don't fail the registration
            print('Failed to auto-accept invitation: $e');
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
        await _realtimeService.connect();

        // If there's a pending invitation, accept it automatically
        if (invitationId != null) {
          try {
            await acceptInvitation(invitationId);
          } catch (e) {
            // Log the error but don't fail the login
            print('Failed to auto-accept invitation: $e');
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
        await _realtimeService.connect();
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
