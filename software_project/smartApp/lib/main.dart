import 'package:flutter/material.dart';

import 'core/di/app_di.dart';
import 'features/auth/auth_service.dart';

import 'ui/login/admin_login_screen.dart';
import 'ui/login/teacher_login_screen.dart';
import 'ui/login/student_login_screen.dart';
import 'ui/login/register_screen.dart';

import 'ui/pages/dashboard_screen.dart';
import 'ui/pages/environmental_screen.dart';
import 'ui/pages/device_control_screen.dart';
import 'ui/pages/attendance_screen.dart';
import 'ui/pages/ai_teacher_screen.dart';
import 'ui/pages/learning_screen.dart';
import 'ui/pages/progress_screen.dart';
import 'ui/pages/ai_management_screen.dart';
import 'ui/pages/analytics_screen.dart';
import 'ui/pages/schedule_screen.dart';
import 'ui/pages/students_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  /// Wraps a screen so it can only be viewed while logged in. If there is no
  /// authenticated user (including a manual URL like /dashboard on web), it
  /// shows the login screen instead.
  static Widget _guarded(Widget page) => _AuthGuard(child: page);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smart Classroom IoT',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2D66F6)),
        scaffoldBackgroundColor: const Color(0xFFF6F9FF),
      ),
      home: const _AuthGate(),
      routes: {
        '/login/admin': (_) => const AdminLoginScreen(),
        '/login/teacher': (_) => const TeacherLoginScreen(),
        '/login/student': (_) => const StudentLoginScreen(),
        '/register': (_) => const RegisterScreen(),

        '/dashboard': (_) => _guarded(const DashboardScreen()),
        '/environmental': (_) => _guarded(const EnvironmentalScreen()),
        '/device-control': (_) => _guarded(const DeviceControlScreen()),
        '/attendance': (_) => _guarded(const AttendanceScreen()),
        '/students': (_) => _guarded(const StudentsScreen()),
        '/analytics': (_) => _guarded(const AnalyticsScreen()),
        '/schedule': (_) => _guarded(const ScheduleScreen()),

        '/ai-teacher': (_) => _guarded(const AiTeacherScreen()),
        '/learning': (_) => _guarded(const LearningScreen()),
        '/progress': (_) => _guarded(const ProgressScreen()),
        '/ai-management': (_) => _guarded(const AiManagementScreen()),
      },
    );
  }
}

/// Shown first. Restores any existing session, then routes to the dashboard
/// (already logged in) or the login screen.
class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  late final Future<void> _boot = authService.restoreSession();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _boot,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return ValueListenableBuilder<AuthUser?>(
          valueListenable: authService.user,
          builder: (context, user, _) {
            return user == null
                ? const AdminLoginScreen()
                : const DashboardScreen();
          },
        );
      },
    );
  }
}

class _AuthGuard extends StatelessWidget {
  const _AuthGuard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AuthUser?>(
      valueListenable: authService.user,
      builder: (context, user, _) {
        if (user == null) return const AdminLoginScreen();
        return child;
      },
    );
  }
}
