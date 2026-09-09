import 'package:flutter/material.dart';
import '../../core/di/app_di.dart';
import 'smart_login_page.dart';

class AdminLoginScreen extends StatelessWidget {
  const AdminLoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SmartLoginPage(
      role: UserRole.admin,
      onQuickRoleTap: (role) {
        switch (role) {
          case UserRole.admin:
            break;
          case UserRole.teacher:
            Navigator.pushReplacementNamed(context, '/login/teacher');
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
                content: Text('Welcome back, Admin! ($email)'),
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
