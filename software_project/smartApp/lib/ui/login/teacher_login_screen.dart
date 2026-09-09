import 'package:flutter/material.dart';
import '../../core/di/app_di.dart';
import 'smart_login_page.dart';

class TeacherLoginScreen extends StatelessWidget {
  const TeacherLoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SmartLoginPage(
      role: UserRole.teacher,
      onQuickRoleTap: (role) {
        switch (role) {
          case UserRole.admin:
            Navigator.pushReplacementNamed(context, '/login/admin');
            break;
          case UserRole.teacher:
            break;
          case UserRole.student:
            Navigator.pushReplacementNamed(context, '/login/student');
            break;
        }
      },
      onSignIn: (email, password, role) async {
        try {
          await authService.login(email: email, password: password);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Welcome, Teacher! ($email)'),
                backgroundColor: const Color(0xFF16A34A),
                duration: const Duration(seconds: 2),
              ),
            );
            Navigator.pushReplacementNamed(context, '/dashboard');
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Login Failed: $e'),
                backgroundColor: const Color(0xFFDC2626),
              ),
            );
          }
        }
      },
    );
  }
}
