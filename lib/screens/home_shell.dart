import 'package:flutter/material.dart';

import '../models/app_models.dart';
import '../state/app_scope.dart';
import 'attendance_screen.dart';
import 'bookings_screen.dart';
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
    final admin = user.role == UserRole.admin;
    final items = <_NavItem>[
      const _NavItem('Dashboard', Icons.dashboard_outlined, DashboardScreen()),
      if (!admin) const _NavItem('Attendance', Icons.fact_check_outlined, AttendanceScreen()),
      const _NavItem('Timetable', Icons.calendar_month_outlined, TimetableScreen()),
      const _NavItem('Reports', Icons.bar_chart_outlined, ReportsScreen()),
      const _NavItem('Discipline / Booking', Icons.warning_amber_outlined, BookingsScreen()),
      const _NavItem('Records', Icons.people_alt_outlined, RecordsScreen()),
      if (admin) const _NavItem('Settings', Icons.settings_outlined, SettingsScreen()),
    ];
    if (index >= items.length) index = 0;

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            extended: MediaQuery.sizeOf(context).width > 1000,
            selectedIndex: index,
            onDestinationSelected: (value) => setState(() => index = value),
            leading: const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Icon(Icons.school, size: 32),
            ),
            trailing: Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: IconButton(
                    tooltip: 'Logout',
                    onPressed: state.logout,
                    icon: const Icon(Icons.logout),
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
          const VerticalDivider(width: 1),
          Expanded(
            child: Column(
              children: [
                _TopBar(user: user),
                Expanded(
                  child: ColoredBox(
                    color: const Color(0xfff8fafc),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: items[index].screen,
                    ),
                  ),
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
  const _TopBar({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xffe5e7eb))),
      ),
      child: Row(
        children: [
          const Text('TVETMARA Attendance System', style: TextStyle(fontWeight: FontWeight.bold)),
          const Spacer(),
          const Text('Wednesday, 29 Apr 2026'),
          const SizedBox(width: 16),
          Chip(label: Text(user.role == UserRole.admin ? 'Admin' : 'Lecturer')),
          const SizedBox(width: 8),
          Text(user.name, style: const TextStyle(fontWeight: FontWeight.w600)),
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
