import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../services/progress_service.dart';
import 'auth_provider.dart';

class ProgressState {
  final bool isLoading;
  final String? error;
  final int healthScore;
  final Map<String, dynamic> exerciseStats;
  final Map<String, dynamic> conversationStats;
  final Map<String, dynamic> activityStreak;
  final List<Map<String, dynamic>> weeklyActivity;

  const ProgressState({
    this.isLoading = false,
    this.error,
    this.healthScore = 0,
    this.exerciseStats = const {},
    this.conversationStats = const {},
    this.activityStreak = const {},
    this.weeklyActivity = const [],
  });

  ProgressState copyWith({
    bool? isLoading,
    String? error,
    int? healthScore,
    Map<String, dynamic>? exerciseStats,
    Map<String, dynamic>? conversationStats,
    Map<String, dynamic>? activityStreak,
    List<Map<String, dynamic>>? weeklyActivity,
  }) {
    return ProgressState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      healthScore: healthScore ?? this.healthScore,
      exerciseStats: exerciseStats ?? this.exerciseStats,
      conversationStats: conversationStats ?? this.conversationStats,
      activityStreak: activityStreak ?? this.activityStreak,
      weeklyActivity: weeklyActivity ?? this.weeklyActivity,
    );
  }
}

class ProgressNotifier extends StateNotifier<ProgressState> {
  final ApiService _apiService;
  final ProgressService _progressService = ProgressService();

  ProgressNotifier(this._apiService) : super(const ProgressState());

  Future<void> loadDashboard() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final token = await _apiService.getToken();
      if (token == null) {
        state = state.copyWith(isLoading: false, error: 'Not authenticated');
        return;
      }

      final data = await _progressService.getDashboard(token);

      final weeklyRaw = data['weeklyActivity'] as List<dynamic>? ?? [];
      final weeklyActivity = weeklyRaw
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();

      state = state.copyWith(
        isLoading: false,
        healthScore: data['healthScore'] ?? 0,
        exerciseStats: Map<String, dynamic>.from(data['exerciseStats'] ?? {}),
        conversationStats: Map<String, dynamic>.from(data['conversationStats'] ?? {}),
        activityStreak: Map<String, dynamic>.from(data['activityStreak'] ?? {}),
        weeklyActivity: weeklyActivity,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final progressProvider =
    StateNotifierProvider<ProgressNotifier, ProgressState>((ref) {
  final apiService = ref.read(apiServiceProvider);
  return ProgressNotifier(apiService);
});
