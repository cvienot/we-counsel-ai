import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../models/user.dart';
import '../services/api_service.dart';

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

  AuthNotifier(this._apiService) : super(const AuthState()) {
    checkAuthStatus();
  }

  Future<void> checkAuthStatus() async {
    final token = await _apiService.getToken();
    if (token != null) {
      try {
        await getCurrentUser();
      } catch (e) {
        await logout();
      }
    }
  }

  Future<void> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final response = await _apiService.register(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
      );
      
      if (response['success'] == true && response['user'] != null) {
        final user = User.fromJson(response['user']);
        state = state.copyWith(
          user: user,
          isLoading: false,
          isAuthenticated: true,
        );
      }
    } on DioException catch (e) {
      final apiError = ApiService.handleError(e);
      state = state.copyWith(
        isLoading: false,
        error: apiError.message,
      );
      rethrow;
    }
  }

  Future<void> login({
    required String email,
    required String password,
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
      }
    } on DioException catch (e) {
      final apiError = ApiService.handleError(e);
      state = state.copyWith(
        isLoading: false,
        error: apiError.message,
      );
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
        );
      }
    } catch (e) {
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
        state = state.copyWith(
          user: updatedUser,
          isLoading: false,
        );
      }
    } on DioException catch (e) {
      final apiError = ApiService.handleError(e);
      state = state.copyWith(
        isLoading: false,
        error: apiError.message,
      );
      rethrow;
    }
  }

  Future<void> invitePartner({
    required String email,
    String? message,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      await _apiService.invitePartner(
        email: email,
        message: message,
      );
      
      state = state.copyWith(isLoading: false);
    } on DioException catch (e) {
      final apiError = ApiService.handleError(e);
      state = state.copyWith(
        isLoading: false,
        error: apiError.message,
      );
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
    } on DioException catch (e) {
      final apiError = ApiService.handleError(e);
      state = state.copyWith(
        isLoading: false,
        error: apiError.message,
      );
      rethrow;
    }
  }

  Future<void> logout() async {
    await _apiService.clearToken();
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
