import 'package:flutter/material.dart';

import '../../models/app_models.dart';
import '../../services/user_timetable_service.dart';
import '../../widgets/app_layout.dart';

class AdminUserManagementScreen extends StatefulWidget {
  const AdminUserManagementScreen({super.key});

  @override
  State<AdminUserManagementScreen> createState() =>
      _AdminUserManagementScreenState();
}

class _AdminUserManagementScreenState extends State<AdminUserManagementScreen> {
  late final UserTimetableService _service;

  final Map<String, bool> _activeOverrides = {};

  final TextEditingController _userSearchController = TextEditingController();
  final TextEditingController _studentSearchController = TextEditingController();
  final TextEditingController _lecturerSearchController = TextEditingController();

  UserRole? _selectedRoleFilter;
  String? _selectedProgramFilter;
  String? _selectedDepartmentFilter;
  String? _selectedSubjectFilter;
  String? _selectedLecturerClassFilter;
  String? _selectedClassFilter;
  String? _selectedSemesterFilter;

  String _userSearchQuery = '';
  String _studentSearchQuery = '';
  String _lecturerSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _service = UserTimetableService();
    _userSearchController.addListener(() {
      setState(() => _userSearchQuery = _userSearchController.text.toLowerCase());
    });
    _studentSearchController.addListener(() {
      setState(() => _studentSearchQuery = _studentSearchController.text.toLowerCase());
    });
    _lecturerSearchController.addListener(() {
      setState(() => _lecturerSearchQuery = _lecturerSearchController.text.toLowerCase());
    });
  }

  @override
  void dispose() {
    _userSearchController.dispose();
    _studentSearchController.dispose();
    _lecturerSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Container(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: AppPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const PageHeader(
                  title: 'Pengurusan Pengguna',
                  subtitle:
                      'Pantau dan uruskan pengguna sistem, senarai pelajar, dan penugasan subjek pensyarah.',
                ),
                TabBar(
                  labelColor: Theme.of(context).colorScheme.primary,
                  unselectedLabelColor: const Color(0xff64748b),
                  indicatorColor: Theme.of(context).colorScheme.primary,
                  indicatorWeight: 3,
                  tabs: const [
                    Tab(text: 'Pengguna Sistem'),
                    Tab(text: 'Senarai Pelajar'),
                    Tab(text: 'Kursus Pensyarah'),
                  ],
                ),
                const SizedBox(height: 18),
                SizedBox(
                  height: 600,
                  child: TabBarView(
                    children: [
                      _buildSystemUsersTab(),
                      _buildStudentsTab(),
                      _buildLecturerCoursesTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar({
    required TextEditingController controller,
    required String hint,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 13, color: Color(0xff94a3b8)),
        prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xff94a3b8)),
        suffixIcon: controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.close, size: 16, color: Color(0xff94a3b8)),
                onPressed: () => controller.clear(),
              )
            : null,
        filled: true,
        fillColor: const Color(0xfff8fafc),
        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xffe2e8f0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xffe2e8f0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
        ),
      ),
    );
  }

  Widget _buildFilterDropdown<T>({
    required T value,
    required String hint,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return DropdownButtonHideUnderline(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xfff8fafc),
          border: Border.all(color: const Color(0xffe2e8f0)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: DropdownButton<T>(
          value: value,
          hint: Text(hint,
              style: const TextStyle(fontSize: 13, color: Color(0xff64748b))),
          icon: const Icon(Icons.keyboard_arrow_down, size: 18),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }

  // ===========================================================================
  // Tab 1: System Users — full-width table
  // ===========================================================================
  Widget _buildSystemUsersTab() {
    return StreamBuilder<List<AppUser>>(
      stream: _service.getUsersStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Ralat memuat data: ${snapshot.error}'));
        }
        final allUsers = snapshot.data ?? [];

        final users = allUsers.where((u) {
          final matchesSearch = _userSearchQuery.isEmpty ||
              u.name.toLowerCase().contains(_userSearchQuery) ||
              u.email.toLowerCase().contains(_userSearchQuery) ||
              (u.departmentId?.toLowerCase().contains(_userSearchQuery) ?? false);
          final matchesRole =
              _selectedRoleFilter == null || u.role == _selectedRoleFilter;
          return matchesSearch && matchesRole;
        }).toList();

        if (allUsers.isEmpty) {
          return const Center(
            child: AppPanel(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text('Tiada pengguna sistem ditemui.'),
              ),
            ),
          );
        }

        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildSearchBar(
                    controller: _userSearchController,
                    hint: 'Cari nama, emel, atau jabatan...',
                  ),
                ),
                const SizedBox(width: 12),
                _buildFilterDropdown<UserRole?>(
                  value: _selectedRoleFilter,
                  hint: 'Semua Peranan',
                  items: [
                    const DropdownMenuItem(
                        value: null,
                        child: Text('Semua Peranan',
                            style: TextStyle(fontSize: 13))),
                    ...UserRole.values.map((role) => DropdownMenuItem(
                          value: role,
                          child: Text(_roleLabel(role),
                              style: const TextStyle(fontSize: 13)),
                        )),
                  ],
                  onChanged: (v) => setState(() => _selectedRoleFilter = v),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${users.length} pengguna dijumpai',
                style: const TextStyle(fontSize: 12, color: Color(0xff94a3b8)),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: users.isEmpty
                  ? const Center(child: Text('Tiada hasil carian.'))
                  : Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                    minWidth: constraints.maxWidth),
                                child: DataTable(
                                  headingRowColor: WidgetStateProperty.all(
                                      const Color(0xfff8fafc)),
                                  headingTextStyle: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: Color(0xff475569),
                                  ),
                                  dataTextStyle: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xff0f172a),
                                  ),
                                  columnSpacing: 20,
                                  dataRowMinHeight: 56,
                                  dataRowMaxHeight: 56,
                                  columns: const [
                                    DataColumn(label: Text('Nama')),
                                    DataColumn(label: Text('Emel')),
                                    DataColumn(label: Text('Peranan')),
                                    DataColumn(label: Text('Jabatan')),
                                    DataColumn(label: Text('Status')),
                                    DataColumn(label: Text('Log Masuk Akhir')),
                                    DataColumn(label: Text('Tindakan')),
                                  ],
                                  rows: users.map((user) {
                                    final bool isActive =
                                        _activeOverrides.containsKey(user.uid)
                                            ? _activeOverrides[user.uid]!
                                            : user.isActive;
                                    return DataRow(cells: [
                                      DataCell(SizedBox(
                                        width: 160,
                                        child: Text(
                                          user.name,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      )),
                                      DataCell(Text(
                                        user.email,
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xff64748b)),
                                      )),
                                      DataCell(_buildRoleBadge(user.role)),
                                      DataCell(Text(
                                        user.departmentId ?? '—',
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xff64748b)),
                                      )),
                                      DataCell(_buildStatusBadge(isActive)),
                                      DataCell(Text(
                                        user.lastLogin.isNotEmpty
                                            ? user.lastLogin.substring(0, 16)
                                            : '—',
                                        style: const TextStyle(
                                            fontSize: 11,
                                            color: Color(0xff94a3b8)),
                                      )),
                                      DataCell(Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          _buildActionIcon(
                                            icon: Icons.edit_outlined,
                                            tooltip: 'Edit',
                                            color: const Color(0xff3b82f6),
                                            onTap: () =>
                                                _showEditUserDialog(user),
                                          ),
                                          const SizedBox(width: 4),
                                          _buildActionIcon(
                                            icon: isActive
                                                ? Icons.toggle_on_outlined
                                                : Icons.toggle_off_outlined,
                                            tooltip: isActive
                                                ? 'Nyahaktifkan'
                                                : 'Aktifkan',
                                            color: isActive
                                                ? Colors.green
                                                : Colors.grey,
                                            onTap: () {
                                              final next = !isActive;
                                              setState(() => _activeOverrides[
                                                  user.uid] = next);
                                              _handleUserStatusToggle(
                                                  user.uid, next);
                                            },
                                          ),
                                          const SizedBox(width: 4),
                                          _buildActionIcon(
                                            icon: Icons.key_outlined,
                                            tooltip:
                                                'Tetapkan Semula Kata Laluan',
                                            color: const Color(0xff94a3b8),
                                            onTap: () {},
                                          ),
                                        ],
                                      )),
                                    ]);
                                  }).toList(),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatusBadge(bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isActive
            ? Colors.green.withValues(alpha: 0.1)
            : Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isActive ? 'Aktif' : 'Tidak Aktif',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isActive ? Colors.green.shade700 : Colors.red.shade700,
        ),
      ),
    );
  }

  Widget _buildActionIcon({
    required IconData icon,
    required String tooltip,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }

  void _showEditUserDialog(AppUser user) {
    final nameController = TextEditingController(text: user.name);
    final emailController = TextEditingController(text: user.email);
    final deptController =
        TextEditingController(text: user.departmentId ?? '');
    UserRole selectedRole = user.role;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Container(
            width: 480,
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Edit Pengguna',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.of(ctx).pop(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildDialogField(
                    label: 'Nama', controller: nameController),
                const SizedBox(height: 16),
                _buildDialogField(
                    label: 'Emel',
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Peranan',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Color(0xff374151))),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<UserRole>(
                      value: selectedRole,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xfff9fafb),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                                color: Color(0xffe5e7eb))),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                                color: Color(0xffe5e7eb))),
                      ),
                      items: UserRole.values
                          .map((r) => DropdownMenuItem(
                                value: r,
                                child: Text(_roleLabel(r),
                                    style: const TextStyle(fontSize: 13)),
                              ))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) {
                          setDialogState(() => selectedRole = v);
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildDialogField(
                    label: 'Jabatan', controller: deptController),
                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                      ),
                      child: const Text('Batal',
                          style: TextStyle(color: Color(0xff6b7280))),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Maklumat pengguna dikemaskini.'),
                            backgroundColor: Colors.green,
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Simpan'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDialogField({
    required String label,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xff374151))),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xfff9fafb),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xffe5e7eb))),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xffe5e7eb))),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary)),
          ),
        ),
      ],
    );
  }

  String _roleLabel(UserRole role) {
    switch (role) {
      case UserRole.pentadbir:
        return 'Pentadbir';
      case UserRole.ketua_jabatan:
        return 'Ketua Jabatan';
      case UserRole.ketua_program:
        return 'Ketua Program';
      case UserRole.pensyarah:
        return 'Pensyarah';
    }
  }

  Widget _buildRoleBadge(UserRole role) {
    Color color;
    String label;
    switch (role) {
      case UserRole.pentadbir:
        color = Colors.red;
        label = 'Pentadbir';
        break;
      case UserRole.ketua_jabatan:
        color = Colors.blue;
        label = 'Ketua Jabatan';
        break;
      case UserRole.ketua_program:
        color = Colors.teal;
        label = 'Ketua Program';
        break;
      case UserRole.pensyarah:
        color = Colors.orange;
        label = 'Pensyarah';
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.24)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  void _handleUserStatusToggle(String uid, bool nextState) async {
    try {
      await _service.updateUserStatus(uid, nextState);
      if (!mounted) return;
      setState(() => _activeOverrides.remove(uid));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Status pengguna berjaya dikemaskini.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _activeOverrides[uid] = !nextState);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menukar status: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  // ===========================================================================
  // Tab 2: Students — table layout matching reference image
  // ===========================================================================
  Widget _buildStudentsTab() {
    return StreamBuilder<List<Student>>(
      stream: _service.getStudentsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Ralat memuat data: ${snapshot.error}'));
        }
        final allStudents = snapshot.data ?? [];

        final programs = allStudents.map((s) => s.program).toSet().toList()
          ..sort();
        final classes = allStudents
            .map((s) => s.section)
            .where((c) => c.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
        final semesters = allStudents
            .map((s) => s.semester.toString())
            .toSet()
            .toList()
          ..sort();

        final students = allStudents.where((s) {
          final matchesSearch = _studentSearchQuery.isEmpty ||
              s.name.toLowerCase().contains(_studentSearchQuery) ||
              s.email.toLowerCase().contains(_studentSearchQuery) ||
              s.id.toLowerCase().contains(_studentSearchQuery) ||
              s.section.toLowerCase().contains(_studentSearchQuery);
          final matchesProgram = _selectedProgramFilter == null ||
              s.program == _selectedProgramFilter;
          final matchesClass =
              _selectedClassFilter == null || s.section == _selectedClassFilter;
          final matchesSemester = _selectedSemesterFilter == null ||
              s.semester.toString() == _selectedSemesterFilter;
          return matchesSearch && matchesProgram && matchesClass && matchesSemester;
        }).toList();

        if (allStudents.isEmpty) {
          return const Center(
            child: AppPanel(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text('Tiada pelajar ditemui.'),
              ),
            ),
          );
        }

        return Column(
          children: [
            // Filters row matching reference: Course, Class, Semester, Search
            Row(
              children: [
                _buildFilterDropdown<String?>(
                  value: _selectedProgramFilter,
                  hint: 'Semua Kursus',
                  items: [
                    const DropdownMenuItem(
                        value: null,
                        child: Text('Semua Kursus',
                            style: TextStyle(fontSize: 13))),
                    ...programs.map((p) => DropdownMenuItem(
                        value: p,
                        child: Text(p, style: const TextStyle(fontSize: 13)))),
                  ],
                  onChanged: (v) => setState(() => _selectedProgramFilter = v),
                ),
                const SizedBox(width: 12),
                _buildFilterDropdown<String?>(
                  value: _selectedClassFilter,
                  hint: 'Semua Kelas',
                  items: [
                    const DropdownMenuItem(
                        value: null,
                        child: Text('Semua Kelas',
                            style: TextStyle(fontSize: 13))),
                    ...classes.map((c) => DropdownMenuItem(
                        value: c,
                        child: Text(c, style: const TextStyle(fontSize: 13)))),
                  ],
                  onChanged: (v) => setState(() => _selectedClassFilter = v),
                ),
                const SizedBox(width: 12),
                _buildFilterDropdown<String?>(
                  value: _selectedSemesterFilter,
                  hint: 'Semua Semester',
                  items: [
                    const DropdownMenuItem(
                        value: null,
                        child: Text('Semua Semester',
                            style: TextStyle(fontSize: 13))),
                    ...semesters.map((s) => DropdownMenuItem(
                        value: s,
                        child: Text('Sem $s',
                            style: const TextStyle(fontSize: 13)))),
                  ],
                  onChanged: (v) =>
                      setState(() => _selectedSemesterFilter = v),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSearchBar(
                    controller: _studentSearchController,
                    hint: 'Nama, ID, kelas...',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Text('${students.length} pelajar dijumpai',
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xff94a3b8))),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: students.isEmpty
                  ? const Center(child: Text('Tiada hasil carian.'))
                  : Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                    minWidth: constraints.maxWidth),
                                child: DataTable(
                                  headingRowColor: WidgetStateProperty.all(
                                      const Color(0xfff8fafc)),
                                  headingTextStyle: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: Color(0xff475569),
                                  ),
                                  dataTextStyle: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xff0f172a),
                                  ),
                                  columnSpacing: 16,
                                  dataRowMinHeight: 56,
                                  dataRowMaxHeight: 56,
                                  columns: const [
                                    DataColumn(label: Text('ID')),
                                    DataColumn(label: Text('Nama')),
                                    DataColumn(label: Text('Emel')),
                                    DataColumn(label: Text('Telefon')),
                                    DataColumn(label: Text('Program')),
                                    DataColumn(label: Text('Seksyen')),
                                    DataColumn(label: Text('Sem'), numeric: true),
                                    DataColumn(label: Text('Status')),
                                    DataColumn(label: Text('Att %'), numeric: true),
                                    DataColumn(label: Text('Tindakan')),
                                  ],
                                  rows: students.map((student) {
                                    final bool isSafe = student.attendance >= 80;
                                    final Color attColor =
                                        isSafe ? Colors.green : Colors.red;
                                    return DataRow(cells: [
                                      // ID
                                      DataCell(Text(
                                        student.id,
                                        style: const TextStyle(
                                            fontSize: 11,
                                            color: Color(0xff64748b),
                                            fontWeight: FontWeight.w500),
                                      )),
                                      // Name
                                      DataCell(SizedBox(
                                        width: 160,
                                        child: Text(
                                          student.name,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      )),
                                      // Email
                                      DataCell(SizedBox(
                                        width: 180,
                                        child: Text(
                                          student.email,
                                          style: const TextStyle(
                                              fontSize: 11,
                                              color: Color(0xff64748b)),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      )),
                                      // Phone
                                      DataCell(Text(
                                        student.phone,
                                        style: const TextStyle(
                                            fontSize: 11,
                                            color: Color(0xff64748b)),
                                      )),
                                      // Program — full name as plain text (e.g. "Electrical Installation")
                                      DataCell(SizedBox(
                                        width: 160,
                                        child: Text(
                                          student.program,
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: Color(0xff0f172a)),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      )),
                                      // Section
                                      DataCell(Text(
                                        student.section,
                                        style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500),
                                      )),
                                      // Semester
                                      DataCell(Center(
                                        child: Text(
                                          '${student.semester}',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      )),
                                      // Status
                                      DataCell(_buildStatusBadge(student.active)),
                                      // Attendance % with bar
                                      DataCell(SizedBox(
                                        width: 80,
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '${student.attendance}%',
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: attColor),
                                            ),
                                            const SizedBox(height: 4),
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                              child: LinearProgressIndicator(
                                                value:
                                                    student.attendance / 100.0,
                                                backgroundColor:
                                                    const Color(0xffe2e8f0),
                                                color: attColor,
                                                minHeight: 6,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )),
                                      // Action — eye icon only
                                      DataCell(
                                        _buildActionIcon(
                                          icon: Icons.visibility_outlined,
                                          tooltip: 'Lihat Profil',
                                          color: const Color(0xff3b82f6),
                                          onTap: () =>
                                              _showStudentDetailDialog(student),
                                        ),
                                      ),
                                    ]);
                                  }).toList(),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  /// Student detail modal — mirrors the reference image (Image 2)
  void _showStudentDetailDialog(Student student) {
    // Mock per-subject attendance data based on the student model.
    // In production, load from AttendanceRecord stream filtered by studentId.
    final mockSubjects = _generateMockSubjectAttendance(student);

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 560,
            maxHeight: MediaQuery.of(ctx).size.height * 0.85,
          ),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: SingleChildScrollView(
              child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      student.name,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.of(ctx).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Info grid — matches reference image layout
              _buildDetailGrid([
                _DetailField(label: 'Student ID', value: student.id),
                // TODO: replace '—' with student.ic once added to Student model
                _DetailField(label: 'IC', value: '—'),
                _DetailField(label: 'Seksyen', value: student.section),
                _DetailField(label: 'Emel', value: student.email),
                _DetailField(label: 'Telefon', value: student.phone),
                _DetailField(
                    label: 'Semester', value: student.semester.toString()),
                _DetailField(label: 'Program', value: student.program),
                _DetailField(
                    label: 'Kehadiran',
                    value: '${student.attendance}%',
                    highlight: true,
                    highlightColor: student.attendance >= 80
                        ? Colors.green
                        : Colors.red),
                _DetailField(
                    label: 'Status',
                    value: student.active ? 'Aktif' : 'Tidak Aktif'),
              ]),
              const SizedBox(height: 20),
              // Overall attendance bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Kehadiran Keseluruhan',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xff374151))),
                  Text(
                    '${student.attendance}%',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: student.attendance >= 80
                            ? Colors.green
                            : Colors.red),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: student.attendance / 100.0,
                  backgroundColor: const Color(0xffe2e8f0),
                  color:
                      student.attendance >= 80 ? Colors.green : Colors.red,
                  minHeight: 10,
                ),
              ),
              const SizedBox(height: 20),
              const Divider(height: 1, color: Color(0xffe2e8f0)),
              const SizedBox(height: 16),
              // Subjects attendance table
              const Text(
                'Kehadiran Mengikut Subjek',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff0f172a)),
              ),
              const SizedBox(height: 10),
              // Table header
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xfff8fafc),
                  borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(8),
                      topRight: Radius.circular(8)),
                  border: Border.all(color: const Color(0xffe2e8f0)),
                ),
                child: const Row(
                  children: [
                    Expanded(
                        flex: 3,
                        child: Text('Subjek',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xff475569)))),
                    Expanded(
                        flex: 2,
                        child: Text('Sesi',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xff475569)))),
                    Expanded(
                        flex: 2,
                        child: Text('Att %',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xff475569)))),
                  ],
                ),
              ),
              // Table rows
              Container(
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(color: Colors.grey.shade200),
                    right: BorderSide(color: Colors.grey.shade200),
                    bottom: BorderSide(color: Colors.grey.shade200),
                  ),
                  borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(8),
                      bottomRight: Radius.circular(8)),
                ),
                child: Column(
                  children: mockSubjects.asMap().entries.map((entry) {
                    final isLast = entry.key == mockSubjects.length - 1;
                    final subj = entry.value;
                    final pct = subj['percentage'] as int;
                    final attColor = pct >= 80 ? Colors.green : Colors.red;
                    return Container(
                      decoration: BoxDecoration(
                        border: isLast
                            ? null
                            : Border(
                                bottom: BorderSide(
                                    color: Colors.grey.shade100)),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      child: Row(
                        children: [
                          // Subject code
                          Expanded(
                            flex: 3,
                            child: Text(
                              subj['subjectCode'] as String,
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xff0f172a)),
                            ),
                          ),
                          // Sessions
                          Expanded(
                            flex: 2,
                            child: Text(
                              '${subj['sessions']}',
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xff475569)),
                            ),
                          ),
                          // Percentage with mini bar
                          Expanded(
                            flex: 2,
                            child: Row(
                              children: [
                                Text(
                                  '$pct%',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: attColor),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: pct / 100.0,
                                      backgroundColor:
                                          const Color(0xffe2e8f0),
                                      color: attColor,
                                      minHeight: 6,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),
              // Close button
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Tutup'),
                ),
              ),
            ],
          ),
            ),
          ),
        ),
      ),
    );
  }

  /// Detail info grid for student modal (2-column layout)
  Widget _buildDetailGrid(List<_DetailField> fields) {
    return Wrap(
      spacing: 16,
      runSpacing: 12,
      children: fields.map((f) {
        return SizedBox(
          width: 230,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(f.label,
                  style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xff94a3b8),
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text(
                f.value,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: f.highlight
                        ? (f.highlightColor ?? const Color(0xff0f172a))
                        : const Color(0xff0f172a)),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  /// Generates mock per-subject attendance for the modal.
  /// Replace with a real Firestore query on AttendanceRecord in production.
  List<Map<String, dynamic>> _generateMockSubjectAttendance(Student student) {
    // We derive subject codes from the program abbreviation.
    final prefix = student.program.length >= 2
        ? student.program.substring(0, 2).toUpperCase()
        : 'XX';
    return List.generate(4, (i) {
      final sessions = 18 - i;
      // Spread individual subject % around the overall attendance.
      final base = student.attendance + (i % 2 == 0 ? -5 + i * 3 : 5 - i * 2);
      final clamped = base.clamp(0, 100);
      return {
        'subjectCode': '${prefix}${100 + i + 1}',
        'sessions': sessions,
        'percentage': clamped,
      };
    });
  }

  // ===========================================================================
  // Tab 3: Lecturer Courses (UNCHANGED)
  // ===========================================================================
  Widget _buildLecturerCoursesTab() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _service.getLecturerCoursesStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Ralat memuat data: ${snapshot.error}'));
        }
        final allAssignments = snapshot.data ?? [];

        if (allAssignments.isEmpty) {
          return const Center(
            child: AppPanel(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text('Tiada penugasan kursus pensyarah ditemui.'),
              ),
            ),
          );
        }

        final Map<String, List<Map<String, dynamic>>> grouped = {};
        for (final map in allAssignments) {
          final lid = map['lecturerId']?.toString() ?? 'unknown';
          grouped.putIfAbsent(lid, () => []).add(map);
        }

        final List<Map<String, dynamic>> lecturerRows =
            grouped.entries.map((e) {
          final rows = e.value;
          final first = rows.first;
          final subjects = rows
              .map((m) => m['subjectCode']?.toString() ?? '')
              .where((s) => s.isNotEmpty)
              .toSet()
              .toList()
            ..sort();
          final classes = rows
              .map((m) => m['classId']?.toString() ?? '')
              .where((c) => c.isNotEmpty)
              .toSet()
              .toList()
            ..sort();
          return {
            'lecturerId': first['lecturerId'] ?? '-',
            'lecturerName': first['lecturerName'] ?? '-',
            'lecturerEmail': first['lecturerEmail'] ?? '-',
            'programId': first['programId'] ?? '-',
            'subjects': subjects,
            'classes': classes,
            'classesPerWeek': classes.length,
          };
        }).toList()
          ..sort((a, b) => a['lecturerName']
              .toString()
              .compareTo(b['lecturerName'].toString()));

        final programs = allAssignments
            .map((m) => m['programId']?.toString() ?? '')
            .where((p) => p.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
        final subjectOptions = allAssignments
            .map((m) => m['subjectCode']?.toString() ?? '')
            .where((s) => s.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
        final classOptions = allAssignments
            .map((m) => m['classId']?.toString() ?? '')
            .where((c) => c.isNotEmpty)
            .toSet()
            .toList()
          ..sort();

        final assignments = lecturerRows.where((row) {
          final name = row['lecturerName'].toString().toLowerCase();
          final email = row['lecturerEmail'].toString().toLowerCase();
          final subjects =
              (row['subjects'] as List<String>).join(' ').toLowerCase();
          final prog = row['programId'].toString();
          final matchesSearch = _lecturerSearchQuery.isEmpty ||
              name.contains(_lecturerSearchQuery) ||
              email.contains(_lecturerSearchQuery) ||
              subjects.contains(_lecturerSearchQuery);
          final matchesProg = _selectedDepartmentFilter == null ||
              prog == _selectedDepartmentFilter;
          final matchesSubject = _selectedSubjectFilter == null ||
              (row['subjects'] as List<String>).contains(_selectedSubjectFilter);
          final matchesClass = _selectedLecturerClassFilter == null ||
              (row['classes'] as List<String>)
                  .contains(_selectedLecturerClassFilter);
          return matchesSearch && matchesProg && matchesSubject && matchesClass;
        }).toList();

        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildSearchBar(
                    controller: _lecturerSearchController,
                    hint: 'Cari nama pensyarah atau emel...',
                  ),
                ),
                const SizedBox(width: 12),
                _buildFilterDropdown<String?>(
                  value: _selectedDepartmentFilter,
                  hint: 'Semua Program',
                  items: [
                    const DropdownMenuItem(
                        value: null,
                        child: Text('Semua Program',
                            style: TextStyle(fontSize: 13))),
                    ...programs.map((p) => DropdownMenuItem(
                        value: p,
                        child: Text(p, style: const TextStyle(fontSize: 13)))),
                  ],
                  onChanged: (v) =>
                      setState(() => _selectedDepartmentFilter = v),
                ),
                const SizedBox(width: 12),
                _buildFilterDropdown<String?>(
                  value: _selectedSubjectFilter,
                  hint: 'Semua Subjek',
                  items: [
                    const DropdownMenuItem(
                        value: null,
                        child: Text('Semua Subjek',
                            style: TextStyle(fontSize: 13))),
                    ...subjectOptions.map((s) => DropdownMenuItem(
                        value: s,
                        child: Text(s, style: const TextStyle(fontSize: 13)))),
                  ],
                  onChanged: (v) => setState(() => _selectedSubjectFilter = v),
                ),
                const SizedBox(width: 12),
                _buildFilterDropdown<String?>(
                  value: _selectedLecturerClassFilter,
                  hint: 'Semua Kelas',
                  items: [
                    const DropdownMenuItem(
                        value: null,
                        child: Text('Semua Kelas',
                            style: TextStyle(fontSize: 13))),
                    ...classOptions.map((c) => DropdownMenuItem(
                        value: c,
                        child: Text(c, style: const TextStyle(fontSize: 13)))),
                  ],
                  onChanged: (v) =>
                      setState(() => _selectedLecturerClassFilter = v),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Text('${assignments.length} pensyarah dijumpai',
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xff94a3b8))),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: assignments.isEmpty
                  ? const Center(child: Text('Tiada hasil carian.'))
                  : Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: LayoutBuilder(builder: (context, constraints) {
                        return SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                  minWidth: constraints.maxWidth),
                              child: DataTable(
                                horizontalMargin: 24,
                                headingRowColor: WidgetStateProperty.all(
                                    const Color(0xfff8fafc)),
                                headingTextStyle: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: Color(0xff475569)),
                                dataTextStyle: const TextStyle(
                                    fontSize: 12, color: Color(0xff0f172a)),
                                columnSpacing: 24,
                                columns: const [
                                  DataColumn(label: Text('Nama')),
                                  DataColumn(label: Text('Emel')),
                                  DataColumn(label: Text('Program')),
                                  DataColumn(label: Text('Subjek')),
                                  DataColumn(label: Text('Seksyen')),
                                  DataColumn(
                                      label: Text('Kelas /\nMinggu'),
                                      numeric: true),
                                ],
                                rows: assignments.map((row) {
                                  final subjects =
                                      (row['subjects'] as List<String>)
                                          .join(', ');
                                  final classes =
                                      (row['classes'] as List<String>)
                                          .join(', ');
                                  return DataRow(cells: [
                                    DataCell(SizedBox(
                                        width: 180,
                                        child: Text(
                                            row['lecturerName'].toString(),
                                            maxLines: 2,
                                            overflow:
                                                TextOverflow.ellipsis))),
                                    DataCell(Text(
                                        row['lecturerEmail'].toString(),
                                        style: const TextStyle(
                                            fontSize: 11,
                                            color: Color(0xff64748b)))),
                                    DataCell(_buildLecturerProgramBadge(
                                        row['programId'].toString())),
                                    DataCell(SizedBox(
                                        width: 120,
                                        child: Text(subjects,
                                            style: const TextStyle(
                                                fontSize: 11,
                                                color: Color(0xff475569))))),
                                    DataCell(SizedBox(
                                        width: 150,
                                        child: Text(classes,
                                            style: const TextStyle(
                                                fontSize: 11,
                                                color: Color(0xff475569))))),
                                    DataCell(Center(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xffe0f2fe),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Text('${row['classesPerWeek']}',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                                color: Color(0xff0369a1))),
                                      ),
                                    )),
                                  ]);
                                }).toList(),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLecturerProgramBadge(String programId) {
    const colorMap = {
      'DCB': Colors.purple,
      'DKM': Colors.blue,
      'DEE': Colors.orange,
      'DEM': Colors.teal,
      'DAC': Colors.green,
      'DRB': Colors.indigo,
      'DTK': Colors.cyan,
    };
    final color = colorMap[programId] ?? Colors.blueGrey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(programId,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.bold, color: color)),
    );
  }
}

// Helper class for the student detail modal info grid
class _DetailField {
  const _DetailField({
    required this.label,
    required this.value,
    this.highlight = false,
    this.highlightColor,
  });

  final String label;
  final String value;
  final bool highlight;
  final Color? highlightColor;
}