import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/theme/app_theme.dart';
import 'features/attendance/presentation/session_detail_screen.dart';
import 'features/attendance/presentation/take_attendance_screen.dart';
import 'features/auth/presentation/forgot_password_screen.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/auth/presentation/register_screen.dart';
import 'features/auth/presentation/splash_screen.dart';
import 'features/courses/presentation/course_detail_screen.dart';
import 'features/courses/presentation/dashboard_screen.dart';
import 'features/courses/presentation/create_course_screen.dart';
import 'features/hardware/presentation/hardware_settings_screen.dart';
import 'features/reports/presentation/report_screen.dart';
import 'shared/providers/auth_provider.dart';

final _routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authNotifierProvider);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: _AuthChangeNotifier(ref),
    redirect: (context, state) {
      final isLoading = authState.isLoading;
      final isLoggedIn = authState.valueOrNull != null;
      final isSplash = state.matchedLocation == '/splash';
      final isAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register' ||
          state.matchedLocation == '/forgot-password';

      // While loading, stay on splash
      if (isLoading && isSplash) return null;

      // Once auth resolves, leave splash
      if (isSplash) {
        return isLoggedIn ? '/dashboard' : '/login';
      }

      // If not logged in and not on auth route, redirect to login
      if (!isLoggedIn && !isAuthRoute) return '/login';

      // If logged in and on auth route, redirect to dashboard
      if (isLoggedIn && isAuthRoute) return '/dashboard';

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
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/courses/create',
        builder: (context, state) => const CreateCourseScreen(),
      ),
      GoRoute(
        path: '/courses/:courseId',
        builder: (context, state) {
          final courseId = state.pathParameters['courseId']!;
          return CourseDetailScreen(courseId: courseId);
        },
        routes: [
          GoRoute(
            path: 'attendance/new',
            builder: (context, state) {
              final courseId = state.pathParameters['courseId']!;
              return TakeAttendanceScreen(courseId: courseId);
            },
          ),
          GoRoute(
            path: 'sessions/:sessionId',
            builder: (context, state) {
              final courseId = state.pathParameters['courseId']!;
              final sessionId = state.pathParameters['sessionId']!;
              return SessionDetailScreen(
                sessionId: sessionId,
                courseId: courseId,
              );
            },
          ),
          GoRoute(
            path: 'reports',
            builder: (context, state) {
              final courseId = state.pathParameters['courseId']!;
              return ReportScreen(courseId: courseId);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/settings/hardware',
        builder: (context, state) => const HardwareSettingsScreen(),
      ),
    ],
  );
});

/// Notifier to force GoRouter to re-evaluate redirect when auth changes
class _AuthChangeNotifier extends ChangeNotifier {
  _AuthChangeNotifier(this._ref) {
    _ref.listen(authNotifierProvider, (_, __) {
      notifyListeners();
    });
  }

  final Ref _ref;
}

class SmartAttendanceApp extends ConsumerWidget {
  const SmartAttendanceApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(_routerProvider);

    return MaterialApp.router(
      title: 'KUET Smart Attendance',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
