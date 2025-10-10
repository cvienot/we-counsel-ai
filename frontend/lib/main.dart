import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_strategy/url_strategy.dart';

import 'providers/auth_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/invitation_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/main_thread/main_thread_screen.dart';
import 'screens/conversations/conversation_list_screen.dart';
import 'screens/conversations/conversation_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/invite/invite_partner_screen.dart';

void main() {
  // Use path-based routing instead of hash-based routing
  setPathUrlStrategy();
  runApp(const ProviderScope(child: WeCounselApp()));
}

class WeCounselApp extends ConsumerWidget {
  const WeCounselApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = _createRouter(ref);

    return MaterialApp.router(
      title: 'We Counsel',
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
      initialLocation: '/login',
      debugLogDiagnostics: true,
      redirect: (context, state) {
        final isAuthenticated = ref.read(isAuthenticatedProvider);
        final location = state.uri.toString();
        final isLoginRoute = location == '/login';
        final isRegisterRoute = location == '/register';
        final isInvitationRoute = location.startsWith('/invitation/');

        // Allow invitation routes without authentication
        if (isInvitationRoute) {
          return null;
        }

        // If not authenticated and not on auth routes, redirect to login
        if (!isAuthenticated && !isLoginRoute && !isRegisterRoute) {
          return '/login';
        }

        // If authenticated and on auth routes, redirect to home
        if (isAuthenticated && (isLoginRoute || isRegisterRoute)) {
          return '/home';
        }

        return null;
      },
      routes: [
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
      ],
    );
  }
}
