import 'package:flutter/material.dart';

import '../../models/app_models.dart';
import '../../services/user_timetable_service.dart';
import '../../widgets/app_layout.dart';
import '../../widgets/app_theme.dart';
import '../../widgets/status_chip.dart';

class AdminUserManagementScreen extends StatefulWidget {
  const AdminUserManagementScreen({super.key});

  @override
  State<AdminUserManagementScreen> createState() =>
      _AdminUserManagementScreenState();
}

class _AdminUserManagementScreenState extends State<AdminUserManagementScreen> {
  late final UserTimetableService _service;

  final Map<String, bool> _activeOverrides = {};
  final Set<String> _cancelledAssignments = {};

  final TextEditingController _userSearchController = TextEditingController();
  final TextEditingController _studentSearchController =
      TextEditingController();
  final TextEditingController _lecturerSearchController =
      TextEditingController();

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

  static const List<(String, String)> _departmentOptions = [
    ('elektrik', 'Jabatan Elektrik'),
    ('mekanikal', 'Jabatan Mekanikal'),
    ('automotif', 'Jabatan Automotif'),
  ];

  static const List<(String, String)> _programOptions = [
    ('DED', 'DED - Diploma Teknologi Elektrik'),
    ('DCP', 'DCP - Diploma Teknologi Komputer'),
    ('DCB', 'DCB - Diploma Teknologi Elektronik'),
    ('ITW', 'ITW'),
    ('SLR', 'SLR'),
    ('SMI', 'SMI'),
    ('IMF', 'IMF'),
    ('SMM', 'SMM'),
    ('DMM', 'DMM'),
    ('DGS', 'DGS'),
    ('DPP', 'DPP'),
    ('DEK', 'DEK'),
    ('DGM', 'DGM'),
    ('SMK', 'SMK'),
  ];

  static const Map<String, String> _programDepartments = {
    'DED': 'elektrik',
    'DCP': 'elektrik',
    'DCB': 'elektrik',
    'ITW': 'mekanikal',
    'SLR': 'mekanikal',
    'SMI': 'mekanikal',
    'IMF': 'automotif',
    'SMM': 'automotif',
    'DMM': 'automotif',
  };

  @override
  void initState() {
    super.initState();
    _service = UserTimetableService();
    _userSearchController.addListener(() {
      setState(
          () => _userSearchQuery = _userSearchController.text.toLowerCase());
    });
    _studentSearchController.addListener(() {
      setState(() =>
          _studentSearchQuery = _studentSearchController.text.toLowerCase());
    });
    _lecturerSearchController.addListener(() {
      setState(() =>
          _lecturerSearchQuery = _lecturerSearchController.text.toLowerCase());
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
          padding: const EdgeInsets.all(20.0),
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
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceTint,
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: TabBar(
                    labelColor: AppColors.primaryDark,
                    unselectedLabelColor: AppColors.muted,
                    indicator: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    labelStyle: const TextStyle(fontWeight: FontWeight.w900),
                    tabs: const [
                      Tab(text: 'Pengguna Sistem'),
                      Tab(text: 'Senarai Pelajar'),
                      Tab(text: 'Kursus Pensyarah'),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  height: (MediaQuery.sizeOf(context).height - 300)
                      .clamp(620.0, 860.0),
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
        hintStyle: const TextStyle(fontSize: 13, color: AppColors.muted),
        prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.muted),
        suffixIcon: controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.close, size: 16, color: AppColors.muted),
                onPressed: () => controller.clear(),
              )
            : null,
        filled: true,
        fillColor: AppColors.surfaceTint,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary),
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
    // Cause of the overflow: DropdownButton (without isExpanded) sizes its
    // closed/collapsed width to the WIDEST item in `items`, not to the
    // hint or the currently-selected value. When `items` contains long
    // values (e.g. full programme names from Firestore), the button's
    // intrinsic width can exceed what the parent Wrap has available at
    // narrow viewports, producing "RIGHT OVERFLOWED BY N PIXELS".
    //
    // Fix: cap the whole control with a fixed-but-reasonable max width via
    // ConstrainedBox, set isExpanded: true so the DropdownButton fills that
    // bounded width instead of measuring its children, and ellipsize any
    // text that's still too long to fit.
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 180),
      child: DropdownButtonHideUnderline(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.surfaceTint,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(14),
          ),
          child: DropdownButton<T>(
            value: value,
            isExpanded: true,
            hint: Text(
              hint,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, color: Color(0xff64748b)),
            ),
            icon: const Icon(Icons.keyboard_arrow_down, size: 18),
            items: [
              for (final item in items)
                DropdownMenuItem<T>(
                  value: item.value,
                  child: DefaultTextStyle.merge(
                    style: const TextStyle(
                        fontSize: 13, overflow: TextOverflow.ellipsis),
                    child: item.child,
                  ),
                ),
            ],
            selectedItemBuilder: (context) => [
              for (final item in items)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _dropdownItemText(item) ?? hint,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style:
                        const TextStyle(fontSize: 13, color: Color(0xff0f172a)),
                  ),
                ),
            ],
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }

  /// Best-effort extraction of plain text from a DropdownMenuItem's child,
  /// used so the closed (selected) button can render a single-line,
  /// ellipsized label via [selectedItemBuilder] without re-deriving the
  /// original label string at every call site.
  String? _dropdownItemText(DropdownMenuItem<dynamic> item) {
    final child = item.child;
    if (child is Text) return child.data;
    return null;
  }

  // ===========================================================================
  // Tab 1: System Users
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
              (u.departmentId?.toLowerCase().contains(_userSearchQuery) ??
                  false);
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
            Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 360,
                  child: _buildSearchBar(
                    controller: _userSearchController,
                    hint: 'Cari nama, emel, atau jabatan...',
                  ),
                ),
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
                                              setState(() =>
                                                  _activeOverrides[user.uid] =
                                                      next);
                                              _handleUserStatusToggle(
                                                  user.uid, next);
                                            },
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
    return StatusChip(isActive ? 'Aktif' : 'Tidak Aktif');
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
    UserRole selectedRole = user.role;
    String? selectedDepartmentId = _normalizeDepartmentId(user.departmentId);
    String? selectedProgramId = user.programId;

    void normalizeScopeForRole() {
      if (selectedRole == UserRole.ketua_jabatan) {
        selectedDepartmentId ??= _departmentOptions.first.$1;
        selectedProgramId = null;
      } else if (selectedRole == UserRole.ketua_program) {
        selectedProgramId ??= _programOptions.first.$1;
        selectedDepartmentId = _departmentForProgram(selectedProgramId);
      } else if (selectedRole == UserRole.pentadbir) {
        selectedDepartmentId = null;
        selectedProgramId = null;
      }
    }

    normalizeScopeForRole();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520, maxHeight: 720),
            child: SingleChildScrollView(
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
                  _buildDialogField(label: 'Nama', controller: nameController),
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
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryDark)),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<UserRole>(
                        initialValue: selectedRole,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppColors.surfaceTint,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide:
                                  const BorderSide(color: AppColors.border)),
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide:
                                  const BorderSide(color: AppColors.border)),
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
                            setDialogState(() {
                              selectedRole = v;
                              normalizeScopeForRole();
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (selectedRole == UserRole.ketua_jabatan)
                    _buildScopeDropdown(
                      label: 'Jabatan',
                      value: selectedDepartmentId,
                      items: _departmentOptions,
                      onChanged: (value) =>
                          setDialogState(() => selectedDepartmentId = value),
                    )
                  else if (selectedRole == UserRole.ketua_program) ...[
                    _buildScopeDropdown(
                      label: 'Program',
                      value: selectedProgramId,
                      items: _programOptions,
                      onChanged: (value) => setDialogState(() {
                        selectedProgramId = value;
                        selectedDepartmentId = _departmentForProgram(value);
                      }),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      selectedDepartmentId == null
                          ? 'Jabatan: Tiada Ketua Jabatan'
                          : 'Jabatan: ${_departmentLabel(selectedDepartmentId)}',
                      style: const TextStyle(
                        color: Color(0xff64748b),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
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
                        onPressed: () async {
                          final navigator = Navigator.of(ctx);
                          final messenger = ScaffoldMessenger.of(context);
                          final updated = AppUser(
                            uid: user.uid,
                            name: nameController.text.trim(),
                            email: emailController.text.trim(),
                            role: selectedRole,
                            programId: selectedRole == UserRole.ketua_program
                                ? selectedProgramId
                                : selectedRole == UserRole.pensyarah
                                    ? user.programId
                                    : null,
                            departmentId:
                                selectedRole == UserRole.ketua_jabatan ||
                                        selectedRole == UserRole.ketua_program
                                    ? selectedDepartmentId
                                    : selectedRole == UserRole.pensyarah
                                        ? user.departmentId
                                        : null,
                            lecturerProfileId: user.lecturerProfileId,
                            phoneNumber: user.phoneNumber,
                            isActive:
                                _activeOverrides[user.uid] ?? user.isActive,
                            createdAt: user.createdAt,
                            updatedAt: user.updatedAt,
                          );
                          await _service.updateUserProfile(updated);
                          navigator.pop();
                          messenger.showSnackBar(
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
                fontWeight: FontWeight.w700,
                color: AppColors.primaryDark)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.surfaceTint,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.border)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.border)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.primary)),
          ),
        ),
      ],
    );
  }

  Widget _buildScopeDropdown({
    required String label,
    required String? value,
    required List<(String, String)> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryDark)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: value,
          isExpanded: true,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.surfaceTint,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.border)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.border)),
          ),
          items: items
              .map((item) => DropdownMenuItem<String>(
                    value: item.$1,
                    child: Text(
                      item.$2,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  String? _departmentForProgram(String? programId) {
    if (programId == null || programId.trim().isEmpty) return null;
    return _programDepartments[programId.trim().toUpperCase()];
  }

  String? _normalizeDepartmentId(String? value) {
    final clean = value?.trim().toLowerCase();
    if (clean == null || clean.isEmpty) return null;
    if (clean.contains('elektrik')) return 'elektrik';
    if (clean.contains('mekanikal')) return 'mekanikal';
    if (clean.contains('automotif')) return 'automotif';
    return _departmentOptions.any((item) => item.$1 == clean) ? clean : null;
  }

  String _departmentLabel(String? departmentId) {
    if (departmentId == null || departmentId.isEmpty) return '-';
    return _departmentOptions
            .where((item) => item.$1 == departmentId)
            .map((item) => item.$2)
            .firstOrNull ??
        departmentId;
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
        color = AppColors.danger;
        label = 'Pentadbir';
        break;
      case UserRole.ketua_jabatan:
        color = AppColors.primary;
        label = 'Ketua Jabatan';
        break;
      case UserRole.ketua_program:
        color = AppColors.info;
        label = 'Ketua Program';
        break;
      case UserRole.pensyarah:
        color = AppColors.warning;
        label = 'Pensyarah';
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.24)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.w800)),
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
  // Tab 2: Students
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
          return matchesSearch &&
              matchesProgram &&
              matchesClass &&
              matchesSemester;
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
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 480;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SizedBox(
                      width: isNarrow ? constraints.maxWidth : 320,
                      child: _buildSearchBar(
                        controller: _studentSearchController,
                        hint: 'Nama, ID, kelas...',
                      ),
                    ),
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
                            child:
                                Text(p, style: const TextStyle(fontSize: 13)))),
                      ],
                      onChanged: (v) =>
                          setState(() => _selectedProgramFilter = v),
                    ),
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
                            child:
                                Text(c, style: const TextStyle(fontSize: 13)))),
                      ],
                      onChanged: (v) =>
                          setState(() => _selectedClassFilter = v),
                    ),
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
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Text('${students.length} pelajar dijumpai',
                  style:
                      const TextStyle(fontSize: 12, color: Color(0xff94a3b8))),
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
                                    DataColumn(
                                        label: Text('Sem'), numeric: true),
                                    DataColumn(label: Text('Status')),
                                    DataColumn(
                                        label: Text('Att %'), numeric: true),
                                    DataColumn(label: Text('Tindakan')),
                                  ],
                                  rows: students.map((student) {
                                    final bool isSafe =
                                        student.attendance >= 80;
                                    final Color attColor =
                                        isSafe ? Colors.green : Colors.red;
                                    return DataRow(cells: [
                                      DataCell(Text(
                                        student.id,
                                        style: const TextStyle(
                                            fontSize: 11,
                                            color: Color(0xff64748b),
                                            fontWeight: FontWeight.w500),
                                      )),
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
                                      DataCell(Text(
                                        student.phone,
                                        style: const TextStyle(
                                            fontSize: 11,
                                            color: Color(0xff64748b)),
                                      )),
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
                                      DataCell(Text(
                                        student.section,
                                        style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500),
                                      )),
                                      DataCell(Center(
                                        child: Text(
                                          '${student.semester}',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      )),
                                      DataCell(
                                          _buildStatusBadge(student.active)),
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

  void _showStudentDetailDialog(Student student) {
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
                  _buildDetailGrid([
                    _DetailField(label: 'Student ID', value: student.id),
                    const _DetailField(label: 'IC', value: '—'),
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
                  const Text(
                    'Kehadiran Mengikut Subjek',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xff0f172a)),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                              Expanded(
                                flex: 2,
                                child: Text(
                                  '${subj['sessions']}',
                                  style: const TextStyle(
                                      fontSize: 12, color: Color(0xff475569)),
                                ),
                              ),
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

  List<Map<String, dynamic>> _generateMockSubjectAttendance(Student student) {
    final prefix = student.program.length >= 2
        ? student.program.substring(0, 2).toUpperCase()
        : 'XX';
    return List.generate(4, (i) {
      final sessions = 18 - i;
      final base = student.attendance + (i % 2 == 0 ? -5 + i * 3 : 5 - i * 2);
      final clamped = base.clamp(0, 100);
      return {
        'subjectCode': '$prefix${100 + i + 1}',
        'sessions': sessions,
        'percentage': clamped,
      };
    });
  }

  // ===========================================================================
  // Tab 3: Lecturer Courses
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

        // ── Group raw assignment docs by lecturerId ──────────────────────────
        final Map<String, List<Map<String, dynamic>>> grouped = {};
        for (final map in allAssignments) {
          final lid = map['lecturerId']?.toString() ?? 'unknown';
          grouped.putIfAbsent(lid, () => []).add(map);
        }

        final List<Map<String, dynamic>> lecturerRows = grouped.entries
            .map((e) {
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

          // Extract latest date from the assignment documents
          final dates = rows
              .map((m) =>
                  m['date']?.toString() ?? m['createdAt']?.toString() ?? '')
              .where((d) => d.isNotEmpty)
              .toList()
            ..sort();
          final latestDate = dates.isNotEmpty ? dates.last : '';

          return {
            'lecturerId': first['lecturerId'] ?? '-',
            'lecturerName': first['lecturerName'] ?? '-',
            'lecturerEmail': first['lecturerEmail'] ?? '-',
            'programId': first['programId'] ?? '-',
            'subjects': subjects,
            'classes': classes,
            'classesPerWeek': classes.length,
            'appUser': first['appUser'],
            // ✅ NEW: raw assignment id for undo cancel
            'assignmentId': first['id']?.toString() ??
                first['lecturerId']?.toString() ??
                '-',
            // ✅ NEW: date field for display
            'latestDate': latestDate,
          };
        }).toList()
          ..sort((a, b) => a['lecturerName']
              .toString()
              .compareTo(b['lecturerName'].toString()));

        // ── Filter options ───────────────────────────────────────────────────
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

        // ── Apply filters + search ───────────────────────────────────────────
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
              (row['subjects'] as List<String>)
                  .contains(_selectedSubjectFilter);
          final matchesClass = _selectedLecturerClassFilter == null ||
              (row['classes'] as List<String>)
                  .contains(_selectedLecturerClassFilter);
          return matchesSearch && matchesProg && matchesSubject && matchesClass;
        }).toList();

        return Column(
          children: [
            // ── Filter bar ─────────────────────────────────────────────────
            Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 340,
                  child: _buildSearchBar(
                    controller: _lecturerSearchController,
                    hint: 'Cari nama pensyarah atau emel...',
                  ),
                ),
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
                  style:
                      const TextStyle(fontSize: 12, color: Color(0xff94a3b8))),
            ),
            const SizedBox(height: 8),

            // ── DataTable ──────────────────────────────────────────────────
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
                                horizontalMargin: 16,
                                headingRowColor: WidgetStateProperty.all(
                                    const Color(0xfff8fafc)),
                                headingTextStyle: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: Color(0xff475569)),
                                dataTextStyle: const TextStyle(
                                    fontSize: 12, color: Color(0xff0f172a)),
                                columnSpacing: 16,
                                dataRowMinHeight: 60,
                                dataRowMaxHeight: 72,
                                columns: const [
                                  DataColumn(label: Text('Nama')),
                                  DataColumn(label: Text('Emel')),
                                  DataColumn(label: Text('Jabatan')),
                                  DataColumn(label: Text('Subjek')),
                                  DataColumn(label: Text('Seksyen')),
                                  DataColumn(
                                      label: Text('Kelas /\nMinggu'),
                                      numeric: true),
                                  DataColumn(label: Text('Tindakan')),
                                ],
                                rows: assignments.map((row) {
                                  final subjects =
                                      (row['subjects'] as List<String>)
                                          .join(', ');
                                  final classes =
                                      (row['classes'] as List<String>)
                                          .join(', ');
                                  final lecturerEmail =
                                      row['lecturerEmail'].toString();
                                  final lecturerName =
                                      row['lecturerName'].toString();
                                  final assignmentId =
                                      row['assignmentId'].toString();

                                  // ✅ NEW: Check local cancelled state
                                  final isCancelled = _cancelledAssignments
                                      .contains(assignmentId);

                                  return DataRow(
                                    // ✅ NEW: Dim cancelled rows
                                    color: isCancelled
                                        ? WidgetStateProperty.all(
                                            Colors.red.withValues(alpha: 0.04))
                                        : null,
                                    cells: [
                                      // Nama
                                      DataCell(SizedBox(
                                          width: 180,
                                          child: Text(lecturerName,
                                              style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 13,
                                                  // ✅ NEW: Strike-through when cancelled
                                                  decoration: isCancelled
                                                      ? TextDecoration
                                                          .lineThrough
                                                      : null,
                                                  color: isCancelled
                                                      ? const Color(0xff94a3b8)
                                                      : const Color(
                                                          0xff0f172a)),
                                              maxLines: 2,
                                              overflow:
                                                  TextOverflow.ellipsis))),
                                      // Emel
                                      DataCell(Text(lecturerEmail,
                                          style: const TextStyle(
                                              fontSize: 11,
                                              color: Color(0xff64748b)))),
                                      // Jabatan badge
                                      DataCell(_buildLecturerProgramBadge(
                                          row['programId'].toString())),
                                      // Subjek
                                      DataCell(SizedBox(
                                          width: 120,
                                          child: Text(subjects,
                                              style: const TextStyle(
                                                  fontSize: 11,
                                                  color: Color(0xff475569))))),
                                      // Seksyen
                                      DataCell(SizedBox(
                                          width: 150,
                                          child: Text(classes,
                                              style: const TextStyle(
                                                  fontSize: 11,
                                                  color: Color(0xff475569))))),
                                      // Kelas/Minggu badge
                                      DataCell(Center(
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: const Color(0xffe0f2fe),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                              '${row['classesPerWeek']}',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                  color: Color(0xff0369a1))),
                                        ),
                                      )),
                                      // ✅ UPDATED: Tindakan — calendar + undo-cancel
                                      DataCell(Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          // Calendar icon → timetable dialog
                                          _buildActionIcon(
                                            icon: Icons.calendar_month,
                                            tooltip: 'Papar Jadual Waktu',
                                            color: const Color(0xff0b74de),
                                            onTap: () =>
                                                _showLecturerTimetableDialog(
                                                    row),
                                          ),
                                          const SizedBox(width: 4),
                                        ],
                                      )),
                                    ],
                                  );
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

  // ── Opens the lecturer timetable popup dialog ─────────────────────────────
  void _showLecturerTimetableDialog(Map<String, dynamic> row) {
    showDialog(
      context: context,
      builder: (ctx) => _LecturerTimetableDialog(
        lecturerId: row['lecturerId'].toString(),
        lecturerName: row['lecturerName'].toString(),
        lecturerEmail: row['lecturerEmail'].toString(),
        service: _service,
      ),
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
      'DEK': Colors.deepPurple,
      'DKV': Colors.brown,
      'ITW': Colors.teal,
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

// =============================================================================
// Lecturer Timetable Dialog
// Shows timetable slots for a specific lecturer with:
//   • Malay day names
//   • Class date display
//   • Undo-cancel via SnackBar action
// =============================================================================
class _LecturerTimetableDialog extends StatefulWidget {
  const _LecturerTimetableDialog({
    required this.lecturerId,
    required this.lecturerName,
    required this.lecturerEmail,
    required this.service,
  });

  final String lecturerId;
  final String lecturerName;
  final String lecturerEmail;
  final UserTimetableService service;

  @override
  State<_LecturerTimetableDialog> createState() =>
      _LecturerTimetableDialogState();
}

class _LecturerTimetableDialogState extends State<_LecturerTimetableDialog> {
  // ✅ UPDATED: Locally cancelled slot IDs (undo-capable)
  final Set<String> _cancelledSlotIds = {};

  static const Map<String, int> _dayOrder = {
    'Monday': 0,
    'Tuesday': 1,
    'Wednesday': 2,
    'Thursday': 3,
    'Friday': 4,
    'Saturday': 5,
    'Sunday': 6,
    'Isnin': 0,
    'Selasa': 1,
    'Rabu': 2,
    'Khamis': 3,
    'Jumaat': 4,
    'Sabtu': 5,
    'Ahad': 6,
  };

  // ✅ UPDATED: Returns full Malay day name (not English abbreviation)
  String _dayToMalay(String? day) {
    const map = {
      'Monday': 'Isnin',
      'Tuesday': 'Selasa',
      'Wednesday': 'Rabu',
      'Thursday': 'Khamis',
      'Friday': 'Jumaat',
      'Saturday': 'Sabtu',
      'Sunday': 'Ahad',
      // Already Malay — pass through
      'Isnin': 'Isnin',
      'Selasa': 'Selasa',
      'Rabu': 'Rabu',
      'Khamis': 'Khamis',
      'Jumaat': 'Jumaat',
      'Sabtu': 'Sabtu',
      'Ahad': 'Ahad',
    };
    return map[day?.trim() ?? ''] ?? (day ?? '—');
  }

  // ✅ NEW: Format slot date for display
  String _formatSlotDate(TimetableSlot slot) {
    final raw = slot.date.isNotEmpty
        ? slot.date
        : slot.weekStart ?? slot.createdAt ?? '';
    if (raw.isEmpty) return '';
    // ISO format YYYY-MM-DD or YYYY-MM-DDTHH:mm
    if (raw.length >= 10 && raw[4] == '-') {
      final parts = raw.substring(0, 10).split('-');
      if (parts.length == 3) return '${parts[2]}/${parts[1]}/${parts[0]}';
    }
    // Already DD/MM/YYYY
    if (RegExp(r'^\d{2}/\d{2}/\d{4}').hasMatch(raw)) {
      return raw.substring(0, 10);
    }
    return raw.length > 10 ? raw.substring(0, 10) : raw;
  }

  // ✅ UPDATED: Undo-cancel with SnackBar action instead of confirmation dialog
  void _handleCancelSlot(TimetableSlot slot) {
    // 1. Immediately mark cancelled in local state
    setState(() => _cancelledSlotIds.add(slot.id));

    // 2. Show SnackBar with URUS BALIK action
    ScaffoldMessenger.of(context).clearSnackBars();
    final snackBar = SnackBar(
      content: Text(
          'Penugasan untuk ${slot.subjectCode} (${slot.section}) dibatalkan secara lokal.'),
      backgroundColor: Colors.orange.shade700,
      duration: const Duration(seconds: 4),
      action: SnackBarAction(
        label: 'URUS BALIK',
        textColor: Colors.white,
        onPressed: () {
          // Undo — restore the slot
          setState(() => _cancelledSlotIds.remove(slot.id));
        },
      ),
    );

    ScaffoldMessenger.of(context)
        .showSnackBar(snackBar)
        .closed
        .then((reason) async {
      // 3. Commit to Firestore only if NOT undone
      if (reason != SnackBarClosedReason.action) {
        try {
          await widget.service.updateTimetableOverride(slot.id, false);
        } catch (e) {
          if (mounted) {
            setState(() => _cancelledSlotIds.remove(slot.id));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Gagal membatalkan kelas: $e'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 4),
              ),
            );
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 1100,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ───────────────────────────────────────────────────────
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xffeff6ff),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.calendar_month,
                        color: Color(0xff1d4ed8), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.lecturerName,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          widget.lecturerEmail,
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xff64748b)),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // ── Dark banner ───────────────────────────────────────────────────
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xff1e293b),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Column(
                  children: [
                    Text(
                      'JADUAL WAKTU SEMESTER SESI 2025/2026',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        letterSpacing: 0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 2),
                    Text(
                      'PAPARAN SLOT JADUAL',
                      style: TextStyle(
                        color: Color(0xff94a3b8),
                        fontSize: 11,
                        letterSpacing: 0.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Table ─────────────────────────────────────────────────────────
              Expanded(
                child: StreamBuilder<List<TimetableSlot>>(
                  stream: widget.service.getFilteredTimetableStream(
                    AppUser(
                      uid: widget.lecturerId,
                      name: widget.lecturerName,
                      email: widget.lecturerEmail,
                      role: UserRole.pensyarah,
                      isActive: true,
                    ),
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(
                          child: Text('Ralat: ${snapshot.error}',
                              style: const TextStyle(color: Colors.red)));
                    }

                    final allSlots = snapshot.data ?? [];

                    // Sort by day order → start time
                    final slots = [...allSlots]..sort((a, b) {
                        final dayA = _dayOrder[a.dayOfWeek ?? a.day] ?? 99;
                        final dayB = _dayOrder[b.dayOfWeek ?? b.day] ?? 99;
                        if (dayA != dayB) return dayA.compareTo(dayB);
                        return a.startTime.compareTo(b.startTime);
                      });

                    if (slots.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Text(
                            'Tiada slot jadual dijumpai untuk pensyarah ini.',
                            style: TextStyle(color: Color(0xff64748b)),
                          ),
                        ),
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            '${slots.length} record(s)',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xff94a3b8),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              border:
                                  Border.all(color: const Color(0xffe2e8f0)),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            // ✅ UPDATED: LayoutBuilder + ConstrainedBox for full-width table
                            child: LayoutBuilder(
                              builder: (context, constraints) =>
                                  SingleChildScrollView(
                                scrollDirection: Axis.vertical,
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(
                                        minWidth: constraints.maxWidth),
                                    child: DataTable(
                                      headingRowColor: WidgetStateProperty.all(
                                          const Color(0xfff1f5f9)),
                                      headingTextStyle: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        color: Color(0xff475569),
                                      ),
                                      dataTextStyle: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xff0f172a),
                                      ),
                                      columnSpacing: 12,
                                      horizontalMargin: 12,
                                      dataRowMinHeight: 64,
                                      dataRowMaxHeight: 80,
                                      columns: const [
                                        DataColumn(
                                            label: Text('NO.'), numeric: true),
                                        DataColumn(label: Text('KOD')),
                                        DataColumn(label: Text('NAMA KURSUS')),
                                        DataColumn(label: Text('SEKSYEN')),
                                        DataColumn(label: Text('PROGRAM')),
                                        DataColumn(
                                            label: Text('KAPASITI'),
                                            numeric: true),
                                        // ✅ UPDATED: HARI/MASA/TARIKH/LOKASI
                                        DataColumn(
                                            label: Text(
                                                'HARI / MASA\nTARIKH · LOKASI')),
                                        DataColumn(label: Text('JENIS')),
                                        DataColumn(label: Text('TINDAKAN')),
                                      ],
                                      rows: slots.asMap().entries.map((entry) {
                                        final index = entry.key;
                                        final slot = entry.value;
                                        final isCancelled =
                                            _cancelledSlotIds.contains(slot.id);
                                        final capacityText =
                                            '${slot.enrolled}/${slot.capacity}';

                                        // ✅ UPDATED: Full Malay day name
                                        final dayMalay = _dayToMalay(
                                            slot.dayOfWeek ?? slot.day);
                                        final timeRange =
                                            '${slot.startTime}-${slot.endTime}';
                                        final location = slot.roomName ??
                                            slot.roomId ??
                                            slot.room;

                                        // ✅ NEW: Formatted date
                                        final dateDisplay =
                                            _formatSlotDate(slot);

                                        final jenis = slot.classType.isNotEmpty
                                            ? slot.classType
                                            : slot.classType.isNotEmpty
                                                ? slot.classType
                                                : 'Teori/Amali';

                                        return DataRow(
                                          color: isCancelled
                                              ? WidgetStateProperty.all(Colors
                                                  .red
                                                  .withValues(alpha: 0.04))
                                              : null,
                                          cells: [
                                            // NO.
                                            DataCell(Text(
                                              '${index + 1}',
                                              style: const TextStyle(
                                                  color: Color(0xff94a3b8),
                                                  fontSize: 12),
                                            )),
                                            // KOD
                                            DataCell(Text(
                                              slot.subjectCode,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12),
                                            )),
                                            // NAMA KURSUS
                                            DataCell(SizedBox(
                                              width: 170,
                                              child: Text(
                                                slot.subjectName,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: isCancelled
                                                    ? const TextStyle(
                                                        decoration:
                                                            TextDecoration
                                                                .lineThrough,
                                                        color:
                                                            Color(0xff94a3b8))
                                                    : null,
                                              ),
                                            )),
                                            // SEKSYEN
                                            DataCell(Text(
                                              slot.section.isNotEmpty
                                                  ? slot.section
                                                  : slot.classId ?? '—',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w600),
                                            )),
                                            // PROGRAM
                                            DataCell(SizedBox(
                                              width: 140,
                                              child: Text(
                                                slot.program.isNotEmpty
                                                    ? slot.program
                                                    : slot.programId ?? '—',
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            )),
                                            // KAPASITI
                                            DataCell(Text(
                                              capacityText,
                                              style:
                                                  const TextStyle(fontSize: 12),
                                            )),
                                            // ✅ UPDATED: HARI / MASA / TARIKH / LOKASI
                                            DataCell(SizedBox(
                                              width: 130,
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  // Day: short abbr + full Malay
                                                  Row(
                                                    children: [
                                                      const SizedBox(width: 5),
                                                      Text(
                                                        dayMalay,
                                                        style: const TextStyle(
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            fontSize: 11,
                                                            color: Color(
                                                                0xff1e293b)),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 3),
                                                  // Time
                                                  Text(
                                                    timeRange,
                                                    style: const TextStyle(
                                                        fontSize: 11,
                                                        color:
                                                            Color(0xff475569)),
                                                  ),
                                                  // ✅ NEW: Date below time
                                                  if (dateDisplay.isNotEmpty)
                                                    Text(
                                                      dateDisplay,
                                                      style: const TextStyle(
                                                          fontSize: 10,
                                                          color: Color(
                                                              0xff94a3b8)),
                                                    ),
                                                  // Location
                                                  Text(
                                                    location,
                                                    style: const TextStyle(
                                                        fontSize: 10,
                                                        color:
                                                            Color(0xff64748b)),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ],
                                              ),
                                            )),
                                            // JENIS badge
                                            DataCell(
                                              isCancelled
                                                  ? Container(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 8,
                                                          vertical: 3),
                                                      decoration: BoxDecoration(
                                                        color: Colors.red
                                                            .withValues(
                                                                alpha: 0.1),
                                                        border: Border.all(
                                                            color: Colors.red
                                                                .withValues(
                                                                    alpha:
                                                                        0.3)),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(12),
                                                      ),
                                                      child: const Text(
                                                        'Dibatalkan',
                                                        style: TextStyle(
                                                            fontSize: 10,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color: Colors.red),
                                                      ),
                                                    )
                                                  : Container(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 8,
                                                          vertical: 3),
                                                      decoration: BoxDecoration(
                                                        color: const Color(
                                                            0xffeff6ff),
                                                        border: Border.all(
                                                            color: const Color(
                                                                0xffbfdbfe)),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(12),
                                                      ),
                                                      child: Text(
                                                        jenis,
                                                        style: const TextStyle(
                                                            fontSize: 10,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color: Color(
                                                                0xff1d4ed8)),
                                                      ),
                                                    ),
                                            ),
                                            // ✅ UPDATED: TINDAKAN — undo-cancel
                                            DataCell(
                                              isCancelled
                                                  ? TextButton.icon(
                                                      onPressed: () => setState(
                                                          () =>
                                                              _cancelledSlotIds
                                                                  .remove(
                                                                      slot.id)),
                                                      icon: const Icon(
                                                          Icons.undo,
                                                          size: 13,
                                                          color: Colors.green),
                                                      label: const Text(
                                                        'Urus Balik',
                                                        style: TextStyle(
                                                            color: Colors.green,
                                                            fontSize: 11,
                                                            fontWeight:
                                                                FontWeight
                                                                    .w600),
                                                      ),
                                                      style:
                                                          TextButton.styleFrom(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                horizontal: 6,
                                                                vertical: 4),
                                                        backgroundColor: Colors
                                                            .green
                                                            .withValues(
                                                                alpha: 0.07),
                                                        shape:
                                                            RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(6),
                                                        ),
                                                      ),
                                                    )
                                                  : TextButton.icon(
                                                      onPressed: () =>
                                                          _handleCancelSlot(
                                                              slot),
                                                      icon: const Icon(
                                                          Icons.close,
                                                          size: 13,
                                                          color: Colors.red),
                                                      label: const Text(
                                                        'Batal',
                                                        style: TextStyle(
                                                            color: Colors.red,
                                                            fontSize: 11,
                                                            fontWeight:
                                                                FontWeight
                                                                    .w600),
                                                      ),
                                                      style:
                                                          TextButton.styleFrom(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                horizontal: 6,
                                                                vertical: 4),
                                                        backgroundColor: Colors
                                                            .red
                                                            .withValues(
                                                                alpha: 0.06),
                                                        shape:
                                                            RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(6),
                                                        ),
                                                      ),
                                                    ),
                                            ),
                                          ],
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

              // ── Footer ─────────────────────────────────────────────────────────
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                  child: const Text('Tutup',
                      style: TextStyle(color: Color(0xff6b7280))),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
// Helper class for the student detail modal info grid
// ===========================================================================
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