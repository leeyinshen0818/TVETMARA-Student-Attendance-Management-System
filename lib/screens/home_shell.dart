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
          dataScope: _DataScope.timetable,
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
          dataScope: _DataScope.adminManagement,
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
          _DataScope.adminManagement =>
            state.loadAdminUserManagementDataIfNeeded(),
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
      _DataScope.adminManagement => !state.isAdminUserManagementDataLoaded &&
          (state.isCollectionLoading('users') ||
              state.isCollectionLoading('students') ||
              state.isCollectionLoading('lecturerCourseAssignments') ||
              state.isCollectionLoading('timetable')),
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
        child: _MobileBottomNav(
          primaryItems: primaryItems,
          primaryIndexes: primaryIndexes,
          activeIndex: activeIndex,
          hasMoreMenu: hasMoreMenu,
          menuActive: selectedPrimaryIndex == -1 && hasMoreMenu,
          labelFor: _mobileNavLabel,
          onSelectIndex: onSelectIndex,
          onMenuPressed: hasMoreMenu
              ? () => _showMobileMoreSheet(
                    context,
                    moreItems,
                    activeIndex: activeIndex,
                  )
              : null,
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

  void _showMobileMoreSheet(
    BuildContext context,
    List<_NavItem> moreItems, {
    required int activeIndex,
  }) {
    final visibleItems = moreItems.toSet().toList();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(26)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryDark.withValues(alpha: .18),
                    blurRadius: 28,
                    offset: const Offset(0, -8),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xffcbd5e1),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: .1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.grid_view_rounded,
                            color: AppColors.primary,
                            size: 19,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Menu',
                            style: TextStyle(
                              color: AppColors.primaryDark,
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    if (visibleItems.isEmpty)
                      const _MobileMenuEmptyState()
                    else
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppColors.surfaceTint,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (var i = 0; i < visibleItems.length; i++) ...[
                              _MobileMenuTile(
                                item: visibleItems[i],
                                current: items.indexOf(visibleItems[i]) ==
                                    activeIndex,
                                onTap: () {
                                  final target = items.indexOf(visibleItems[i]);
                                  if (target == activeIndex) return;
                                  Navigator.pop(context);
                                  if (target != -1) onSelectIndex(target);
                                },
                              ),
                              if (i != visibleItems.length - 1)
                                const Divider(
                                  height: 1,
                                  indent: 58,
                                  color: AppColors.border,
                                ),
                            ],
                          ],
                        ),
                      ),
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.danger.withValues(alpha: .06),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                            color: AppColors.danger.withValues(alpha: .16)),
                      ),
                      child: ListTile(
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 12),
                        leading: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.danger.withValues(alpha: .1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.logout_rounded,
                              color: AppColors.danger, size: 19),
                        ),
                        title: const Text(
                          'Log Keluar',
                          style: TextStyle(
                            color: AppColors.danger,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          state.logout();
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
      padding: const EdgeInsets.fromLTRB(14, 8, 10, 9),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: .98),
        border: const Border(bottom: BorderSide(color: AppColors.border)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: .055),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: .11),
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: AppColors.primary.withValues(alpha: .1)),
            ),
            child: const Icon(
              Icons.school_outlined,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Flexible(
                      child: Text(
                        'TVETMARA',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: .08),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                              color: AppColors.primary.withValues(alpha: .1)),
                        ),
                        child: Text(
                          _roleLabel(user.role),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w900,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  'Sistem Kehadiran • $title',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Tooltip(
            message: 'Log Keluar',
            child: InkWell(
              onTap: onLogout,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.surfaceTint,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Icon(
                  Icons.logout_outlined,
                  color: AppColors.primaryDark,
                  size: 19,
                ),
              ),
            ),
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

class _MobileBottomNav extends StatelessWidget {
  const _MobileBottomNav({
    required this.primaryItems,
    required this.primaryIndexes,
    required this.activeIndex,
    required this.hasMoreMenu,
    required this.menuActive,
    required this.labelFor,
    required this.onSelectIndex,
    required this.onMenuPressed,
  });

  final List<_NavItem> primaryItems;
  final List<int> primaryIndexes;
  final int activeIndex;
  final bool hasMoreMenu;
  final bool menuActive;
  final String Function(String label) labelFor;
  final ValueChanged<int> onSelectIndex;
  final VoidCallback? onMenuPressed;

  @override
  Widget build(BuildContext context) {
    final itemCount = primaryItems.length + (hasMoreMenu ? 1 : 0);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: .98),
        border: const Border(top: BorderSide(color: AppColors.border)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: .09),
            blurRadius: 24,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 7, 8, 7),
        child: Row(
          mainAxisAlignment: itemCount <= 3
              ? MainAxisAlignment.spaceEvenly
              : MainAxisAlignment.spaceBetween,
          children: [
            for (var i = 0; i < primaryItems.length; i++)
              _MobileNavItemButton(
                icon: primaryItems[i].icon,
                label: labelFor(primaryItems[i].label),
                active: primaryIndexes[i] == activeIndex,
                onTap: () => onSelectIndex(primaryIndexes[i]),
              ),
            if (hasMoreMenu)
              _MobileNavItemButton(
                icon: Icons.grid_view_rounded,
                label: 'Menu',
                active: menuActive,
                onTap: onMenuPressed,
              ),
          ],
        ),
      ),
    );
  }
}

class _MobileNavItemButton extends StatelessWidget {
  const _MobileNavItemButton({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.primary : AppColors.muted;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
            decoration: BoxDecoration(
              color: active ? AppColors.primary.withValues(alpha: .1) : null,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: active
                    ? AppColors.primary.withValues(alpha: .14)
                    : Colors.transparent,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 21, color: color),
                const SizedBox(height: 3),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: color,
                    fontSize: 10.5,
                    fontWeight: active ? FontWeight.w900 : FontWeight.w700,
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

class _MobileMenuTile extends StatelessWidget {
  const _MobileMenuTile({
    required this.item,
    required this.current,
    required this.onTap,
  });

  final _NavItem item;
  final bool current;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = current ? AppColors.primary : AppColors.primaryDark;
    return ListTile(
      enabled: !current,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: current
              ? AppColors.primary.withValues(alpha: .1)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(item.icon, color: color, size: 19),
      ),
      title: Text(
        item.label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w900,
        ),
      ),
      trailing: current
          ? const Text(
              'Semasa',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            )
          : const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.muted,
            ),
      onTap: current ? null : onTap,
    );
  }
}

class _MobileMenuEmptyState extends StatelessWidget {
  const _MobileMenuEmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: AppColors.surfaceTint,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: const Text(
        'Semua halaman utama sudah dipaparkan di bawah.',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: AppColors.muted,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
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
  adminManagement,
}
