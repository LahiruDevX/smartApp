import 'package:flutter/material.dart';

import 'ui/login/admin_login_screen.dart';
import 'ui/login/teacher_login_screen.dart';
import 'ui/login/student_login_screen.dart';

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


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smart Classroom IoT',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6D5DF5),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF3F5FF),
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          foregroundColor: Color(0xFF0F172A),
          iconTheme: IconThemeData(color: Color(0xFF6D5DF5)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6D5DF5),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            textStyle: const TextStyle(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          hintStyle: TextStyle(color: Colors.black.withOpacity(0.35)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(color: Colors.black.withOpacity(0.08)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(
              color: const Color(0xFF6D5DF5).withOpacity(0.65),
            ),
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 10,
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          shadowColor: const Color(0x22000000),
        ),
      ),
      initialRoute: '/login/admin',
      routes: {
  '/login/admin': (_) => const AdminLoginScreen(),
  '/login/teacher': (_) => const TeacherLoginScreen(),
  '/login/student': (_) => const StudentLoginScreen(),

  '/dashboard': (_) => const DashboardScreen(),
  '/environmental': (_) => const EnvironmentalScreen(),
  '/device-control': (_) => const DeviceControlScreen(),
  '/attendance': (_) => const AttendanceScreen(),
  '/analytics': (_) => const AnalyticsScreen(),
  '/schedule': (_) => const ScheduleScreen(),

  '/ai-teacher': (_) => const AiTeacherScreen(),
  '/learning': (_) => const LearningScreen(),
  '/progress': (_) => const ProgressScreen(),
  '/ai-management': (_) => const AiManagementScreen(),
},

    );
  }
}
