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
    String? invitationId,
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
        
        // Connect to realtime service after successful registration
        await _realtimeService.connect();
        
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
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
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
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
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
        
        // Connect to realtime service if not connected
        await _realtimeService.connect();
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
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
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
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
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
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
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
