//slide bar + layout

/*import 'package:flutter/material.dart';

class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.title,
    required this.subtitle,
    required this.selectedRoute,
    required this.body,
    this.actions,
  });

  final String title;
  final String subtitle;
  final String selectedRoute;
  final Widget body;
  final List<Widget>? actions;

  static const _sidebarWidth = 260.0;

  bool _isWide(BuildContext context) =>
      MediaQuery.of(context).size.width >= 980;

  @override
  Widget build(BuildContext context) {
    final wide = _isWide(context);

    final sidebar = _Sidebar(
      selectedRoute: selectedRoute,
      onNavigate: (route) {
        if (ModalRoute.of(context)?.settings.name == route) return;
        Navigator.pushReplacementNamed(context, route);
      },
    );

    return Scaffold(
      drawer: wide ? null : Drawer(child: SafeArea(child: sidebar)),
      body: SafeArea(
        child: Row(
          children: [
            if (wide)
              SizedBox(
                width: _sidebarWidth,
                child: sidebar,
              ),
            Expanded(
              child: Column(
                children: [
                  _TopBar(
                    title: title,
                    subtitle: subtitle,
                    showMenu: !wide,
                    actions: actions,
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
                      child: body,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.title,
    required this.subtitle,
    required this.showMenu,
    this.actions,
  });

  final String title;
  final String subtitle;
  final bool showMenu;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        border: Border(
          bottom: BorderSide(color: Colors.black.withOpacity(0.06)),
        ),
      ),
      child: Row(
        children: [
          if (showMenu)
            IconButton(
              onPressed: () => Scaffold.of(context).openDrawer(),
              icon: const Icon(Icons.menu),
            ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    )),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black.withOpacity(0.55),
                    )),
              ],
            ),
          ),
          ...(actions ?? []),
          const SizedBox(width: 6),
          _UserPill(),
        ],
      ),
    );
  }
}

class _UserPill extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F6FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 12,
            backgroundColor: Color(0xFF2D66F6),
            child: Icon(Icons.person, size: 14, color: Colors.white),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Admin User',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              Text('admin',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.black.withOpacity(0.55),
                  )),
            ],
          ),
          const SizedBox(width: 10),
          Icon(Icons.logout, size: 18, color: Colors.red.withOpacity(0.85)),
        ],
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.selectedRoute, required this.onNavigate});

  final String selectedRoute;
  final void Function(String route) onNavigate;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF6F9FF), Color(0xFFFFFFFF)],
        ),
        border: Border(
          right: BorderSide(color: Colors.black.withOpacity(0.04)),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2D66F6), Color(0xFF5B99FF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 18,
                        offset: const Offset(0, 10),
                        color: Colors.black.withOpacity(0.08),
                      )
                    ],
                  ),
                  child: const Icon(Icons.grid_view_rounded, color: Colors.white),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Smart Classroom',
                          style: TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF0F172A))),
                      SizedBox(height: 2),
                      Text('IoT Management',
                          style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _NavItem(
            icon: Icons.dashboard_outlined,
            label: 'Dashboard',
            selected: selectedRoute == '/dashboard',
            onTap: () => onNavigate('/dashboard'),
          ),
          _NavItem(
            icon: Icons.thermostat_outlined,
            label: 'Environmental',
            selected: selectedRoute == '/environmental',
            onTap: () => onNavigate('/environmental'),
          ),
          _NavItem(
            icon: Icons.power_settings_new,
            label: 'Device Control',
            selected: selectedRoute == '/device-control',
            onTap: () => onNavigate('/device-control'),
          ),
          _NavItem(
            icon: Icons.how_to_reg_outlined,
            label: 'Attendance',
            selected: selectedRoute == '/attendance',
            onTap: () => onNavigate('/attendance'),
          ),
          _NavItem(
              icon: Icons.query_stats_outlined,
              label: 'Analytics',
              selected: selectedRoute == '/analytics',
              onTap: () => onNavigate('/analytics')),
          _NavItem(
              icon: Icons.calendar_month_outlined,
              label: 'Schedule',
              selected: selectedRoute == '/schedule',
              onTap: () => onNavigate('/schedule')),
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'AI TEACHING ASSISTANT',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.black.withOpacity(0.45),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          _NavItem(
              icon: Icons.smart_toy_outlined,
              label: 'AI Teacher',
              selected: selectedRoute == '/ai-teacher',
              onTap: () => onNavigate('/ai-teacher')),
          _NavItem(
              icon: Icons.menu_book_outlined,
              label: 'Learning',
              selected: selectedRoute == '/learning',
              onTap: () => onNavigate('/learning')),
          _NavItem(
              icon: Icons.trending_up_outlined,
              label: 'Progress',
              selected: selectedRoute == '/progress',
              onTap: () => onNavigate('/progress')),
          _NavItem(
            icon: Icons.settings_suggest_outlined,
            label: 'AI Management',
            selected: selectedRoute == '/ai-management',
            onTap: () => onNavigate('/ai-management'),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF1FF),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.black.withOpacity(0.05)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('System Status',
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.circle, size: 10, color: Colors.green),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'All systems operational',
                          style: TextStyle(
                              fontSize: 11,
                              color: Colors.black.withOpacity(0.6)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = selected ? const Color(0xFFEAF1FF) : Colors.transparent;
    final fg = selected ? const Color(0xFF2D66F6) : const Color(0xFF334155);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(icon, size: 20, color: fg),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700, color: fg),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
*/
//after overflow sloving
import 'package:flutter/material.dart';
import '../../core/di/app_di.dart';

class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.title,
    required this.subtitle,
    required this.selectedRoute,
    required this.body,
    this.actions,
  });

  final String title;
  final String subtitle;
  final String selectedRoute;
  final Widget body;
  final List<Widget>? actions;

  static const _sidebarWidth = 260.0;

  bool _isWide(BuildContext context) =>
      MediaQuery.of(context).size.width >= 980;

  @override
  Widget build(BuildContext context) {
    final wide = _isWide(context);

    final sidebar = _Sidebar(
      selectedRoute: selectedRoute,
      onNavigate: (route) {
        if (ModalRoute.of(context)?.settings.name == route) return;
        Navigator.pushReplacementNamed(context, route);
      },
    );

    return Scaffold(
      drawer: wide ? null : Drawer(child: SafeArea(child: sidebar)),
      body: SafeArea(
        child: Row(
          children: [
            if (wide)
              SizedBox(
                width: _sidebarWidth,
                child: sidebar,
              ),
            Expanded(
              child: Column(
                children: [
                  _TopBar(
                    title: title,
                    subtitle: subtitle,
                    showMenu: !wide,
                    actions: actions,
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
                      child: body,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.title,
    required this.subtitle,
    required this.showMenu,
    this.actions,
  });

  final String title;
  final String subtitle;
  final bool showMenu;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 78,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(22),
          bottomRight: Radius.circular(22),
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: 24,
            offset: const Offset(0, 10),
            color: Colors.black.withOpacity(0.08),
          ),
        ],
      ),
      child: Row(
        children: [
          if (showMenu)
            Builder(
              builder: (context) => IconButton(
                onPressed: () => Scaffold.of(context).openDrawer(),
                icon: const Icon(Icons.menu),
              ),
            ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black.withOpacity(0.55),
                  ),
                ),
              ],
            ),
          ),
          ...(actions ?? []),
          const SizedBox(width: 8),
          _UserPill(),
        ],
      ),
    );
  }
}

class _UserPill extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final email = apiClient.currentEmail ?? 'admin@classroom.com';
    final role = apiClient.currentRole ?? 'admin';
    final displayName = email.split('@').first;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () async {
        await authService.logout();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Logged out successfully')),
          );
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/login/admin',
            (route) => false,
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F6FF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black.withOpacity(0.06)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 12,
              backgroundColor: role == 'teacher'
                  ? const Color(0xFF16A34A)
                  : (role == 'student' ? const Color(0xFF7C3AED) : const Color(0xFF2D66F6)),
              child: const Icon(Icons.person, size: 14, color: Colors.white),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  displayName,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
                Text(
                  role.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Colors.black.withOpacity(0.55),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),
            Icon(Icons.logout, size: 18, color: Colors.red.withOpacity(0.85)),
          ],
        ),
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.selectedRoute, required this.onNavigate});

  final String selectedRoute;
  final void Function(String route) onNavigate;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF5F7FF), Color(0xFFFFFFFF)],
        ),
        border: Border(
          right: BorderSide(color: Colors.black.withOpacity(0.04)),
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          children: [
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2D66F6), Color(0xFF5B99FF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          blurRadius: 18,
                          offset: const Offset(0, 10),
                          color: Colors.black.withOpacity(0.08),
                        )
                      ],
                    ),
                    child: const Icon(Icons.grid_view_rounded,
                        color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Smart Classroom',
                            style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                                color: Color(0xFF0F172A))),
                        SizedBox(height: 2),
                        Text('IoT Management',
                            style: TextStyle(
                                fontSize: 11, color: Color(0xFF64748B))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            _NavItem(
              icon: Icons.dashboard_outlined,
              label: 'Dashboard',
              selected: selectedRoute == '/dashboard',
              onTap: () => onNavigate('/dashboard'),
            ),
            _NavItem(
              icon: Icons.thermostat_outlined,
              label: 'Environmental',
              selected: selectedRoute == '/environmental',
              onTap: () => onNavigate('/environmental'),
            ),
            _NavItem(
              icon: Icons.power_settings_new,
              label: 'Device Control',
              selected: selectedRoute == '/device-control',
              onTap: () => onNavigate('/device-control'),
            ),
            _NavItem(
              icon: Icons.how_to_reg_outlined,
              label: 'Attendance',
              selected: selectedRoute == '/attendance',
              onTap: () => onNavigate('/attendance'),
            ),
            _NavItem(
              icon: Icons.query_stats_outlined,
              label: 'Analytics',
              selected: selectedRoute == '/analytics',
              onTap: () => onNavigate('/analytics'),
            ),
            _NavItem(
              icon: Icons.calendar_month_outlined,
              label: 'Schedule',
              selected: selectedRoute == '/schedule',
              onTap: () => onNavigate('/schedule'),
            ),

            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'AI TEACHING ASSISTANT',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.black.withOpacity(0.45),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),

            _NavItem(
              icon: Icons.smart_toy_outlined,
              label: 'AI Teacher',
              selected: selectedRoute == '/ai-teacher',
              onTap: () => onNavigate('/ai-teacher'),
            ),
            _NavItem(
              icon: Icons.menu_book_outlined,
              label: 'Learning',
              selected: selectedRoute == '/learning',
              onTap: () => onNavigate('/learning'),
            ),
            _NavItem(
              icon: Icons.trending_up_outlined,
              label: 'Progress',
              selected: selectedRoute == '/progress',
              onTap: () => onNavigate('/progress'),
            ),
            _NavItem(
              icon: Icons.settings_suggest_outlined,
              label: 'AI Management',
              selected: selectedRoute == '/ai-management',
              onTap: () => onNavigate('/ai-management'),
            ),

            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF1FF),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.black.withOpacity(0.05)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('System Status',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.circle, size: 10, color: Colors.green),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'All systems operational',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.black.withOpacity(0.6),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = selected ? const Color(0xFFE9EDFF) : const Color(0xFFF8FAFF);
    final fg = selected ? const Color(0xFF5C6ACB) : const Color(0xFF334155);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: selected ? const Color(0xFFDBE0FF) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, size: 18, color: fg),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: fg,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
