import 'package:flutter/material.dart';

enum UserRole { admin, teacher, student }

extension UserRoleX on UserRole {
  String get label {
    switch (this) {
      case UserRole.admin:
        return 'Admin';
      case UserRole.teacher:
        return 'Teacher';
      case UserRole.student:
        return 'Student';
    }
  }

  String get defaultEmail {
    switch (this) {
      case UserRole.admin:
        return 'admin@classroom.com';
      case UserRole.teacher:
        return 'teacher@classroom.com';
      case UserRole.student:
        return 'student@classroom.com';
    }
  }
}

class SmartLoginPage extends StatefulWidget {
  const SmartLoginPage({
    super.key,
    required this.role,
    this.onSignIn,
    this.onQuickRoleTap,
  });

  final UserRole role;
  final Future<void> Function(String email, String password, UserRole role)?
  onSignIn;
  final void Function(UserRole role)? onQuickRoleTap;
    

  @override
  State<SmartLoginPage> createState() => _SmartLoginPageState();
}

class _SmartLoginPageState extends State<SmartLoginPage> {
  late final TextEditingController _email;
  late final TextEditingController _password;

  bool _obscure = true;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _email = TextEditingController(text: widget.role.defaultEmail);
    _password = TextEditingController();
  }

  @override
  void didUpdateWidget(covariant SmartLoginPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.role != widget.role) {
      _email.text = widget.role.defaultEmail;
      _password.clear();
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    final email = _email.text.trim();
    final pass = _password.text;

    if (email.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter email and password')),
      );
      return;
    }

    if (widget.onSignIn == null) return;

    setState(() => _loading = true);
    try {
      await widget.onSignIn!(email, pass, widget.role);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF2D66F6);
    const accentBlue = Color(0xFF5B99FF);
    const background = Color(0xFFF4F7FF);

    return Scaffold(
      backgroundColor: background,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFEFF4FF), Color(0xFFFDFDFF)],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -80,
              left: -60,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accentBlue.withOpacity(0.14),
                ),
              ),
            ),
            Positioned(
              bottom: -90,
              right: -70,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primaryBlue.withOpacity(0.12),
                ),
              ),
            ),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                blurRadius: 26,
                                offset: const Offset(0, 14),
                                color: Colors.black.withOpacity(0.08),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [Color(0xFF2D66F6), Color(0xFF5B99FF)],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(
                                  Icons.lightbulb_outlined,
                                  color: Colors.white,
                                  size: 26,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    Text(
                                      'Welcome back!',
                                      style: TextStyle(
                                        fontSize: 19,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                    SizedBox(height: 6),
                                    Text(
                                      'Sign in to the Smart Classroom dashboard',
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        color: Color(0xFF475569),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                blurRadius: 30,
                                offset: const Offset(0, 18),
                                color: Colors.black.withOpacity(0.08),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.role.label.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.2,
                                  color: Color(0xFF2D66F6),
                                ),
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'Smart Classroom IoT',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Intelligent classroom management system',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.black.withOpacity(0.55),
                                ),
                              ),
                              const SizedBox(height: 24),
                              const _FieldLabel('Email Address'),
                              const SizedBox(height: 8),
                              _AppTextField(
                                controller: _email,
                                hintText: 'email@example.com',
                                keyboardType: TextInputType.emailAddress,
                              ),
                              const SizedBox(height: 18),
                              const _FieldLabel('Password'),
                              const SizedBox(height: 8),
                              _AppTextField(
                                controller: _password,
                                hintText: 'Enter your password',
                                obscureText: _obscure,
                                suffix: IconButton(
                                  onPressed: () => setState(() => _obscure = !_obscure),
                                  icon: Icon(
                                    _obscure ? Icons.visibility_off : Icons.visibility,
                                  ),
                                  color: Colors.black.withOpacity(0.45),
                                ),
                              ),
                              const SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: ElevatedButton.icon(
                                  onPressed: _loading ? null : _handleSignIn,
                                  icon: const Icon(Icons.login, size: 18),
                                  label: Text(_loading ? 'Signing in...' : 'Sign In'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryBlue,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    textStyle: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              const Divider(height: 1.5),
                              const SizedBox(height: 18),
                              Text(
                                'Quick Login',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.black.withOpacity(0.55),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: _QuickRoleButton(
                                      text: 'Admin',
                                      selected: widget.role == UserRole.admin,
                                      onTap: () => widget.onQuickRoleTap?.call(
                                        UserRole.admin,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _QuickRoleButton(
                                      text: 'Teacher',
                                      selected: widget.role == UserRole.teacher,
                                      onTap: () => widget.onQuickRoleTap?.call(
                                        UserRole.teacher,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _QuickRoleButton(
                                      text: 'Student',
                                      selected: widget.role == UserRole.student,
                                      onTap: () => widget.onQuickRoleTap?.call(
                                        UserRole.student,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 11.5,
        fontWeight: FontWeight.w600,
        color: Colors.black.withOpacity(0.7),
      ),
    );
  }
}

class _AppTextField extends StatelessWidget {
  const _AppTextField({
    required this.controller,
    required this.hintText,
    this.keyboardType,
    this.obscureText = false,
    this.suffix,
  });

  final TextEditingController controller;
  final String hintText;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    final prefixIcon = obscureText
        ? const Icon(Icons.lock_outline, color: Color(0xFF64748B))
        : keyboardType == TextInputType.emailAddress
            ? const Icon(Icons.email_outlined, color: Color(0xFF64748B))
            : null;

    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.black.withOpacity(0.3)),
        filled: true,
        fillColor: const Color(0xFFF8FAFF),
        suffixIcon: suffix,
        prefixIcon: prefixIcon,
        prefixIconColor: const Color(0xFF64748B),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 16,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.black.withOpacity(0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: const Color(0xFF2D66F6).withOpacity(0.65),
          ),
        ),
      ),
    );
  }
}

class _QuickRoleButton extends StatelessWidget {
  const _QuickRoleButton({
    required this.text,
    required this.onTap,
    required this.selected,
  });

  final String text;
  final VoidCallback? onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: Material(
        color: selected ? const Color(0xFFEAF1FF) : const Color(0xFFF3F6FA),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected
                    ? const Color(0xFF2D66F6)
                    : Colors.black.withOpacity(0.7),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
