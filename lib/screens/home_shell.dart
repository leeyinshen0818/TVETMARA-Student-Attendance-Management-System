import 'package:flutter/material.dart';

import '../models/app_models.dart';
import '../state/app_scope.dart';
import '../state/app_state.dart';
import '../widgets/app_theme.dart';
import '../widgets/mobile_components.dart';
import '../widgets/responsive.dart';
import 'admin/register_user_screen.dart';
import 'attendance_screen.dart';
import 'tempahan_screen.dart';
import 'disiplin_screen.dart';
import 'dashboard_screen.dart';
import 'records_screen.dart';
import 'reports_screen.dart';
import 'timetable_screen.dart';
// import 'admin/admin_timetable_viewer_screen.dart';
import 'admin/admin_user_management_screen.dart';
import 'lecturer_timetable_grid_screen.dart';
import 'kp_timetable_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int index = 0;
  String? _lastRequestedScope;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final user = state.currentUser!;

    // Role checks
    final isAdmin = user.role == UserRole.pentadbir;
    final isKetuaJabatan = user.role == UserRole.ketua_jabatan;
    final isKetuaProgram = user.role == UserRole.ketua_program;
    final isKetuaProgramWithoutKj =
        state.currentKetuaProgramInheritsKetuaJabatanTasks;
    final isPensyarah = user.role == UserRole.pensyarah;

    // Build navigation items based strictly on role
    late final List<_NavItem> items;
    void navigateToLabel(String label) {
      final targetIndex = items.indexWhere((item) => item.label == label);
      if (targetIndex == -1) return;
      setState(() => index = targetIndex);
    }

    items = <_NavItem>[
      // Dashboard is global to all users, but its interior will shape-shift later
      _NavItem(
        'Papan Pemuka',
        Icons.dashboard_outlined,
        DashboardScreen(onNavigateToLabel: navigateToLabel),
        dataScope: _DataScope.dashboard,
      ),

      // Pensyarah: view own timetable (Module 5 – read-only grid)
      if (isPensyarah)
        _NavItem(
          'Jadual Saya',
          Icons.calendar_view_week_outlined,
          LecturerTimetableGridScreen(
            lecturerId: user.uid,
            lecturerName: user.name,
            lecturerEmail: user.email,
            programId: user.programId ?? '',
            lecturerProfileId: user.lecturerProfileId,
            onNavigateToAttendance: () {
              setState(() {
                final targetIndex =
                    _DataScope.values.indexOf(_DataScope.timetable);
                if (targetIndex != -1) index = targetIndex;
              });
            },
            // FIXED TYPO HERE: Changed 'onNavigateToTempapan' to 'onNavigateToTempahan'
            onNavigateToTempahan: () {
              setState(() {
                final targetIndex =
                    _DataScope.values.indexOf(_DataScope.attendance);
                if (targetIndex != -1) index = targetIndex;
              });
            },
          ),
          dataScope: _DataScope.none, // uses its own Firestore stream
        ),

      if (isKetuaProgram && !isKetuaProgramWithoutKj)
        _NavItem(
          'Jadual Program',
          Icons.calendar_month_outlined,
          KpTimetableScreen(kpUser: user),
          dataScope: _DataScope.timetable,
        ),

      // Option A: only Pensyarah takes attendance.
      if (isPensyarah)
        const _NavItem(
            'Kehadiran', Icons.fact_check_outlined, AttendanceScreen(),
            dataScope: _DataScope.attendance),

      // Option A: KJ uploads timetable; KP inherits this if program has no KJ.
      if (isKetuaJabatan || isKetuaProgramWithoutKj)
        const _NavItem('Pengurusan Jadual', Icons.calendar_month_outlined,
            TimetableScreen(),
            dataScope: _DataScope.timetable),

      // Option A: KJ reviews department reports, KP reviews program reports.
      if (isKetuaJabatan || isKetuaProgram)
        const _NavItem('Laporan', Icons.bar_chart_outlined, ReportsScreen(),
            dataScope: _DataScope.records),

      // Pensyarah requests; KP and KJ approve according to programme hierarchy.
      if (isPensyarah || isKetuaProgram || isKetuaJabatan)
        const _NavItem(
            'Tempahan Bilik', Icons.meeting_room_outlined, TempahanScreen(),
            dataScope: _DataScope.booking),

      // Pensyarah submits reports; KJ/KP review according to scoped hierarchy.
      if (isPensyarah || isKetuaJabatan || isKetuaProgram)
        _NavItem(isPensyarah ? 'Laporan Disiplin Saya' : 'Laporan Disiplin',
            Icons.warning_amber_outlined, const DisiplinScreen(),
            dataScope: _DataScope.discipline),

      // KJ/KP see student records within operational scope.
      if (isKetuaJabatan || isKetuaProgram)
        const _NavItem(
            'Rekod Pelajar', Icons.people_alt_outlined, RecordsScreen(),
            dataScope: _DataScope.records),

      // Admin Only Modules
      if (isAdmin)
        const _NavItem(
            'Daftar Akaun', Icons.person_add_outlined, RegisterUserScreen()),
      if (isAdmin)
        const _NavItem(
          'Pengurusan Pengguna',
          Icons.manage_accounts_outlined,
          AdminUserManagementScreen(),
          dataScope:
              _DataScope.none, // Since it uses internal Firestore streams
        ),
    ];
    if (index >= items.length) index = 0;
    final activeItem = items[index];
    _requestDataFor(activeItem, state);
    final mobile = context.isMobile;
    final compact = MediaQuery.sizeOf(context).width < 780;
    if (mobile) {
      return _MobileHomeShell(
        user: user,
        items: items,
        activeIndex: index,
        activeItem: activeItem,
        state: state,
        isWaiting: _isWaitingForInitialScreenData(activeItem, state),
        onSelectIndex: (value) => setState(() => index = value),
      );
    }

    return Scaffold(
      body: Row(
        children: [
          if (!compact) ...[
            Container(
              width: MediaQuery.sizeOf(context).width > 1120 ? 246 : 88,
              decoration: const BoxDecoration(
                color: AppColors.sidebar,
                border: Border(
                  right: BorderSide(color: Color(0xff1e293b)),
                ),
              ),
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: IntrinsicHeight(
                        child: NavigationRail(
                          backgroundColor: AppColors.sidebar,
                          indicatorColor:
                              AppColors.primary.withValues(alpha: .18),
                          indicatorShape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          extended: MediaQuery.sizeOf(context).width > 1120,
                          selectedIndex: index,
                          selectedIconTheme:
                              const IconThemeData(color: Colors.white),
                          unselectedIconTheme: const IconThemeData(
                              color: AppColors.sidebarMuted),
                          selectedLabelTextStyle: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                          unselectedLabelTextStyle:
                              const TextStyle(color: AppColors.sidebarMuted),
                          onDestinationSelected: (value) =>
                              setState(() => index = value),
                          leading: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            child: _BrandMark(
                              extended: MediaQuery.sizeOf(context).width > 1120,
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
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: IconButton(
                        tooltip: 'Log Keluar',
                        onPressed: state.logout,
                        icon: const Icon(
                          Icons.logout,
                          color: AppColors.sidebarMuted,
                        ),
                      ),
                    ),
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
                    color: AppColors.background,
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
                                child: Text(
                                    'Ralat memuat turun data: ${state.error}',
                                    style: const TextStyle(
                                        color: AppColors.danger)),
                              ),
                            )
                          : _isWaitingForInitialScreenData(activeItem, state)
                              ? const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(24),
                                    child: CircularProgressIndicator(),
                                  ),
                                )
                              : activeItem.screen,
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

  void _requestDataFor(_NavItem item, AppState state) {
    if (_lastRequestedScope == item.dataScope.name) return;
    _lastRequestedScope = item.dataScope.name;
    Future.microtask(() => switch (item.dataScope) {
          _DataScope.dashboard => state.loadDashboardDataIfNeeded(),
          _DataScope.timetable => state.loadTimetableDataIfNeeded(),
          _DataScope.attendance => state.loadAttendanceDataIfNeeded(),
          _DataScope.booking => state.loadBookingDataIfNeeded(),
          _DataScope.discipline => state.loadDisciplineDataIfNeeded(),
          _DataScope.records => state.loadStudentRecordDataIfNeeded(),
          _DataScope.none => Future<void>.value(),
        }).catchError((_) {});
  }

  bool _isWaitingForInitialScreenData(_NavItem item, AppState state) {
    return switch (item.dataScope) {
      _DataScope.dashboard =>
        !state.isDashboardDataLoaded && state.isDashboardDataLoading,
      _DataScope.timetable =>
        !state.isTimetableDataLoaded && state.isCollectionLoading('timetable'),
      _DataScope.attendance =>
        !state.isAttendanceDataLoaded && state.isCollectionLoading('timetable'),
      _DataScope.booking =>
        !state.isBookingDataLoaded && state.isCollectionLoading('bookings'),
      _DataScope.discipline => !state.isDisciplineDataLoaded &&
          state.isCollectionLoading('discipline'),
      _DataScope.records => !state.isStudentRecordDataLoaded &&
          state.isCollectionLoading('students'),
      _DataScope.none => false,
    };
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
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: .96),
        border: const Border(bottom: BorderSide(color: AppColors.border)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: .035),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(
              Icons.school_outlined,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          const Flexible(
            child: Text(
              'Sistem Kehadiran TVETMARA',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: AppColors.primaryDark,
              ),
            ),
          ),
          const Spacer(),
          const Text('Selasa, 19 Mei 2026',
              style: TextStyle(color: AppColors.muted)),
          const SizedBox(width: 16),
          Chip(
            label: Text(user.role == UserRole.pentadbir
                ? 'Pentadbir'
                : user.role == UserRole.ketua_jabatan
                    ? 'Ketua Jabatan'
                    : user.role == UserRole.ketua_program
                        ? 'Ketua Program'
                        : 'Pensyarah'),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              user.name,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.primaryDark,
                fontWeight: FontWeight.w800,
              ),
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

class _MobileHomeShell extends StatelessWidget {
  const _MobileHomeShell({
    required this.user,
    required this.items,
    required this.activeIndex,
    required this.activeItem,
    required this.state,
    required this.isWaiting,
    required this.onSelectIndex,
  });

  final AppUser user;
  final List<_NavItem> items;
  final int activeIndex;
  final _NavItem activeItem;
  final AppState state;
  final bool isWaiting;
  final ValueChanged<int> onSelectIndex;

  @override
  Widget build(BuildContext context) {
    final primaryItems = _mobilePrimaryItems(user, items);
    final primaryIndexes = primaryItems
        .map((item) => items.indexOf(item))
        .where((index) => index >= 0)
        .toList();
    final moreItems =
        items.where((item) => !primaryItems.contains(item)).toList();
    final hasMoreMenu = moreItems.isNotEmpty;
    final selectedPrimaryIndex = primaryIndexes.indexOf(activeIndex);
    final navIndex = selectedPrimaryIndex == -1
        ? (hasMoreMenu ? primaryItems.length : 0)
        : selectedPrimaryIndex;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _MobileTopBar(
              user: user,
              title: activeItem.label,
              onLogout: state.logout,
            ),
            Expanded(
              child: ColoredBox(
                color: AppColors.background,
                child: SingleChildScrollView(
                  padding: EdgeInsets.zero,
                  child: state.error != null
                      ? MobilePageContainer(
                          child: _MobileErrorState(message: '${state.error}'),
                        )
                      : isWaiting
                          ? const MobilePageContainer(
                              child: Padding(
                                padding: EdgeInsets.all(28),
                                child:
                                    Center(child: CircularProgressIndicator()),
                              ),
                            )
                          : MobilePageContainer(child: activeItem.screen),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: const Border(top: BorderSide(color: AppColors.border)),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryDark.withValues(alpha: .08),
                blurRadius: 22,
                offset: const Offset(0, -8),
              ),
            ],
          ),
          child: NavigationBar(
            height: 72,
            selectedIndex: navIndex,
            backgroundColor: AppColors.surface,
            indicatorColor: AppColors.primary.withValues(alpha: .12),
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            onDestinationSelected: (value) {
              if (value < primaryIndexes.length) {
                onSelectIndex(primaryIndexes[value]);
                return;
              }
              if (hasMoreMenu) {
                _showMobileMoreSheet(context, moreItems);
              }
            },
            destinations: [
              for (final item in primaryItems)
                NavigationDestination(
                  icon: Icon(item.icon),
                  selectedIcon: Icon(item.icon),
                  label: _mobileNavLabel(item.label),
                ),
              if (hasMoreMenu)
                const NavigationDestination(
                  icon: Icon(Icons.grid_view_outlined),
                  selectedIcon: Icon(Icons.grid_view_rounded),
                  label: 'Menu',
                ),
            ],
          ),
        ),
      ),
    );
  }

  List<_NavItem> _mobilePrimaryItems(AppUser user, List<_NavItem> allItems) {
    if (allItems.length <= 5) {
      return List<_NavItem>.from(allItems);
    }

    final labels = switch (user.role) {
      UserRole.pensyarah => [
          'Papan Pemuka',
          'Jadual Saya',
          'Kehadiran',
          'Tempahan Bilik',
        ],
      UserRole.ketua_jabatan => [
          'Papan Pemuka',
          'Pengurusan Jadual',
          'Laporan',
          'Tempahan Bilik',
        ],
      UserRole.ketua_program => [
          'Papan Pemuka',
          'Pengurusan Jadual',
          'Jadual Program',
          'Laporan',
          'Tempahan Bilik',
        ],
      UserRole.pentadbir => [
          'Papan Pemuka',
          'Daftar Akaun',
          'Pengurusan Pengguna',
        ],
    };

    final result = <_NavItem>[];
    for (final label in labels) {
      final match = allItems.where((item) => item.label == label).firstOrNull;
      if (match != null && !result.contains(match)) {
        result.add(match);
      }
      if (result.length == 4) break;
    }
    if (result.isEmpty && allItems.isNotEmpty) result.add(allItems.first);
    return result;
  }

  String _mobileNavLabel(String label) {
    return switch (label) {
      'Papan Pemuka' => 'Home',
      'Pengurusan Jadual' => 'Jadual',
      'Jadual Program' => 'Jadual',
      'Jadual Saya' => 'Jadual',
      'Tempahan Bilik' => 'Tempahan',
      'Daftar Akaun' => 'Daftar',
      'Pengurusan Pengguna' => 'Pengguna',
      'Laporan Disiplin' => 'Disiplin',
      'Laporan Disiplin Saya' => 'Disiplin',
      'Rekod Pelajar' => 'Rekod',
      _ => label,
    };
  }

  void _showMobileMoreSheet(BuildContext context, List<_NavItem> moreItems) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return MobileBottomSheet(
          title: 'Menu',
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final item in moreItems)
                MobileListTile(
                  icon: item.icon,
                  title: item.label,
                  onTap: () {
                    Navigator.pop(context);
                    final target = items.indexOf(item);
                    if (target != -1) onSelectIndex(target);
                  },
                ),
              MobileListTile(
                icon: Icons.logout,
                title: 'Log Keluar',
                iconColor: AppColors.danger,
                onTap: () {
                  Navigator.pop(context);
                  state.logout();
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MobileTopBar extends StatelessWidget {
  const _MobileTopBar({
    required this.user,
    required this.title,
    required this.onLogout,
  });

  final AppUser user;
  final String title;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(bottom: BorderSide(color: AppColors.border)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: .04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.school_outlined, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'TVETMARA',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_roleLabel(user.role)} • $title',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Log Keluar',
            onPressed: onLogout,
            icon: const Icon(Icons.logout_outlined),
          ),
        ],
      ),
    );
  }

  String _roleLabel(UserRole role) {
    return switch (role) {
      UserRole.pentadbir => 'Pentadbir',
      UserRole.ketua_jabatan => 'Ketua Jabatan',
      UserRole.ketua_program => 'Ketua Program',
      UserRole.pensyarah => 'Pensyarah',
    };
  }
}

class _MobileErrorState extends StatelessWidget {
  const _MobileErrorState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: .08),
        border: Border.all(color: AppColors.danger.withValues(alpha: .22)),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        'Ralat memuat turun data: $message',
        style: const TextStyle(
          color: AppColors.danger,
          fontWeight: FontWeight.w700,
        ),
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
        foregroundColor: AppColors.primary,
        child: Icon(Icons.school),
      );
    }
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.white,
            foregroundColor: AppColors.primary,
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
  const _NavItem(this.label, this.icon, this.screen,
      {this.dataScope = _DataScope.none});
  final String label;
  final IconData icon;
  final Widget screen;
  final _DataScope dataScope;
}

enum _DataScope {
  none,
  dashboard,
  timetable,
  attendance,
  booking,
  discipline,
  records,
}
