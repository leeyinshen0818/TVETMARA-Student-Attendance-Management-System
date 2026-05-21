import 'package:flutter/material.dart';

import '../models/app_models.dart';
import '../state/app_scope.dart';
import 'admin/register_user_screen.dart';
import 'attendance_screen.dart';
import 'tempahan_screen.dart';
import 'disiplin_screen.dart';
import 'dashboard_screen.dart';
import 'records_screen.dart';
import 'reports_screen.dart';
import 'settings_screen.dart';
import 'timetable_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final user = state.currentUser!;

    // Role checks
    final isAdmin = user.role == UserRole.admin;
    final isKetuaProgram = user.role == UserRole.ketuaProgram;
    final isPensyarah = user.role == UserRole.pensyarah;

    // Build navigation items based strictly on role
    final items = <_NavItem>[
      // Dashboard is global to all users, but its interior will shape-shift later
      const _NavItem(
          'Papan Pemuka', Icons.dashboard_outlined, DashboardScreen()),

      // Attendance is strictly for Pensyarah (and maybe Ketua Program as they also teach)
      if (isPensyarah || isKetuaProgram)
        const _NavItem(
            'Kehadiran', Icons.fact_check_outlined, AttendanceScreen()),

      // Timetable Upload/View is mainly for academics, but Admin doesn't need it
      if (!isAdmin)
        const _NavItem(
            'Jadual', Icons.calendar_month_outlined, TimetableScreen()),

      // Reports are mostly for management (Admin, KJ, KP)
      if (!isPensyarah)
        const _NavItem('Laporan', Icons.bar_chart_outlined, ReportsScreen()),

      // Room Booking: Pensyarah creates, KP approves
      if (isPensyarah || isKetuaProgram)
        const _NavItem(
            'Tempahan Bilik', Icons.meeting_room_outlined, TempahanScreen()),

      // Discipline: Pensyarah creates, KJ approves
      if (isPensyarah || user.role == UserRole.ketuaJabatan)
        const _NavItem(
            'Laporan Disiplin', Icons.warning_amber_outlined, DisiplinScreen()),

      // Student Records are mainly for Academic checking
      if (!isAdmin)
        const _NavItem(
            'Rekod Pelajar', Icons.people_alt_outlined, RecordsScreen()),

      // Admin Only Modules
      if (isAdmin)
        const _NavItem(
            'Tetapan Sistem', Icons.settings_outlined, SettingsScreen()),
      if (isAdmin)
        const _NavItem(
            'Daftar Akaun', Icons.person_add_outlined, RegisterUserScreen()),
    ];
    if (index >= items.length) index = 0;
    final compact = MediaQuery.sizeOf(context).width < 780;

    return Scaffold(
      body: Row(
        children: [
          if (!compact) ...[
            Container(
              width: MediaQuery.sizeOf(context).width > 1120 ? 246 : 88,
              color: const Color(0xff0f172a),
              child: NavigationRail(
                backgroundColor: const Color(0xff0f172a),
                indicatorColor: const Color(0xffdbeafe),
                extended: MediaQuery.sizeOf(context).width > 1120,
                selectedIndex: index,
                selectedIconTheme:
                    const IconThemeData(color: Color(0xff1d4ed8)),
                unselectedIconTheme:
                    const IconThemeData(color: Color(0xffcbd5e1)),
                selectedLabelTextStyle: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w800),
                unselectedLabelTextStyle:
                    const TextStyle(color: Color(0xffcbd5e1)),
                onDestinationSelected: (value) => setState(() => index = value),
                leading: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: _BrandMark(
                      extended: MediaQuery.sizeOf(context).width > 1120),
                ),
                trailing: Expanded(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: IconButton(
                        tooltip: 'Log Keluar',
                        onPressed: state.logout,
                        icon:
                            const Icon(Icons.logout, color: Color(0xffcbd5e1)),
                      ),
                    ),
                  ),
                ),
                destinations: [
                  for (final item in items)
                    NavigationRailDestination(
                      icon: Icon(item.icon),
                      selectedIcon: Icon(item.icon),
                      label: Text(item.label),
                    ),
                ],
              ),
            ),
          ],
          Expanded(
            child: Column(
              children: [
                _TopBar(user: user, onLogout: compact ? state.logout : null),
                Expanded(
                  child: ColoredBox(
                    color: const Color(0xfff6f8fb),
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        compact ? 14 : 24,
                        22,
                        compact ? 14 : 24,
                        28,
                      ),
                      child: state.error != null
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: Text('Ralat memuat turun data: ${state.error}',
                                    style: const TextStyle(color: Colors.red)),
                              ),
                            )
                          : state.loading
                              ? const Center(child: CircularProgressIndicator())
                              : items[index].screen,
                    ),
                  ),
                ),
                if (compact)
                  NavigationBar(
                    selectedIndex: index,
                    onDestinationSelected: (value) =>
                        setState(() => index = value),
                    destinations: [
                      for (final item in items)
                        NavigationDestination(
                          icon: Icon(item.icon),
                          selectedIcon: Icon(item.icon),
                          label: item.label,
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.user, this.onLogout});

  final AppUser user;
  final VoidCallback? onLogout;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: 22),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xffe2e8f0))),
      ),
      child: Row(
        children: [
          const Icon(Icons.school_outlined, color: Color(0xff1d4ed8)),
          const SizedBox(width: 10),
          const Flexible(
            child: Text(
              'Sistem Kehadiran TVETMARA',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: Color(0xff0f172a),
              ),
            ),
          ),
          const Spacer(),
          const Text('Selasa, 19 Mei 2026',
              style: TextStyle(color: Color(0xff64748b))),
          const SizedBox(width: 16),
          Chip(
              label: Text(user.role == UserRole.admin
                  ? 'Pentadbir'
                  : user.role == UserRole.ketuaJabatan
                      ? 'Ketua Jabatan'
                      : user.role == UserRole.ketuaProgram
                          ? 'Ketua Program'
                          : 'Pensyarah')),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              user.name,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          if (onLogout != null) ...[
            const SizedBox(width: 6),
            IconButton(
              tooltip: 'Log Keluar',
              onPressed: onLogout,
              icon: const Icon(Icons.logout),
            ),
          ],
        ],
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark({required this.extended});

  final bool extended;

  @override
  Widget build(BuildContext context) {
    if (!extended) {
      return const CircleAvatar(
        backgroundColor: Color(0xffdbeafe),
        foregroundColor: Color(0xff1d4ed8),
        child: Icon(Icons.school),
      );
    }
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Color(0xffdbeafe),
            foregroundColor: Color(0xff1d4ed8),
            child: Icon(Icons.school),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'TVETMARA',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  const _NavItem(this.label, this.icon, this.screen);
  final String label;
  final IconData icon;
  final Widget screen;
}
