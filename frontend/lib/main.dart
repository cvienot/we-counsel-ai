import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_strategy/url_strategy.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';

import 'providers/auth_provider.dart';
import 'providers/language_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/invitation_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/auth/reset_password_screen.dart';
import 'screens/auth/terms_of_service_screen.dart';
import 'screens/auth/privacy_policy_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/main_thread/main_thread_screen.dart';
import 'screens/conversations/conversation_list_screen.dart';
import 'screens/conversations/conversation_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/invite/invite_partner_screen.dart';
import 'screens/settings/language_selection_screen.dart';
import 'screens/plan_selection_screen.dart';
import 'screens/settings/payment_portal_screen.dart';
import 'screens/settings/billing_history_screen.dart';
import 'screens/settings/payment_success_screen.dart';
import 'screens/exercises/exercise_loader_screen.dart';
import 'screens/exercises/exercise_history_screen.dart';
import 'screens/progress/progress_dashboard_screen.dart';
import 'config/environment.dart';
import 'services/analytics_service.dart';
import 'services/attribution_service.dart';
import 'utils/navigation_utils.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Print environment config for debugging
  Environment.printConfig();

  // Use path-based routing instead of hash-based routing
  setPathUrlStrategy();
  await AttributionService().captureCurrentUri();
  runApp(const ProviderScope(child: WeCounselApp()));
}

class WeCounselApp extends ConsumerWidget {
  const WeCounselApp({super.key});

  // Cache the router so locale changes don't recreate it (which would reset navigation)
  static GoRouter? _cachedRouter;
  static bool _appOpenTracked = false;

  /// Reset the cached router. Call between integration test cases.
  static void resetRouter() {
    _cachedRouter = null;
    _appOpenTracked = false;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    _cachedRouter ??= _createRouter(ref);
    final currentLocale = ref.watch(currentLocaleProvider);
    _trackAppOpenOnce(currentLocale.languageCode);

    return MaterialApp.router(
      title: 'Entrelace',
      locale: currentLocale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''),
        Locale('fr', ''),
        Locale('es', ''),
      ],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6B73FF),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(elevation: 0, centerTitle: true),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
      ),
      routerConfig: _cachedRouter!,
    );
  }

  GoRouter _createRouter(WidgetRef ref) {
    return GoRouter(
      initialLocation: '/splash', // Start with splash to check auth
      // Marketing links land on "/?utm_..." — initialLocation only applies
      // when the browser URL is exactly "/", so "/" must be a real route.
      onException: (context, state, router) => router.go('/splash'),
      debugLogDiagnostics: !Environment.isProduction,
      refreshListenable: _AuthStateNotifier(ref), // Listen to auth changes
      redirect: (context, state) {
        final authState = ref.read(authProvider);
        final location = state.uri.toString();
        final path = state.uri.path;
        final from = safeInternalRedirect(state.uri.queryParameters['from']);
        final isLoginRoute = path == '/login';
        final isRegisterRoute = path == '/register';
        final isInvitationRoute = path.startsWith('/invitation/');
        final isForgotPasswordRoute = path == '/forgot-password';
        final isResetPasswordRoute = path.startsWith('/reset-password/');
        final isLegalRoute = path == '/terms' || path == '/privacy';
        final isSplashRoute = path == '/splash';

        Environment.log(
          'ROUTER: Redirect check - location: $location, isAuth: ${authState.isAuthenticated}, isLoading: ${authState.isLoading}',
        );

        // Allow invitation and password reset routes without authentication
        if (isInvitationRoute ||
            isForgotPasswordRoute ||
            isResetPasswordRoute ||
            isLegalRoute) {
          Environment.log('ROUTER: Allowing public route');
          return null;
        }

        if (isSplashRoute) {
          if (authState.isLoading) return null;

          if (authState.isAuthenticated) {
            Environment.log('ROUTER: Authenticated from splash');
            return from ?? '/main-thread';
          }

          Environment.log('ROUTER: Unauthenticated from splash');
          return routeWithFrom('/login', from);
        }

        // If still loading auth state, keep the requested URL stable. The
        // destination screen can show its own loading state until auth settles.
        if (authState.isLoading && !isLoginRoute && !isRegisterRoute) {
          Environment.log('ROUTER: Still loading, preserving current route');
          return null;
        }

        // If done loading and not authenticated, go to login (unless already there)
        if (!authState.isLoading &&
            !authState.isAuthenticated &&
            !isLoginRoute &&
            !isRegisterRoute) {
          Environment.log('ROUTER: Not authenticated, redirect to /login');
          return routeWithFrom('/login', location);
        }

        // If authenticated and on auth routes, redirect to the requested page.
        if (authState.isAuthenticated && (isLoginRoute || isRegisterRoute)) {
          Environment.log('ROUTER: Authenticated, leaving auth route');
          return from ?? '/main-thread';
        }

        Environment.log('ROUTER: No redirect needed');
        return null;
      },
      routes: [
        GoRoute(path: '/', redirect: (context, state) => '/splash'),
        GoRoute(
          path: '/splash',
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) => const RegisterScreen(),
        ),
        GoRoute(
          path: '/invitation/:id',
          builder: (context, state) {
            final invitationId = state.pathParameters['id']!;
            return InvitationScreen(invitationId: invitationId);
          },
        ),
        GoRoute(
          path: '/forgot-password',
          builder: (context, state) => const ForgotPasswordScreen(),
        ),
        GoRoute(
          path: '/reset-password/:token',
          builder: (context, state) {
            final token = state.pathParameters['token']!;
            return ResetPasswordScreen(token: token);
          },
        ),
        GoRoute(
          path: '/terms',
          builder: (context, state) => const TermsOfServiceScreen(),
        ),
        GoRoute(
          path: '/privacy',
          builder: (context, state) => const PrivacyPolicyScreen(),
        ),
        GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
        GoRoute(
          path: '/main-thread',
          builder: (context, state) => const MainThreadScreen(),
        ),
        GoRoute(
          path: '/conversations',
          builder: (context, state) => const ConversationListScreen(),
        ),
        GoRoute(
          path: '/conversation/:id',
          builder: (context, state) {
            final conversationId = state.pathParameters['id']!;
            return ConversationScreen(conversationId: conversationId);
          },
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
        ),
        GoRoute(
          path: '/invite',
          builder: (context, state) => const InvitePartnerScreen(),
        ),
        GoRoute(
          path: '/dashboard',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/language',
          builder: (context, state) => const LanguageSelectionScreen(),
        ),
        GoRoute(
          path: '/plan-selection',
          builder: (context, state) => const PlanSelectionScreen(),
        ),
        GoRoute(
          path: '/payment-portal',
          builder: (context, state) => const PaymentPortalScreen(),
        ),
        GoRoute(
          path: '/billing-history',
          builder: (context, state) => const BillingHistoryScreen(),
        ),
        GoRoute(
          path: '/payment/success',
          builder: (context, state) => const PaymentSuccessScreen(),
        ),
        GoRoute(
          path: '/exercise-history',
          builder: (context, state) => const ExerciseHistoryScreen(),
        ),
        GoRoute(
          path: '/progress',
          builder: (context, state) => const ProgressDashboardScreen(),
        ),
        GoRoute(
          path: '/exercise',
          builder: (context, state) {
            final args = state.extra as Map<String, dynamic>?;
            final conversationId = args?['conversationId'] as String?;
            final exerciseId = args?['exerciseId'] as String?;

            if (conversationId == null || exerciseId == null) {
              // Redirect to conversation if required parameters are missing
              WidgetsBinding.instance.addPostFrameCallback((_) {
                context.go('/main-thread');
              });
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            return ExerciseLoaderScreen(
              conversationId: conversationId,
              exerciseId: exerciseId,
            );
          },
        ),
      ],
    );
  }

  void _trackAppOpenOnce(String language) {
    if (_appOpenTracked) return;
    _appOpenTracked = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      AnalyticsService.trackAppOpen(
        language: language,
        entryPath: Uri.base.path.isEmpty ? '/' : Uri.base.path,
      );
    });
  }
}

class _AuthStateNotifier extends ChangeNotifier {
  final WidgetRef _ref;

  _AuthStateNotifier(this._ref) {
    _ref.listen<AuthState>(authProvider, (previous, next) {
      Environment.log(
        'AUTH STATE CHANGED: isAuth: ${next.isAuthenticated}, isLoading: ${next.isLoading}',
      );
      notifyListeners();
    });
  }
}

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  Timer? _recoveryTimer;
  bool _showRecoveryActions = false;

  @override
  void initState() {
    super.initState();
    _startRecoveryTimer();
  }

  @override
  void dispose() {
    _recoveryTimer?.cancel();
    super.dispose();
  }

  void _startRecoveryTimer() {
    _recoveryTimer?.cancel();
    _showRecoveryActions = false;
    _recoveryTimer = Timer(const Duration(seconds: 12), () {
      if (mounted && ref.read(authProvider).isLoading) {
        setState(() => _showRecoveryActions = true);
      }
    });
  }

  Future<void> _retrySessionCheck() async {
    setState(() => _showRecoveryActions = false);
    _startRecoveryTimer();
    await ref.read(authProvider.notifier).checkAuthStatus();
  }

  Future<void> _signInAgain() async {
    await ref.read(authProvider.notifier).logout();
    if (mounted) {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to auth state changes to trigger navigation
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (!next.isLoading) {
        // Auth check is complete, router will handle navigation
      }
    });
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite, size: 80, color: Colors.white),
            const SizedBox(height: 24),
            Text(
              AppLocalizations.of(context)?.appTitle ?? 'Entrelace',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)?.appSubtitle ??
                  'Your relationship journey together',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            if (_showRecoveryActions) ...[
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  l10n?.startupTakingLong ??
                      'This is taking longer than expected.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  l10n?.startupTakingLongHelp ??
                      'You can retry the session check or sign in again.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 8,
                children: [
                  OutlinedButton(
                    onPressed: _retrySessionCheck,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white),
                    ),
                    child: Text(l10n?.retry ?? 'Retry'),
                  ),
                  FilledButton(
                    onPressed: _signInAgain,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Theme.of(context).colorScheme.primary,
                    ),
                    child: Text(l10n?.signInAgain ?? 'Sign in again'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
