import 'package:flutter/material.dart';

import '../models/app_models.dart';
import '../state/app_scope.dart';
import '../state/app_state.dart';
import '../widgets/app_layout.dart';
import '../widgets/app_theme.dart';
import '../widgets/academic_session_manager_dialog.dart';
import '../widgets/mobile_components.dart';
import '../widgets/responsive.dart';
import '../widgets/stat_tile.dart';
import '../widgets/status_chip.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, this.onNavigateToLabel});

  final ValueChanged<String>? onNavigateToLabel;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final user = state.currentUser!;

    if (user.role == UserRole.pentadbir) {
      return _PentadbirDashboard(
        state: state,
        onNavigateToLabel: onNavigateToLabel,
      );
    }

    if (user.role == UserRole.ketua_jabatan ||
        user.role == UserRole.ketua_program) {
      return _KetuaDashboard(
        state: state,
        onNavigateToLabel: onNavigateToLabel,
      );
    }

    return _PensyarahDashboard(
      state: state,
      onNavigateToLabel: onNavigateToLabel,
    );
  }
}

class _PentadbirDashboard extends StatelessWidget {
  const _PentadbirDashboard({
    required this.state,
    required this.onNavigateToLabel,
  });

  final AppState state;
  final ValueChanged<String>? onNavigateToLabel;

  @override
  Widget build(BuildContext context) {
    final users = state.users;
    final students = state.students;
    final lecturers = state.lecturers;
    final programs = state.programs;
    final sessions = state.academicSessions;
    final activeSession = _activeSessionLabel(state);
    final lecturerEmails = <String>{
      ...lecturers.map((lecturer) => lecturer.email.toLowerCase()),
      ...users
          .where((item) => item.role == UserRole.pensyarah)
          .map((item) => item.email.toLowerCase()),
    };
    final managementAccounts = users
        .where((item) =>
            item.role == UserRole.pentadbir ||
            item.role == UserRole.ketua_jabatan ||
            item.role == UserRole.ketua_program)
        .length;
    final inactiveAccounts = users.where((item) => !item.isActive).length;
    final activeClasses = students
        .where((student) => student.active)
        .map((student) => student.section)
        .toSet()
        .length;

    if (context.isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MobileDashboardWelcomeCard(
            title: 'Selamat kembali, Pentadbir',
            subtitle: 'Ringkasan akaun, data sistem dan tetapan asas.',
            scopeLabel: 'Pentadbir',
            sessionLabel: activeSession,
            icon: Icons.admin_panel_settings_outlined,
          ),
          const SizedBox(height: 12),
          _AdminStatGrid(
            tiles: [
              StatTile(
                label: 'Pengguna',
                value: '${users.length}',
                icon: Icons.people_alt_outlined,
              ),
              StatTile(
                label: 'Pelajar',
                value: '${students.length}',
                icon: Icons.school_outlined,
              ),
              StatTile(
                label: 'Pensyarah',
                value: '${lecturerEmails.length}',
                icon: Icons.badge_outlined,
              ),
              StatTile(
                label: 'Akaun Tidak Aktif',
                value: '$inactiveAccounts',
                icon: Icons.person_off_outlined,
                color: inactiveAccounts > 0
                    ? AppColors.warning
                    : AppColors.success,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _AdminQuickActionsPanel(
            state: state,
            onNavigateToLabel: onNavigateToLabel,
          ),
          const SizedBox(height: 16),
          AppPanel(
            title: 'Status Data Sistem',
            subtitle: 'Kesediaan data asas untuk operasi semester semasa.',
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _ReadinessTile(
                    label: 'Program aktif', value: '${programs.length}'),
                _ReadinessTile(label: 'Kelas aktif', value: '$activeClasses'),
                _ReadinessTile(label: 'Pelajar', value: '${students.length}'),
                _ReadinessTile(
                    label: 'Pensyarah / profil',
                    value: '${lecturerEmails.length}'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _ReviewNeededPanel(
            inactiveAccounts: inactiveAccounts,
            lecturerProfilesWithoutLogin: _lecturerProfilesWithoutLogin(
              lecturers,
              users,
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeader(
          title: 'Selamat kembali, Pentadbir',
          subtitle:
              'Ringkasan pentadbiran pengguna, data sistem dan tetapan asas.',
          trailing: StatusChip(activeSession),
        ),
        _AdminStatGrid(
          tiles: [
            StatTile(
              label: 'Pengguna',
              value: '${users.length}',
              icon: Icons.people_alt_outlined,
            ),
            StatTile(
              label: 'Pelajar',
              value: '${students.length}',
              icon: Icons.school_outlined,
            ),
            StatTile(
              label: 'Pensyarah',
              value: '${lecturerEmails.length}',
              icon: Icons.badge_outlined,
            ),
            StatTile(
              label: 'Pengurusan',
              value: '$managementAccounts',
              icon: Icons.admin_panel_settings_outlined,
            ),
            StatTile(
              label: 'Akaun Tidak Aktif',
              value: '$inactiveAccounts',
              icon: Icons.person_off_outlined,
              color:
                  inactiveAccounts > 0 ? AppColors.warning : AppColors.success,
            ),
            StatTile(
              label: 'Program / Kelas Aktif',
              value: '${programs.length} / $activeClasses',
              icon: Icons.account_tree_outlined,
            ),
          ],
        ),
        const SizedBox(height: 16),
        _AdminQuickActionsPanel(
          state: state,
          onNavigateToLabel: onNavigateToLabel,
        ),
        const SizedBox(height: 20),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 920;
            final panels = [
              _UserRoleSummaryPanel(users: users, students: students),
              _CurrentSettingsPanel(
                attendanceThreshold: state.attendanceThreshold,
                reportFrequency: state.reportFrequency,
                semester: state.semester,
                activeSession: activeSession,
              ),
            ];

            if (!wide) {
              return Column(
                children: [
                  for (final panel in panels) ...[
                    panel,
                    const SizedBox(height: 16),
                  ],
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: panels[0]),
                const SizedBox(width: 16),
                Expanded(child: panels[1]),
              ],
            );
          },
        ),
        AppPanel(
          title: 'Status Data Sistem',
          subtitle: 'Kesediaan data asas untuk operasi semester semasa.',
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _ReadinessTile(
                  label: 'Program aktif', value: '${programs.length}'),
              _ReadinessTile(label: 'Kelas aktif', value: '$activeClasses'),
              _ReadinessTile(label: 'Pelajar', value: '${students.length}'),
              _ReadinessTile(
                  label: 'Pensyarah / profil',
                  value: '${lecturerEmails.length}'),
              _ReadinessTile(
                label: 'Sesi akademik aktif',
                value:
                    '${sessions.where((session) => session.isActive && session.status.toLowerCase() != 'archived').length}',
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _ReviewNeededPanel(
          inactiveAccounts: inactiveAccounts,
          lecturerProfilesWithoutLogin: _lecturerProfilesWithoutLogin(
            lecturers,
            users,
          ),
        ),
      ],
    );
  }
}

class _AdminQuickActionsPanel extends StatelessWidget {
  const _AdminQuickActionsPanel({
    required this.state,
    required this.onNavigateToLabel,
  });

  final AppState state;
  final ValueChanged<String>? onNavigateToLabel;

  @override
  Widget build(BuildContext context) {
    return _DashboardQuickActionsPanel(
      title: 'Tindakan Pentadbiran',
      subtitle: 'Urus akaun pengguna dan data asas sistem.',
      actions: [
        _DashboardQuickAction(
          icon: Icons.person_add_alt_1_outlined,
          label: 'Daftar Akaun',
          description: 'Cipta akaun baharu',
          onPressed: () => onNavigateToLabel?.call('Daftar Akaun'),
        ),
        _DashboardQuickAction(
          icon: Icons.manage_accounts_outlined,
          label: 'Pengurusan Pengguna',
          description: 'Urus akaun sistem',
          onPressed: () => onNavigateToLabel?.call('Pengurusan Pengguna'),
        ),
        _DashboardQuickAction(
          icon: Icons.event_note_outlined,
          label: 'Urus Sesi Akademik',
          description: 'Tambah atau arkib sesi akademik',
          onPressed: () => showAcademicSessionManagerDialog(
            context: context,
            state: state,
          ),
        ),
      ],
    );
  }
}

class _KetuaDashboard extends StatelessWidget {
  const _KetuaDashboard({
    required this.state,
    required this.onNavigateToLabel,
  });

  final AppState state;
  final ValueChanged<String>? onNavigateToLabel;

  @override
  Widget build(BuildContext context) {
    final user = state.currentUser!;
    final isKj = user.role == UserRole.ketua_jabatan;
    final inheritsKj = state.currentKetuaProgramInheritsKetuaJabatanTasks;
    final scopedPrograms = state.scopedPrograms;
    final hasStudentData = state.isStudentRecordDataLoaded;
    final scopedStudents = hasStudentData ? state.scopedStudents : <Student>[];
    final studentSummary = state.studentDashboardSummary;
    final sessionSlots = _currentSessionSlots(state);
    final activeSlots = sessionSlots.where(_isActiveSlot).toList();
    final bookings = state.scopedBookings;
    final disciplineReports = state.scopedDisciplineReports;
    final pendingBookings =
        bookings.where((booking) => _isPendingStatus(booking.status)).length;
    final pendingDiscipline = disciplineReports
        .where((report) => _isPendingDisciplineStatus(report.status))
        .length;
    final riskStudents = hasStudentData
        ? scopedStudents
            .where((student) =>
                state.attendanceSummaryForStudent(student).percentage <
                state.attendanceThreshold)
            .toList()
        : <Student>[];
    final riskStudentCount = hasStudentData
        ? riskStudents.length
        : studentSummary.belowThresholdStudents;
    final conflictCount = _countTimetableConflicts(activeSlots);
    final pendingActions = pendingBookings + pendingDiscipline + conflictCount;
    final scopeCode = isKj
        ? _departmentShortLabel(state, user.departmentId)
        : (user.programId ?? scopedPrograms.firstOrNull?.id ?? 'Program');
    final scopeWord = isKj ? 'Jabatan' : 'Program';
    final title = isKj
        ? 'Selamat kembali, KJ $scopeCode'
        : 'Selamat kembali, KP $scopeCode';
    final subtitle = isKj
        ? 'Pemantauan jabatan untuk jadual, kehadiran, disiplin dan kelulusan.'
        : inheritsKj
            ? 'Pemantauan program untuk kehadiran, laporan dan kelulusan tempahan.'
            : 'Pemantauan program sendiri untuk kehadiran, jadual dan laporan.';

    if (context.isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MobileDashboardWelcomeCard(
            title: title,
            subtitle: subtitle,
            scopeLabel: '$scopeWord $scopeCode',
            sessionLabel: _activeSessionLabel(state),
            icon: Icons.admin_panel_settings_outlined,
          ),
          const SizedBox(height: 12),
          _AdminStatGrid(
            tiles: [
              StatTile(
                label: 'Pelajar',
                value: hasStudentData
                    ? '${scopedStudents.length}'
                    : '${studentSummary.totalStudents}',
                icon: Icons.school_outlined,
              ),
              StatTile(
                label: 'Slot Aktif',
                value: '${activeSlots.length}',
                icon: Icons.calendar_month_outlined,
              ),
              StatTile(
                label: 'Bawah Had',
                value: '$riskStudentCount',
                icon: Icons.warning_amber_outlined,
                color: riskStudentCount == 0
                    ? AppColors.success
                    : AppColors.danger,
              ),
              StatTile(
                label: 'Tindakan',
                value: '$pendingActions',
                icon: Icons.pending_actions_outlined,
                color:
                    pendingActions == 0 ? AppColors.success : AppColors.warning,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _DashboardQuickActionsPanel(
            title: 'Tindakan Pantas $scopeWord',
            subtitle: 'Buka modul utama untuk semakan dan tindakan lanjut.',
            actions: [
              if (isKj || inheritsKj)
                _DashboardQuickAction(
                  icon: Icons.calendar_month_outlined,
                  label: 'Pengurusan Jadual',
                  description: 'Urus jadual & tempahan',
                  onPressed: () => onNavigateToLabel?.call('Pengurusan Jadual'),
                )
              else
                _DashboardQuickAction(
                  icon: Icons.calendar_month_outlined,
                  label: 'Jadual Program',
                  description: 'Lihat slot program',
                  onPressed: () => onNavigateToLabel?.call('Jadual Program'),
                ),
              _DashboardQuickAction(
                icon: Icons.gavel_outlined,
                label: 'Disiplin',
                description: 'Laporan disiplin',
                onPressed: () => onNavigateToLabel?.call('Laporan Disiplin'),
              ),
              _DashboardQuickAction(
                icon: Icons.meeting_room_outlined,
                label: 'Semak Tempahan',
                description: 'Luluskan atau semak permohonan bilik',
                onPressed: () => onNavigateToLabel?.call('Tempahan Bilik'),
              ),
              _DashboardQuickAction(
                icon: Icons.people_alt_outlined,
                label: 'Rekod Pelajar',
                description: 'Semak pelajar',
                onPressed: () => onNavigateToLabel?.call('Rekod Pelajar'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _ActionRequiredPanel(
            pendingBookings: pendingBookings,
            pendingDiscipline: pendingDiscipline,
            riskStudents: riskStudentCount,
            timetableConflicts: conflictCount,
          ),
          const SizedBox(height: 16),
          _AttendanceSummaryPanel(
            state: state,
            students: scopedStudents,
            summary: studentSummary,
            useLoadedStudents: hasStudentData,
            title: isKj
                ? 'Ringkasan Kehadiran Jabatan'
                : 'Ringkasan Kehadiran Program',
          ),
          const SizedBox(height: 16),
          _TimetableProgrammeSummaryPanel(
            programs: scopedPrograms,
            slots: activeSlots,
            title:
                isKj ? 'Ringkasan Jadual Jabatan' : 'Ringkasan Jadual Program',
          ),
          const SizedBox(height: 16),
          _MobileTimetableListPanel(
            title: isKj ? 'Slot Jadual Terkini' : 'Jadual Program Terkini',
            slots: activeSlots,
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeader(
          title: title,
          subtitle: subtitle,
          trailing: StatusChip(_activeSessionLabel(state)),
        ),
        _AdminStatGrid(
          tiles: [
            StatTile(
              label: 'Pelajar',
              value: hasStudentData
                  ? '${scopedStudents.length}'
                  : '${studentSummary.totalStudents}',
              icon: Icons.school_outlined,
            ),
            StatTile(
              label: 'Slot Aktif',
              value: '${activeSlots.length}',
              icon: Icons.calendar_month_outlined,
            ),
            StatTile(
              label: 'Bawah Had',
              value: '$riskStudentCount',
              icon: Icons.warning_amber_outlined,
              color:
                  riskStudentCount == 0 ? AppColors.success : AppColors.danger,
            ),
            StatTile(
              label: 'Tindakan',
              value: '$pendingActions',
              icon: Icons.pending_actions_outlined,
              color:
                  pendingActions == 0 ? AppColors.success : AppColors.warning,
            ),
          ],
        ),
        const SizedBox(height: 20),
        _DashboardQuickActionsPanel(
          title: 'Tindakan Pantas $scopeWord',
          subtitle: 'Buka modul utama untuk semakan dan tindakan lanjut.',
          actions: [
            if (isKj || inheritsKj)
              _DashboardQuickAction(
                icon: Icons.calendar_month_outlined,
                label: 'Pengurusan Jadual',
                description: 'Urus jadual, konflik dan import CSV',
                onPressed: () => onNavigateToLabel?.call('Pengurusan Jadual'),
              )
            else
              _DashboardQuickAction(
                icon: Icons.calendar_month_outlined,
                label: 'Jadual Program',
                description: 'Lihat slot jadual program sendiri',
                onPressed: () => onNavigateToLabel?.call('Jadual Program'),
              ),
            _DashboardQuickAction(
              icon: Icons.bar_chart_outlined,
              label: 'Laporan Kehadiran',
              description: 'Semak ringkasan dan analisis scoped',
              onPressed: () => onNavigateToLabel?.call('Laporan'),
            ),
            _DashboardQuickAction(
              icon: Icons.meeting_room_outlined,
              label: 'Semak Tempahan',
              description: 'Luluskan atau semak permohonan bilik',
              onPressed: () => onNavigateToLabel?.call('Tempahan Bilik'),
            ),
            _DashboardQuickAction(
              icon: Icons.warning_amber_outlined,
              label: 'Semak Disiplin',
              description: 'Lihat laporan disiplin dalam skop',
              onPressed: () => onNavigateToLabel?.call('Laporan Disiplin'),
            ),
            _DashboardQuickAction(
              icon: Icons.people_alt_outlined,
              label: 'Rekod Pelajar',
              description: 'Semak pelajar dan tugasan pensyarah',
              onPressed: () => onNavigateToLabel?.call('Rekod Pelajar'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _ActionRequiredPanel(
          pendingBookings: pendingBookings,
          pendingDiscipline: pendingDiscipline,
          riskStudents: riskStudentCount,
          timetableConflicts: conflictCount,
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 940;
            final panels = [
              _AttendanceSummaryPanel(
                state: state,
                students: scopedStudents,
                summary: studentSummary,
                useLoadedStudents: hasStudentData,
                title: isKj
                    ? 'Ringkasan Kehadiran Jabatan'
                    : 'Ringkasan Kehadiran Program',
              ),
              _TimetableProgrammeSummaryPanel(
                programs: scopedPrograms,
                slots: activeSlots,
                title: isKj
                    ? 'Ringkasan Jadual Jabatan'
                    : 'Ringkasan Jadual Program',
              ),
            ];

            if (!wide) {
              return Column(
                children: [
                  for (final panel in panels) ...[
                    panel,
                    const SizedBox(height: 16),
                  ],
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: panels[0]),
                const SizedBox(width: 16),
                Expanded(child: panels[1]),
              ],
            );
          },
        ),
        _RecentTimetablePanel(
          title: isKj ? 'Slot Jadual Terkini' : 'Jadual Program Terkini',
          slots: activeSlots,
        ),
      ],
    );
  }
}

class _PensyarahDashboard extends StatelessWidget {
  const _PensyarahDashboard({
    required this.state,
    required this.onNavigateToLabel,
  });

  final AppState state;
  final ValueChanged<String>? onNavigateToLabel;

  @override
  Widget build(BuildContext context) {
    final user = state.currentUser!;
    final slots = _currentSessionSlots(state).where(_isActiveSlot).toList()
      ..sort(_compareSlotsBySchedule);
    final hasStudentData = state.isStudentRecordDataLoaded;
    final students = hasStudentData ? state.scopedStudents : <Student>[];
    final bookings = state.scopedBookings;
    final reports = state.scopedDisciplineReports;
    final assignedClasses = slots.map((slot) => slot.section).toSet();
    final pendingAttendanceSlots =
        slots.where((slot) => !_hasCompletedAttendance(state, slot)).toList();
    final riskStudents = students
        .where((student) =>
            state.attendanceSummaryForStudent(student).percentage <
            state.attendanceThreshold)
        .toList()
      ..sort((a, b) => state
          .attendanceSummaryForStudent(a)
          .percentage
          .compareTo(state.attendanceSummaryForStudent(b).percentage));
    final nextSlot = slots.firstOrNull;

    if (context.isMobile) {
      final displayName =
          user.name.trim().isEmpty ? 'Pensyarah' : user.name.trim();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MobileDashboardWelcomeCard(
            title: 'Selamat kembali, $displayName',
            subtitle: 'Pantau jadual mengajar, kehadiran dan permohonan anda.',
            scopeLabel: 'Pensyarah',
            sessionLabel: _activeSessionLabel(state),
            icon: Icons.badge_outlined,
          ),
          const SizedBox(height: 12),
          _AdminStatGrid(
            tiles: [
              StatTile(
                label: 'Kelas',
                value: '${assignedClasses.length}',
                icon: Icons.groups_outlined,
              ),
              StatTile(
                label: 'Slot Saya',
                value: '${slots.length}',
                icon: Icons.calendar_month_outlined,
              ),
              StatTile(
                label: 'Belum Diambil',
                value: '${pendingAttendanceSlots.length}',
                icon: Icons.fact_check_outlined,
                color: pendingAttendanceSlots.isEmpty
                    ? AppColors.success
                    : AppColors.warning,
              ),
              StatTile(
                label: 'Bawah Had',
                value: '${riskStudents.length}',
                icon: Icons.report_problem_outlined,
                color:
                    riskStudents.isEmpty ? AppColors.success : AppColors.danger,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _DashboardQuickActionsPanel(
            title: 'Tindakan Pantas Mengajar',
            subtitle: 'Akses tugasan harian pensyarah dengan cepat.',
            actions: [
              _DashboardQuickAction(
                icon: Icons.calendar_view_week_outlined,
                label: 'Jadual Saya',
                description: 'Lihat slot mengajar',
                onPressed: () => onNavigateToLabel?.call('Jadual Saya'),
              ),
              _DashboardQuickAction(
                icon: Icons.fact_check_outlined,
                label: 'Kehadiran',
                description: 'Rekod kehadiran pelajar',
                onPressed: () => onNavigateToLabel?.call('Kehadiran'),
              ),
              _DashboardQuickAction(
                icon: Icons.meeting_room_outlined,
                label: 'Tempahan',
                description: 'Mohon bilik',
                onPressed: () => onNavigateToLabel?.call('Tempahan Bilik'),
              ),
              _DashboardQuickAction(
                icon: Icons.warning_amber_outlined,
                label: 'Disiplin',
                description: 'Lapor salah laku',
                onPressed: () =>
                    onNavigateToLabel?.call('Laporan Disiplin Saya'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _NextClassPanel(slot: nextSlot),
          const SizedBox(height: 16),
          _LecturerAttendanceActionPanel(slots: pendingAttendanceSlots),
          const SizedBox(height: 16),
          _RiskStudentPanel(state: state, students: riskStudents),
          const SizedBox(height: 16),
          _LecturerRequestsPanel(bookings: bookings, reports: reports),
          const SizedBox(height: 16),
          _MobileTimetableListPanel(
            title: 'Slot Jadual Saya',
            slots: slots,
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeader(
          title: user.name.trim().isEmpty
              ? 'Selamat kembali, Pensyarah'
              : 'Selamat kembali, ${user.name}',
          subtitle:
              'Pantau jadual mengajar, kehadiran, laporan disiplin dan permohonan bilik anda.',
          trailing: StatusChip(_activeSessionLabel(state)),
        ),
        _AdminStatGrid(
          tiles: [
            StatTile(
              label: 'Kelas',
              value: '${assignedClasses.length}',
              icon: Icons.groups_outlined,
            ),
            StatTile(
              label: 'Slot Saya',
              value: '${slots.length}',
              icon: Icons.calendar_month_outlined,
            ),
            StatTile(
              label: 'Belum Diambil',
              value: '${pendingAttendanceSlots.length}',
              icon: Icons.fact_check_outlined,
              color: pendingAttendanceSlots.isEmpty
                  ? AppColors.success
                  : AppColors.warning,
            ),
            StatTile(
              label: 'Bawah Had',
              value: '${riskStudents.length}',
              icon: Icons.report_problem_outlined,
              color:
                  riskStudents.isEmpty ? AppColors.success : AppColors.danger,
            ),
          ],
        ),
        const SizedBox(height: 20),
        _DashboardQuickActionsPanel(
          title: 'Tindakan Pantas Mengajar',
          subtitle: 'Akses tugasan harian pensyarah dengan cepat.',
          actions: [
            _DashboardQuickAction(
              icon: Icons.calendar_view_week_outlined,
              label: 'Jadual Saya',
              description: 'Lihat slot mengajar',
              onPressed: () => onNavigateToLabel?.call('Jadual Saya'),
            ),
            _DashboardQuickAction(
              icon: Icons.fact_check_outlined,
              label: 'Kehadiran',
              description: 'Rekod kehadiran pelajar',
              onPressed: () => onNavigateToLabel?.call('Kehadiran'),
            ),
            _DashboardQuickAction(
              icon: Icons.meeting_room_outlined,
              label: 'Tempahan',
              description: 'Mohon bilik',
              onPressed: () => onNavigateToLabel?.call('Tempahan Bilik'),
            ),
            _DashboardQuickAction(
              icon: Icons.warning_amber_outlined,
              label: 'Disiplin',
              description: 'Lapor salah laku',
              onPressed: () => onNavigateToLabel?.call('Laporan Disiplin Saya'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _NextClassPanel(slot: nextSlot),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 940;
            final panels = [
              _LecturerAttendanceActionPanel(slots: pendingAttendanceSlots),
              _RiskStudentPanel(state: state, students: riskStudents),
            ];

            if (!wide) {
              return Column(
                children: [
                  for (final panel in panels) ...[
                    panel,
                    const SizedBox(height: 16),
                  ],
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: panels[0]),
                const SizedBox(width: 16),
                Expanded(child: panels[1]),
              ],
            );
          },
        ),
        _LecturerRequestsPanel(bookings: bookings, reports: reports),
        const SizedBox(height: 16),
        _LecturerTimetablePanel(slots: slots),
      ],
    );
  }
}

class _NextClassPanel extends StatelessWidget {
  const _NextClassPanel({required this.slot});

  final TimetableSlot? slot;

  @override
  Widget build(BuildContext context) {
    final value = slot;
    return AppPanel(
      title: 'Kelas Seterusnya',
      subtitle:
          'Slot jadual seterusnya / terkini berdasarkan jadual yang ditugaskan.',
      child: value == null
          ? const _CleanEmptyState(
              icon: Icons.event_available_outlined,
              message: 'Tiada kelas seterusnya untuk dipaparkan.',
            )
          : Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: .07),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: .18),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      StatusChip(value.subjectCode),
                      StatusChip(value.section),
                      StatusChip(_statusLabel(value.status)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Tooltip(
                    message: value.subjectName,
                    child: Text(
                      value.subjectName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.primaryDark,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 14,
                    runSpacing: 8,
                    children: [
                      _InlineInfo(
                        icon: Icons.calendar_today_outlined,
                        text: value.day,
                      ),
                      _InlineInfo(
                        icon: Icons.schedule_outlined,
                        text: '${value.startTime}-${value.endTime}',
                      ),
                      _InlineInfo(
                        icon: Icons.meeting_room_outlined,
                        text: _roomLabel(value),
                      ),
                      _InlineInfo(
                        icon: Icons.date_range_outlined,
                        text:
                            'Minggu ${value.weekStart ?? '1'}-${value.weekEnd ?? '18'}',
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}

class _InlineInfo extends StatelessWidget {
  const _InlineInfo({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 6),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 220),
          child: Tooltip(
            message: text,
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.primaryDark,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LecturerAttendanceActionPanel extends StatelessWidget {
  const _LecturerAttendanceActionPanel({required this.slots});

  final List<TimetableSlot> slots;

  @override
  Widget build(BuildContext context) {
    final values = slots.take(5).toList();
    return AppPanel(
      title: 'Kehadiran Perlu Dilengkapkan',
      subtitle: 'Sesi untuk semakan kehadiran berdasarkan slot aktif anda.',
      child: values.isEmpty
          ? const _CleanEmptyState(
              icon: Icons.fact_check_outlined,
              message: 'Tiada sesi kehadiran yang memerlukan tindakan.',
            )
          : Column(
              children: [
                for (final slot in values)
                  _CompactSlotRow(
                    leading: slot.subjectCode,
                    title: slot.subjectName,
                    subtitle:
                        '${slot.section} - ${slot.day}, ${slot.startTime}-${slot.endTime}',
                    trailing:
                        'Minggu ${slot.weekStart ?? '1'}-${slot.weekEnd ?? '18'}',
                  ),
              ],
            ),
    );
  }
}

class _RiskStudentPanel extends StatelessWidget {
  const _RiskStudentPanel({
    required this.state,
    required this.students,
  });

  final AppState state;
  final List<Student> students;

  @override
  Widget build(BuildContext context) {
    final values = students.take(5).toList();
    return AppPanel(
      title: 'Pelajar Perlu Perhatian',
      subtitle: 'Pelajar dalam kelas anda yang berada di bawah had kehadiran.',
      child: values.isEmpty
          ? const _CleanEmptyState(
              icon: Icons.verified_user_outlined,
              message: 'Tiada pelajar berisiko dalam kelas anda.',
            )
          : Column(
              children: [
                for (final student in values)
                  _CompactSlotRow(
                    leading:
                        '${state.attendanceSummaryForStudent(student).percentage}%',
                    title: student.name,
                    subtitle: student.section,
                    trailing:
                        state.attendanceSummaryForStudent(student).percentage <
                                state.attendanceThreshold
                            ? 'Bawah Had'
                            : 'Stabil',
                    danger:
                        state.attendanceSummaryForStudent(student).percentage <
                            state.attendanceThreshold,
                  ),
              ],
            ),
    );
  }
}

class _LecturerRequestsPanel extends StatelessWidget {
  const _LecturerRequestsPanel({
    required this.bookings,
    required this.reports,
  });

  final List<BookingRequest> bookings;
  final List<DisciplineReport> reports;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 860;
        final panels = [
          _StatusSummaryPanel(
            title: 'Tempahan Bilik Saya',
            subtitle: 'Status permohonan bilik dan kelas ganti anda.',
            items: [
              (
                'Menunggu',
                bookings.where((item) => _isPendingStatus(item.status)).length
              ),
              (
                'Diluluskan',
                bookings.where((item) => _isApprovedStatus(item.status)).length
              ),
              (
                'Ditolak',
                bookings.where((item) => _isRejectedStatus(item.status)).length
              ),
            ],
          ),
          _StatusSummaryPanel(
            title: 'Laporan Disiplin Saya',
            subtitle: 'Status laporan disiplin yang telah dihantar.',
            items: [
              (
                'Menunggu Semakan',
                reports
                    .where((item) => _isPendingDisciplineStatus(item.status))
                    .length,
              ),
              (
                'Tindakan Diambil',
                reports
                    .where((item) =>
                        _normalizeStatusKey(item.status) == 'action_taken')
                    .length,
              ),
              (
                'Ditolak',
                reports
                    .where((item) =>
                        _normalizeStatusKey(item.status) == 'rejected')
                    .length
              ),
            ],
          ),
        ];

        if (!wide) {
          return Column(
            children: [
              for (final panel in panels) ...[
                panel,
                const SizedBox(height: 16),
              ],
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: panels[0]),
            const SizedBox(width: 16),
            Expanded(child: panels[1]),
          ],
        );
      },
    );
  }
}

class _StatusSummaryPanel extends StatelessWidget {
  const _StatusSummaryPanel({
    required this.title,
    required this.subtitle,
    required this.items,
  });

  final String title;
  final String subtitle;
  final List<(String, int)> items;

  @override
  Widget build(BuildContext context) {
    final hasAny = items.any((item) => item.$2 > 0);
    return AppPanel(
      title: title,
      subtitle: subtitle,
      child: hasAny
          ? Column(
              children: [
                for (final item in items)
                  _SummaryRow(label: item.$1, value: '${item.$2}'),
              ],
            )
          : const _CleanEmptyState(
              icon: Icons.inbox_outlined,
              message: 'Tiada rekod ditemui.',
            ),
    );
  }
}

class _LecturerTimetablePanel extends StatelessWidget {
  const _LecturerTimetablePanel({required this.slots});

  final List<TimetableSlot> slots;

  @override
  Widget build(BuildContext context) {
    final values = slots.take(5).toList();
    return AppPanel(
      title: 'Slot Jadual Saya',
      subtitle:
          'Ringkasan lima slot mengajar pertama. Buka Jadual Saya untuk paparan penuh.',
      child: values.isEmpty
          ? const _CleanEmptyState(
              icon: Icons.event_note_outlined,
              message: 'Tiada slot jadual aktif untuk sesi akademik ini.',
            )
          : AppDataTable(
              columns: const [
                DataColumn(label: Text('Hari')),
                DataColumn(label: Text('Masa')),
                DataColumn(label: Text('Kelas')),
                DataColumn(label: Text('Subjek')),
                DataColumn(label: Text('Bilik')),
                DataColumn(label: Text('Status')),
              ],
              rows: values.map((slot) {
                return DataRow(
                  cells: [
                    DataCell(Text(slot.day)),
                    DataCell(Text('${slot.startTime}-${slot.endTime}')),
                    DataCell(Text(slot.section)),
                    DataCell(
                      Tooltip(
                        message: slot.subjectName,
                        child: Text(
                          slot.subjectName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    DataCell(
                      Tooltip(
                        message: _roomLabel(slot),
                        child: Text(
                          _roomLabel(slot),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    DataCell(StatusChip(_statusLabel(slot.status))),
                  ],
                );
              }).toList(),
            ),
    );
  }
}

class _CompactSlotRow extends StatelessWidget {
  const _CompactSlotRow({
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.danger = false,
  });

  final String leading;
  final String title;
  final String subtitle;
  final String trailing;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? const Color(0xffdc2626) : const Color(0xff2563eb);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 58,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              leading,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Tooltip(
                  message: title,
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xff0f172a),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style:
                      const TextStyle(color: Color(0xff64748b), fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          StatusChip(trailing),
        ],
      ),
    );
  }
}

class _DashboardQuickActionsPanel extends StatelessWidget {
  const _DashboardQuickActionsPanel({
    required this.title,
    required this.subtitle,
    required this.actions,
  });

  final String title;
  final String subtitle;
  final List<_DashboardQuickAction> actions;

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      title: title,
      subtitle: subtitle,
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: actions,
      ),
    );
  }
}

class _MobileDashboardWelcomeCard extends StatelessWidget {
  const _MobileDashboardWelcomeCard({
    required this.title,
    required this.subtitle,
    required this.scopeLabel,
    required this.sessionLabel,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final String scopeLabel;
  final String sessionLabel;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return MobileHeroCard(
      icon: icon,
      title: title,
      subtitle: subtitle,
      chips: [
        StatusChip(scopeLabel),
        StatusChip(sessionLabel),
      ],
    );
  }
}

class _DashboardQuickAction extends StatelessWidget {
  const _DashboardQuickAction({
    required this.icon,
    required this.label,
    required this.description,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final String description;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = MediaQuery.sizeOf(context).width < 600;
        final mobileWidth = (MediaQuery.sizeOf(context).width - 64).clamp(
          240.0,
          520.0,
        );
        if (narrow) {
          return SizedBox(
            width: mobileWidth,
            child: MobileActionCard(
              icon: icon,
              title: label,
              subtitle: description,
              onTap: onPressed,
            ),
          );
        }
        return SizedBox(
          width: 235,
          child: OutlinedButton(
            onPressed: onPressed,
            style: OutlinedButton.styleFrom(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.all(14),
              side: const BorderSide(color: AppColors.border),
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: .1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MobileTimetableListPanel extends StatelessWidget {
  const _MobileTimetableListPanel({
    required this.title,
    required this.slots,
  });

  final String title;
  final List<TimetableSlot> slots;

  @override
  Widget build(BuildContext context) {
    final recent = slots.toList()..sort(_compareSlotsBySchedule);

    return AppPanel(
      title: title,
      subtitle: 'Ringkasan lima slot pertama untuk sesi akademik dipilih.',
      child: recent.isEmpty
          ? const _CleanEmptyState(
              icon: Icons.event_note_outlined,
              message: 'Tiada slot jadual aktif untuk sesi akademik ini.',
            )
          : Column(
              children: [
                for (final slot in recent.take(5)) ...[
                  _MobileTimetableSlotCard(slot: slot),
                  if (slot != recent.take(5).last) const SizedBox(height: 10),
                ],
              ],
            ),
    );
  }
}

class _MobileTimetableSlotCard extends StatelessWidget {
  const _MobileTimetableSlotCard({required this.slot});

  final TimetableSlot slot;

  @override
  Widget build(BuildContext context) {
    return MobileInfoCard(
      leadingIcon: Icons.event_note_outlined,
      title: slot.subjectName,
      subtitle: slot.lecturerName.isEmpty ? slot.section : slot.lecturerName,
      chips: [StatusChip(_statusLabel(slot.status))],
      metadata: [
        MobileMetaPill(icon: Icons.calendar_today_outlined, label: slot.day),
        MobileMetaPill(
          icon: Icons.schedule_outlined,
          label: '${slot.startTime}-${slot.endTime}',
        ),
        MobileMetaPill(icon: Icons.groups_outlined, label: slot.section),
        MobileMetaPill(
          icon: Icons.meeting_room_outlined,
          label: slot.roomName ?? slot.roomId ?? '-',
        ),
      ],
    );
  }
}

class _ActionRequiredPanel extends StatelessWidget {
  const _ActionRequiredPanel({
    required this.pendingBookings,
    required this.pendingDiscipline,
    required this.riskStudents,
    required this.timetableConflicts,
  });

  final int pendingBookings;
  final int pendingDiscipline;
  final int riskStudents;
  final int timetableConflicts;

  @override
  Widget build(BuildContext context) {
    final items = <_ActionItemData>[
      if (pendingBookings > 0)
        _ActionItemData(
          icon: Icons.meeting_room_outlined,
          title: 'Tempahan bilik menunggu kelulusan',
          count: pendingBookings,
          description:
              'Semak permohonan bilik dan kelas ganti dalam skop anda.',
        ),
      if (pendingDiscipline > 0)
        _ActionItemData(
          icon: Icons.gavel_outlined,
          title: 'Laporan disiplin menunggu semakan',
          count: pendingDiscipline,
          description: 'Tentukan tindakan lanjut untuk laporan baharu.',
        ),
      if (riskStudents > 0)
        _ActionItemData(
          icon: Icons.trending_down_outlined,
          title: 'Pelajar bawah had kehadiran',
          count: riskStudents,
          description: 'Pantau pelajar yang memerlukan intervensi kehadiran.',
        ),
      if (timetableConflicts > 0)
        _ActionItemData(
          icon: Icons.event_busy_outlined,
          title: 'Konflik jadual dikesan',
          count: timetableConflicts,
          description:
              'Semak konflik bilik, kelas atau pensyarah dalam jadual.',
        ),
    ];

    return AppPanel(
      title: 'Tindakan Diperlukan',
      subtitle: 'Ringkasan perkara yang memerlukan perhatian segera.',
      child: items.isEmpty
          ? const _CleanEmptyState(
              icon: Icons.check_circle_outline,
              message: 'Tiada tindakan segera diperlukan.',
            )
          : Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final item in items) _ActionItemCard(item: item),
              ],
            ),
    );
  }
}

class _ActionItemData {
  const _ActionItemData({
    required this.icon,
    required this.title,
    required this.count,
    required this.description,
  });

  final IconData icon;
  final String title;
  final int count;
  final String description;
}

class _ActionItemCard extends StatelessWidget {
  const _ActionItemCard({required this.item});

  final _ActionItemData item;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.warning.withValues(alpha: .24)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.warning.withValues(alpha: .14),
            child: Icon(item.icon, color: const Color(0xffc2410c), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${item.count}',
                      style: const TextStyle(
                        color: Color(0xffc2410c),
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  item.description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                    height: 1.25,
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

class _AttendanceSummaryPanel extends StatelessWidget {
  const _AttendanceSummaryPanel({
    required this.state,
    required this.students,
    required this.summary,
    required this.useLoadedStudents,
    required this.title,
  });

  final AppState state;
  final List<Student> students;
  final StudentDashboardSummary summary;
  final bool useLoadedStudents;
  final String title;

  @override
  Widget build(BuildContext context) {
    final summaries = students
        .map((student) => state.attendanceSummaryForStudent(student).percentage)
        .toList();
    final total = useLoadedStudents ? summaries.length : summary.totalStudents;
    final belowThreshold = useLoadedStudents
        ? summaries
            .where((percentage) => percentage < state.attendanceThreshold)
            .length
        : summary.belowThresholdStudents;
    final safe = useLoadedStudents
        ? summaries.length - belowThreshold
        : summary.meetsThresholdStudents;
    final below95 = useLoadedStudents
        ? summaries.where((item) => item < 95).length
        : summary.below95Students;
    final below90 = useLoadedStudents
        ? summaries.where((item) => item < 90).length
        : summary.below90Students;
    final below85 = useLoadedStudents
        ? summaries.where((item) => item < 85).length
        : summary.below85Students;
    final below80 = useLoadedStudents
        ? summaries.where((item) => item < 80).length
        : summary.below80Students;

    return AppPanel(
      title: title,
      subtitle: useLoadedStudents
          ? 'Agihan risiko kehadiran berdasarkan rekod semasa.'
          : 'Agihan ringkas tanpa memuatkan senarai penuh pelajar.',
      child: Column(
        children: [
          _ProgressSummaryRow(
            label: 'Melepasi Had',
            value: safe,
            total: total,
            color: AppColors.success,
          ),
          _ProgressSummaryRow(
            label: 'Bawah ${state.attendanceThreshold}%',
            value: belowThreshold,
            total: total,
            color: AppColors.danger,
          ),
          const Divider(height: 24),
          _SummaryRow(
            label: 'Pelajar <95%',
            value: '$below95',
          ),
          _SummaryRow(
            label: 'Pelajar <90%',
            value: '$below90',
          ),
          _SummaryRow(
            label: 'Pelajar <85%',
            value: '$below85',
          ),
          _SummaryRow(
            label: 'Pelajar <80%',
            value: '$below80',
          ),
        ],
      ),
    );
  }
}

class _ProgressSummaryRow extends StatelessWidget {
  const _ProgressSummaryRow({
    required this.label,
    required this.value,
    required this.total,
    required this.color,
  });

  final String label;
  final int value;
  final int total;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final ratio = total == 0 ? 0.0 : value / total;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '$value / $total',
                style: const TextStyle(
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: ratio,
              backgroundColor: const Color(0xffe2e8f0),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimetableProgrammeSummaryPanel extends StatelessWidget {
  const _TimetableProgrammeSummaryPanel({
    required this.programs,
    required this.slots,
    required this.title,
  });

  final List<ProgramCode> programs;
  final List<TimetableSlot> slots;
  final String title;

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      title: title,
      subtitle: 'Bilangan slot aktif mengikut program untuk sesi dipilih.',
      child: programs.isEmpty
          ? const _CleanEmptyState(
              icon: Icons.calendar_month_outlined,
              message: 'Tiada program dalam skop semasa.',
            )
          : Column(
              children: [
                for (final program in programs)
                  _SummaryRow(
                    label: '${program.id} - ${program.name}',
                    value:
                        '${slots.where((slot) => _slotProgramId(slot) == program.id).length} slot',
                  ),
              ],
            ),
    );
  }
}

class _RecentTimetablePanel extends StatelessWidget {
  const _RecentTimetablePanel({
    required this.title,
    required this.slots,
  });

  final String title;
  final List<TimetableSlot> slots;

  @override
  Widget build(BuildContext context) {
    final recent = slots.toList()
      ..sort((a, b) {
        final day = _dayOrder(a.day).compareTo(_dayOrder(b.day));
        if (day != 0) return day;
        return a.startTime.compareTo(b.startTime);
      });

    return AppPanel(
      title: title,
      subtitle:
          'Maksimum lima slot sebagai ringkasan pantas. Buka modul Jadual untuk paparan penuh.',
      child: recent.isEmpty
          ? const _CleanEmptyState(
              icon: Icons.event_note_outlined,
              message: 'Tiada slot jadual aktif untuk sesi akademik ini.',
            )
          : AppDataTable(
              columns: const [
                DataColumn(label: Text('Hari')),
                DataColumn(label: Text('Masa')),
                DataColumn(label: Text('Kelas')),
                DataColumn(label: Text('Subjek')),
                DataColumn(label: Text('Pensyarah')),
                DataColumn(label: Text('Status')),
              ],
              rows: recent.take(5).map((slot) {
                return DataRow(
                  cells: [
                    DataCell(Text(slot.day)),
                    DataCell(Text('${slot.startTime}-${slot.endTime}')),
                    DataCell(Text(slot.section)),
                    DataCell(
                      Tooltip(
                        message: slot.subjectName,
                        child: Text(
                          slot.subjectName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    DataCell(
                      Tooltip(
                        message: slot.lecturerName,
                        child: Text(
                          slot.lecturerName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    DataCell(StatusChip(_statusLabel(slot.status))),
                  ],
                );
              }).toList(),
            ),
    );
  }
}

class _CleanEmptyState extends StatelessWidget {
  const _CleanEmptyState({
    required this.icon,
    required this.message,
  });

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    if (context.isMobile) {
      return MobileEmptyState(
        icon: icon,
        title: message,
        subtitle:
            'Semakan ini akan dikemas kini apabila data baharu dimuatkan.',
      );
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceTint,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.success),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.muted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminStatGrid extends StatelessWidget {
  const _AdminStatGrid({required this.tiles});

  final List<Widget> tiles;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        const spacing = 12.0;
        final mobile = context.isMobile;
        final columns = mobile
            ? 2
            : width >= 1180
                ? 4
                : width >= 760
                    ? 2
                    : 1;
        final tileWidth = (width - (spacing * (columns - 1))) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final tile in tiles)
              SizedBox(
                width: tileWidth,
                child: mobile && tile is StatTile
                    ? MobileStatCard(
                        icon: tile.icon,
                        value: tile.value,
                        label: tile.label,
                        helper: tile.helper,
                        color: tile.color ?? AppColors.primary,
                      )
                    : tile,
              ),
          ],
        );
      },
    );
  }
}

class _UserRoleSummaryPanel extends StatelessWidget {
  const _UserRoleSummaryPanel({
    required this.users,
    required this.students,
  });

  final List<AppUser> users;
  final List<Student> students;

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      title: 'Ringkasan Pengguna Sistem',
      subtitle: 'Taburan akaun mengikut peranan utama.',
      child: Column(
        children: [
          _SummaryRow(
            label: 'Pentadbir',
            value:
                '${users.where((user) => user.role == UserRole.pentadbir).length}',
          ),
          _SummaryRow(
            label: 'Ketua Jabatan',
            value:
                '${users.where((user) => user.role == UserRole.ketua_jabatan).length}',
          ),
          _SummaryRow(
            label: 'Ketua Program',
            value:
                '${users.where((user) => user.role == UserRole.ketua_program).length}',
          ),
          _SummaryRow(
            label: 'Pensyarah',
            value:
                '${users.where((user) => user.role == UserRole.pensyarah).length}',
          ),
          _SummaryRow(label: 'Pelajar', value: '${students.length}'),
        ],
      ),
    );
  }
}

class _CurrentSettingsPanel extends StatelessWidget {
  const _CurrentSettingsPanel({
    required this.attendanceThreshold,
    required this.reportFrequency,
    required this.semester,
    required this.activeSession,
  });

  final int attendanceThreshold;
  final String reportFrequency;
  final int semester;
  final String activeSession;

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      title: 'Tetapan Semasa',
      subtitle: 'Tetapan asas yang sedang digunakan oleh sistem.',
      child: Column(
        children: [
          _SummaryRow(label: 'Had Kehadiran', value: '$attendanceThreshold%'),
          _SummaryRow(
            label: 'Kekerapan Semakan Laporan',
            value: _reportFrequencyLabel(reportFrequency),
          ),
          _SummaryRow(label: 'Semester Aktif', value: 'Semester $semester'),
          _SummaryRow(label: 'Sesi Akademik Aktif', value: activeSession),
        ],
      ),
    );
  }
}

class _ReviewNeededPanel extends StatelessWidget {
  const _ReviewNeededPanel({
    required this.inactiveAccounts,
    required this.lecturerProfilesWithoutLogin,
  });

  final int inactiveAccounts;
  final int lecturerProfilesWithoutLogin;

  @override
  Widget build(BuildContext context) {
    final issues = <({IconData icon, String label, String value})>[
      if (inactiveAccounts > 0)
        (
          icon: Icons.person_off_outlined,
          label: 'Akaun tidak aktif',
          value: '$inactiveAccounts',
        ),
      if (lecturerProfilesWithoutLogin > 0)
        (
          icon: Icons.badge_outlined,
          label: 'Profil pensyarah tanpa akaun login',
          value: '$lecturerProfilesWithoutLogin',
        ),
    ];

    return AppPanel(
      title: 'Perlu Semakan',
      subtitle: 'Isu akaun dan profil yang memerlukan perhatian pentadbir.',
      child: issues.isEmpty
          ? Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xfff8fafc),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xffe2e8f0)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle_outline, color: Color(0xff16a34a)),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Tiada isu akaun dikesan.',
                      style: TextStyle(
                        color: Color(0xff475569),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            )
          : Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final issue in issues)
                  _ReadinessTile(
                    icon: issue.icon,
                    label: issue.label,
                    value: issue.value,
                    warning: true,
                  ),
              ],
            ),
    );
  }
}

class _ReadinessTile extends StatelessWidget {
  const _ReadinessTile({
    required this.label,
    required this.value,
    this.icon = Icons.check_circle_outline,
    this.warning = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    final color = warning ? const Color(0xffb45309) : const Color(0xff0f766e);
    return Container(
      width: 210,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: warning ? const Color(0xfffffbeb) : const Color(0xfff0fdfa),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: warning ? const Color(0xfffde68a) : const Color(0xff99f6e4),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xff64748b),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
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

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xff475569),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: Color(0xff0f172a),
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _activeSessionLabel(AppState state) {
  final sessions = state.academicSessions;
  final current = state.session;
  final selected = sessions.where((item) => item.academicSessionId == current);
  if (selected.isNotEmpty) return selected.first.name;
  return current;
}

List<TimetableSlot> _currentSessionSlots(AppState state) {
  return state.scopedTimetable
      .where((slot) =>
          slot.academicSessionId == null ||
          slot.academicSessionId!.isEmpty ||
          slot.academicSessionId == state.session)
      .toList();
}

bool _isActiveSlot(TimetableSlot slot) {
  final status = slot.status.trim().toLowerCase();
  return status == 'active' ||
      status == 'attendance pending' ||
      status == 'attendance not taken';
}

bool _isPendingStatus(String status) {
  final normalized = _normalizeStatusKey(status);
  return normalized == 'pending' ||
      normalized == 'menunggu' ||
      normalized == 'menunggu_kelulusan';
}

bool _isPendingDisciplineStatus(String status) {
  final normalized = _normalizeStatusKey(status);
  return normalized == 'pending' ||
      normalized == 'submitted' ||
      normalized == 'new' ||
      normalized == 'menunggu' ||
      normalized == 'menunggu_semakan';
}

bool _isApprovedStatus(String status) {
  final normalized = _normalizeStatusKey(status);
  return normalized == 'approved' ||
      normalized == 'diluluskan' ||
      normalized == 'completed' ||
      normalized == 'selesai';
}

bool _isRejectedStatus(String status) {
  final normalized = _normalizeStatusKey(status);
  return normalized == 'rejected' || normalized == 'ditolak';
}

String _normalizeStatusKey(String status) {
  return status.trim().toLowerCase().replaceAll(' ', '_');
}

bool _hasCompletedAttendance(AppState state, TimetableSlot slot) {
  final slotStatus = slot.status.trim().toLowerCase();
  if (slotStatus == 'attendance completed') return true;
  return state.scopedAttendanceSessions.any((session) =>
      session.slotId == slot.id &&
      session.status.trim().toLowerCase() == 'submitted');
}

int _countTimetableConflicts(List<TimetableSlot> slots) {
  var count = 0;
  for (var i = 0; i < slots.length; i++) {
    for (var j = i + 1; j < slots.length; j++) {
      final a = slots[i];
      final b = slots[j];
      if (a.day != b.day) continue;
      if (!_timeOverlaps(a, b) || !_weekOverlaps(a, b)) continue;
      final sameLecturer =
          a.lecturerId.trim().isNotEmpty && a.lecturerId == b.lecturerId;
      if (_sameRoom(a, b) || sameLecturer || a.section == b.section) {
        count++;
      }
    }
  }
  return count;
}

bool _sameRoom(TimetableSlot a, TimetableSlot b) {
  final roomA = a.roomId?.trim().isNotEmpty == true ? a.roomId : a.roomName;
  final roomB = b.roomId?.trim().isNotEmpty == true ? b.roomId : b.roomName;
  return roomA != null && roomA.isNotEmpty && roomA == roomB;
}

bool _timeOverlaps(TimetableSlot a, TimetableSlot b) {
  final startA = _timeMinutes(a.startTime);
  final endA = _timeMinutes(a.endTime);
  final startB = _timeMinutes(b.startTime);
  final endB = _timeMinutes(b.endTime);
  if (startA == null || endA == null || startB == null || endB == null) {
    return false;
  }
  return startA < endB && startB < endA;
}

int? _timeMinutes(String value) {
  final parts = value.split(':');
  if (parts.length != 2) return null;
  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);
  if (hour == null || minute == null) return null;
  return hour * 60 + minute;
}

bool _weekOverlaps(TimetableSlot a, TimetableSlot b) {
  final startA = int.tryParse(a.weekStart ?? '') ?? 1;
  final endA = int.tryParse(a.weekEnd ?? '') ?? 18;
  final startB = int.tryParse(b.weekStart ?? '') ?? 1;
  final endB = int.tryParse(b.weekEnd ?? '') ?? 18;
  return startA <= endB && startB <= endA;
}

String _slotProgramId(TimetableSlot slot) {
  final normalized = slot.programId?.trim();
  if (normalized != null && normalized.isNotEmpty) return normalized;
  final sectionPrefix = slot.section.split(' ').firstOrNull;
  if (sectionPrefix != null && sectionPrefix.isNotEmpty) return sectionPrefix;
  return slot.program;
}

String _departmentShortLabel(AppState state, String? departmentId) {
  if (departmentId == null || departmentId.isEmpty) return 'Jabatan';
  final department =
      state.departments.where((item) => item.id == departmentId).firstOrNull;
  if (department == null) return departmentId;
  final lower = department.name.toLowerCase();
  if (lower.contains('elektrik')) return 'Elektrik';
  if (lower.contains('mekanikal')) return 'Mekanikal';
  if (lower.contains('automotif')) return 'Automotif';
  return department.name;
}

int _dayOrder(String day) {
  return switch (day.trim().toLowerCase()) {
    'isnin' => 1,
    'selasa' => 2,
    'rabu' => 3,
    'khamis' => 4,
    'jumaat' => 5,
    'sabtu' => 6,
    'ahad' => 7,
    _ => 99,
  };
}

int _compareSlotsBySchedule(TimetableSlot a, TimetableSlot b) {
  final day = _dayOrder(a.day).compareTo(_dayOrder(b.day));
  if (day != 0) return day;
  return a.startTime.compareTo(b.startTime);
}

String _roomLabel(TimetableSlot slot) {
  final roomName = slot.roomName?.trim();
  if (roomName != null && roomName.isNotEmpty) return roomName;
  final roomId = slot.roomId?.trim();
  if (roomId != null && roomId.isNotEmpty) return roomId;
  return slot.room;
}

String _statusLabel(String status) {
  final normalized = status.trim().toLowerCase().replaceAll('_', ' ');
  return switch (normalized) {
    'active' => 'Aktif',
    'inactive' => 'Tidak Aktif',
    'cancelled' || 'canceled' => 'Dibatalkan',
    'attendance pending' => 'Kehadiran Menunggu',
    'attendance completed' => 'Kehadiran Selesai',
    _ => status,
  };
}

String _reportFrequencyLabel(String value) {
  return switch (value) {
    'Weekly' => 'Mingguan',
    'Monthly' => 'Bulanan',
    _ => value,
  };
}

int _lecturerProfilesWithoutLogin(
  List<Lecturer> lecturers,
  List<AppUser> users,
) {
  final userEmails = users.map((user) => user.email.toLowerCase()).toSet();
  return lecturers
      .where((lecturer) => !userEmails.contains(lecturer.email.toLowerCase()))
      .length;
}
