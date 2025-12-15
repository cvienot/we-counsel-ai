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
import 'screens/home/home_screen.dart';
import 'screens/main_thread/main_thread_screen.dart';
import 'screens/conversations/conversation_list_screen.dart';
import 'screens/conversations/conversation_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/invite/invite_partner_screen.dart';
import 'screens/settings/language_selection_screen.dart';
import 'config/environment.dart';

void main() {
  // Print environment config for debugging
  Environment.printConfig();
  
  // Use path-based routing instead of hash-based routing
  setPathUrlStrategy();
  runApp(const ProviderScope(child: WeCounselApp()));
}

class WeCounselApp extends ConsumerWidget {
  const WeCounselApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = _createRouter(ref);
    final currentLocale = ref.watch(currentLocaleProvider);

    return MaterialApp.router(
      title: 'We Counsel',
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
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
        ),
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
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
      ),
      routerConfig: router,
    );
  }

  GoRouter _createRouter(WidgetRef ref) {
    return GoRouter(
      initialLocation: '/splash', // Start with splash to check auth
      debugLogDiagnostics: true,
      refreshListenable: _AuthStateNotifier(ref), // Listen to auth changes
      redirect: (context, state) {
        final authState = ref.read(authProvider);
        final location = state.uri.toString();
        final isLoginRoute = location == '/login';
        final isRegisterRoute = location == '/register';
        final isInvitationRoute = location.startsWith('/invitation/');
        final isSplashRoute = location == '/splash';

        print('🔀 ROUTER: Redirect check - location: $location, isAuth: ${authState.isAuthenticated}, isLoading: ${authState.isLoading}');

        // Allow invitation routes without authentication
        if (isInvitationRoute) {
          print('🔀 ROUTER: Allowing invitation route');
          return null;
        }

        // If still loading auth state, stay on splash
        if (authState.isLoading && !isSplashRoute) {
          print('🔀 ROUTER: Still loading, redirect to /splash');
          return '/splash';
        }

        // If done loading and not authenticated, go to login (unless already there)
        if (!authState.isLoading && !authState.isAuthenticated && !isLoginRoute && !isRegisterRoute) {
          print('🔀 ROUTER: Not authenticated, redirect to /login');
          return '/login';
        }

        // If authenticated and on auth/splash routes, redirect to home
        if (authState.isAuthenticated && (isLoginRoute || isRegisterRoute || isSplashRoute)) {
          print('🔀 ROUTER: Authenticated, redirect to /home');
          return '/home';
        }

        print('🔀 ROUTER: No redirect needed');
        return null;
      },
      routes: [
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
          path: '/home',
          builder: (context, state) => const HomeScreen(),
        ),
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
      ],
    );
  }
}

class _AuthStateNotifier extends ChangeNotifier {
  final WidgetRef _ref;

  _AuthStateNotifier(this._ref) {
    _ref.listen<AuthState>(authProvider, (previous, next) {
      print('🔔 AUTH STATE CHANGED: isAuth: ${next.isAuthenticated}, isLoading: ${next.isLoading}');
      notifyListeners();
    });
  }
}

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Listen to auth state changes to trigger navigation
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (!next.isLoading) {
        // Auth check is complete, router will handle navigation
      }
    });

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite,
              size: 80,
              color: Colors.white,
            ),
            const SizedBox(height: 24),
            Text(
              AppLocalizations.of(context)?.appTitle ?? 'We Counsel',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)?.appSubtitle ?? 'Your relationship journey together',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white.withOpacity(0.9),
              ),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
