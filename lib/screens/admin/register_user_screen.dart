import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/app_models.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../state/app_scope.dart';

class RegisterUserScreen extends StatefulWidget {
  const RegisterUserScreen({super.key});

  @override
  State<RegisterUserScreen> createState() => _RegisterUserScreenState();
}

class _RegisterUserScreenState extends State<RegisterUserScreen> {
  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final phoneController = TextEditingController();
  final authUidController = TextEditingController();

  UserRole _selectedRole = UserRole.pensyarah;
  String? _selectedDepartmentId;
  String? _selectedProgramId;
  bool _isActive = true;

  List<Department> _departments = [];
  List<ProgramCode> _programs = [];
  bool _loadingData = true;
  bool _isSubmitting = false;
  bool _showRepairPanel = false;
  String? _repairMessage;

  @override
  void initState() {
    super.initState();
    _loadHierarchy();
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    phoneController.dispose();
    authUidController.dispose();
    super.dispose();
  }

  Future<void> _loadHierarchy() async {
    final fs = FirestoreService.instance;
    try {
      final depts = await fs.getDepartments();
      final progs = await fs.getPrograms();
      if (!mounted) return;
      setState(() {
        _departments = depts;
        _programs = progs;
        _selectedDepartmentId = depts.isEmpty ? null : depts.first.id;
        _selectedProgramId = progs.isEmpty ? null : progs.first.id;
        _loadingData = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingData = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ralat memuatkan data hierarki: $e')),
      );
    }
  }

  Future<void> _registerUser() async {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;

    final selectedProgram = _selectedProgram;
    if ((_selectedRole == UserRole.ketua_program ||
            _selectedRole == UserRole.pensyarah) &&
        selectedProgram == null) {
      _showError('Sila pilih program.');
      return;
    }
    if (_selectedRole == UserRole.ketua_jabatan &&
        _selectedDepartmentId == null) {
      _showError('Sila pilih jabatan.');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final normalizedEmail = emailController.text.trim().toLowerCase();
      final credential = await AuthService.instance.registerNewUserByAdmin(
        normalizedEmail,
        passwordController.text,
      );

      final uid = credential.user?.uid;
      if (uid == null) {
        _showError('Akaun Firebase berjaya dibuat tetapi UID tidak ditemui.');
        return;
      }

      final newUser = _buildUserProfile(uid, selectedProgram);

      try {
        await FirestoreService.instance.createUserProfile(newUser);
      } on FirebaseException catch (e, stackTrace) {
        authUidController.text = uid;
        debugPrint('Register profile write failed after Auth creation: '
            'email=$normalizedEmail uid=$uid code=${e.code} message=${e.message}');
        debugPrintStack(stackTrace: stackTrace);
        _enableRepairPanel(
          'Akaun Auth telah dicipta tetapi profil Firestore gagal disimpan. '
          'UID telah diisi secara automatik; tekan Retry Save Profile selepas sambungan atau kebenaran Firestore pulih.',
        );
        _showError(_messageForProfileWriteError(e, normalizedEmail));
        return;
      } catch (e, stackTrace) {
        authUidController.text = uid;
        debugPrint('Register profile write failed after Auth creation: '
            'email=$normalizedEmail uid=$uid error=$e');
        debugPrintStack(stackTrace: stackTrace);
        _enableRepairPanel(
          'Akaun Auth telah dicipta tetapi profil Firestore gagal disimpan. '
          'UID telah diisi secara automatik; tekan Retry Save Profile.',
        );
        _showError(
          'Akaun Auth telah dicipta tetapi profil Firestore gagal disimpan '
          'untuk $normalizedEmail. Sila gunakan Retry Save Profile dengan UID Auth '
          'atau hubungi pentadbir sistem.',
        );
        return;
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Akaun pengguna berjaya didaftarkan.')),
      );
      _clearForm();
    } on FirebaseAuthException catch (e) {
      debugPrint('Register Auth error: ${e.code} ${e.message}');
      if (e.code == 'email-already-in-use') {
        await _showDuplicateEmailMessage();
        return;
      }
      if (e.code == 'network-request-failed') {
        final recovered = await _tryAutoCreateMissingProfileFromAuth(
          selectedProgram,
          reason: 'network-request-failed',
        );
        if (recovered) return;
      }
      _showError(_messageForAuthError(e));
    } catch (e) {
      debugPrint('Register unexpected error: $e');
      _showError('Pendaftaran gagal: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  AppUser _buildUserProfile(String uid, ProgramCode? selectedProgram) {
    final phone = phoneController.text.trim();
    return AppUser(
      uid: uid,
      name: nameController.text.trim(),
      email: emailController.text.trim().toLowerCase(),
      role: _selectedRole,
      programId: _requiresProgram ? selectedProgram?.id : null,
      departmentId: _departmentIdForProfile(selectedProgram),
      phoneNumber: phone.isEmpty ? null : phone,
      isActive: _isActive,
    );
  }

  Future<void> _showDuplicateEmailMessage() async {
    final normalizedEmail = emailController.text.trim().toLowerCase();

    try {
      final existingProfile =
          await FirestoreService.instance.getUserByEmail(normalizedEmail);
      if (existingProfile != null) {
        _showError(
          'Emel ini telah digunakan. Jika pengguna tidak boleh log masuk, '
          'semak sama ada profil Firestore wujud.',
        );
        return;
      }
      final recovered = await _tryAutoCreateMissingProfileFromAuth(
        _selectedProgram,
        reason: 'email-already-in-use',
      );
      if (recovered) return;
      _showError(
        'Akaun Auth wujud tetapi profil Firestore tidak dijumpai. '
        'Untuk membaiki, masukkan Firebase Auth UID dan tekan Save Missing Firestore Profile.',
      );
      _enableRepairPanel(
        'Akaun Auth wujud tetapi profil Firestore tidak dijumpai. '
        'Salin UID daripada Firebase Console > Authentication > Users, kemudian cipta profil Firestore di sini.',
      );
    } on FirebaseException catch (e, stackTrace) {
      debugPrint('Email duplicate profile lookup failed: '
          '${e.code} ${e.message}');
      debugPrintStack(stackTrace: stackTrace);
      _showError(
        'Emel ini telah digunakan, tetapi semakan profil Firestore gagal. '
        'Sila semak Firebase Authentication dan Firestore.',
      );
    } catch (e, stackTrace) {
      debugPrint('Email duplicate profile lookup failed: $e');
      debugPrintStack(stackTrace: stackTrace);
      _showError(
        'Emel ini telah digunakan, tetapi semakan profil Firestore gagal.',
      );
    }
  }

  Future<bool> _tryAutoCreateMissingProfileFromAuth(
    ProgramCode? selectedProgram, {
    required String reason,
  }) async {
    final normalizedEmail = emailController.text.trim().toLowerCase();
    try {
      final uid = await AuthService.instance.getUidBySecondarySignIn(
        normalizedEmail,
        passwordController.text,
      );
      if (uid == null || uid.isEmpty) return false;

      final existingByUid = await FirestoreService.instance.getUserById(uid);
      if (existingByUid != null) {
        _showError(
          'Emel ini telah digunakan. Profil Firestore untuk akaun ini sudah wujud.',
        );
        return true;
      }

      final existingByEmail =
          await FirestoreService.instance.getUserByEmail(normalizedEmail);
      if (existingByEmail != null) {
        _showError(
          'Emel ini telah digunakan. Profil Firestore untuk emel ini sudah wujud.',
        );
        return true;
      }

      await FirestoreService.instance.createUserProfile(
        _buildUserProfile(uid, selectedProgram),
      );

      if (!mounted) return true;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Akaun Auth telah wujud dan profil Firestore berjaya dicipta. Pengguna kini boleh log masuk.',
          ),
        ),
      );
      _clearForm();
      return true;
    } on FirebaseAuthException catch (e, stackTrace) {
      debugPrint('Auto profile repair Auth lookup failed: '
          'reason=$reason email=$normalizedEmail code=${e.code} message=${e.message}');
      debugPrintStack(stackTrace: stackTrace);
      _enableRepairPanel(
        'Akaun Auth mungkin wujud tetapi profil Firestore tidak dijumpai. '
        'Sistem tidak dapat mendapatkan UID secara automatik. Salin UID daripada Firebase Console > Authentication > Users.',
      );
      return false;
    } on FirebaseException catch (e, stackTrace) {
      debugPrint('Auto profile repair Firestore write failed: '
          'reason=$reason email=$normalizedEmail code=${e.code} message=${e.message}');
      debugPrintStack(stackTrace: stackTrace);
      _enableRepairPanel(
        'Akaun Auth wujud tetapi profil Firestore gagal dicipta secara automatik. '
        'Salin UID daripada Firebase Console jika perlu dan cuba simpan profil secara manual.',
      );
      _showError(
        'Akaun Auth wujud tetapi profil Firestore gagal dicipta secara automatik. Sila cuba semula atau gunakan repair manual.',
      );
      return true;
    } catch (e, stackTrace) {
      debugPrint('Auto profile repair failed: '
          'reason=$reason email=$normalizedEmail error=$e');
      debugPrintStack(stackTrace: stackTrace);
      _enableRepairPanel(
        'Akaun Auth mungkin wujud tetapi profil Firestore tidak dijumpai. '
        'Sistem tidak dapat membaiki secara automatik. Salin UID daripada Firebase Console.',
      );
      return false;
    }
  }

  void _enableRepairPanel(String message) {
    if (!mounted) return;
    setState(() {
      _showRepairPanel = true;
      _repairMessage = message;
    });
  }

  Future<void> _repairFirestoreProfile() async {
    if (_isSubmitting) return;

    final selectedProgram = _selectedProgram;
    final validationMessage = _validateRepairProfile(selectedProgram);
    if (validationMessage != null) {
      _showError(validationMessage);
      return;
    }

    final uid = authUidController.text.trim();
    final normalizedEmail = emailController.text.trim().toLowerCase();

    setState(() => _isSubmitting = true);
    try {
      final existingByUid = await FirestoreService.instance.getUserById(uid);
      if (existingByUid != null) {
        _showError(
          'Profil Firestore untuk UID ini sudah wujud. Tiada profil baharu dicipta.',
        );
        return;
      }

      final existingByEmail =
          await FirestoreService.instance.getUserByEmail(normalizedEmail);
      if (existingByEmail != null) {
        _showError(
          'Profil Firestore untuk emel ini sudah wujud. Tiada profil baharu dicipta.',
        );
        return;
      }

      await FirestoreService.instance.createUserProfile(
        _buildUserProfile(uid, selectedProgram),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Profil Firestore berjaya dibaiki. Pengguna kini boleh log masuk.',
          ),
        ),
      );
      setState(() {
        _showRepairPanel = false;
        _repairMessage = null;
      });
      _clearForm();
    } on FirebaseException catch (e, stackTrace) {
      debugPrint('Firestore profile repair failed: '
          'email=$normalizedEmail uid=$uid code=${e.code} message=${e.message}');
      debugPrintStack(stackTrace: stackTrace);
      _showError(
        'Profil Firestore gagal dibaiki. Sila semak kebenaran Firestore dan cuba semula.',
      );
    } catch (e, stackTrace) {
      debugPrint('Firestore profile repair failed: '
          'email=$normalizedEmail uid=$uid error=$e');
      debugPrintStack(stackTrace: stackTrace);
      _showError('Profil Firestore gagal dibaiki. Sila cuba semula.');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String? _validateRepairProfile(ProgramCode? selectedProgram) {
    if (authUidController.text.trim().isEmpty) {
      return 'Sila masukkan Firebase Auth UID.';
    }
    if (nameController.text.trim().isEmpty) {
      return 'Nama penuh diperlukan.';
    }
    final email = emailController.text.trim();
    if (email.isEmpty) return 'Emel diperlukan.';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return 'Format emel tidak sah.';
    }
    if (_requiresProgram && selectedProgram == null) {
      return 'Sila pilih program.';
    }
    if (_selectedRole == UserRole.ketua_jabatan &&
        _selectedDepartmentId == null) {
      return 'Sila pilih jabatan.';
    }
    return null;
  }

  String? _departmentIdForProfile(ProgramCode? selectedProgram) {
    return switch (_selectedRole) {
      UserRole.pentadbir => null,
      UserRole.ketua_jabatan => _selectedDepartmentId,
      UserRole.ketua_program ||
      UserRole.pensyarah =>
        selectedProgram?.departmentId,
    };
  }

  bool get _requiresProgram =>
      _selectedRole == UserRole.ketua_program ||
      _selectedRole == UserRole.pensyarah;

  ProgramCode? get _selectedProgram {
    final selectedId = _selectedProgramId;
    if (selectedId == null) return null;
    return _programs.where((program) => program.id == selectedId).firstOrNull;
  }

  void _clearForm() {
    _formKey.currentState?.reset();
    nameController.clear();
    emailController.clear();
    passwordController.clear();
    phoneController.clear();
    authUidController.clear();
    setState(() {
      _selectedRole = UserRole.pensyarah;
      _selectedProgramId = _programs.isEmpty ? null : _programs.first.id;
      _selectedDepartmentId =
          _departments.isEmpty ? null : _departments.first.id;
      _isActive = true;
      _showRepairPanel = false;
      _repairMessage = null;
    });
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  String _messageForAuthError(FirebaseAuthException error) {
    return switch (error.code) {
      'email-already-in-use' => 'Emel ini telah digunakan.',
      'invalid-email' => 'Format emel tidak sah.',
      'weak-password' => 'Kata laluan terlalu lemah.',
      'network-request-failed' =>
        'Ralat rangkaian. Sila semak sambungan internet.',
      'too-many-requests' =>
        'Terlalu banyak permintaan. Sila cuba semula kemudian.',
      _ => 'Ralat Firebase Auth: ${error.message ?? error.code}',
    };
  }

  String _messageForProfileWriteError(
    FirebaseException error,
    String email,
  ) {
    return switch (error.code) {
      'permission-denied' =>
        'Akaun Auth telah dicipta tetapi profil Firestore gagal disimpan untuk $email kerana kebenaran Firestore. Sila gunakan Retry Save Profile selepas kebenaran Firestore dipulihkan.',
      'unavailable' ||
      'deadline-exceeded' =>
        'Akaun Auth telah dicipta tetapi profil Firestore gagal disimpan untuk $email. Sila gunakan Retry Save Profile selepas sambungan pulih.',
      _ =>
        'Akaun Auth telah dicipta tetapi profil Firestore gagal disimpan untuk $email. Sila gunakan Retry Save Profile dengan UID Auth atau hubungi pentadbir sistem.',
    };
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = AppScope.of(context).currentUser;
    if (currentUser?.role != UserRole.pentadbir) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
              'Akses tidak dibenarkan. Hanya Pentadbir boleh daftar akaun.'),
        ),
      );
    }

    if (_loadingData) {
      return const Center(child: CircularProgressIndicator());
    }

    final selectedProgram = _selectedProgram;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Daftar Pengguna Baru',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Cipta akaun Firebase Auth dan profil Firestore untuk staf TVETMARA.',
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: nameController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Nama Penuh'),
                validator: (val) => val == null || val.trim().isEmpty
                    ? 'Nama penuh diperlukan'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Emel'),
                validator: (val) {
                  final email = val?.trim() ?? '';
                  if (email.isEmpty) return 'Emel diperlukan';
                  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
                    return 'Format emel tidak sah';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: passwordController,
                obscureText: true,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Kata Laluan Sementara (min 6 aksara)',
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) {
                    return 'Kata laluan sementara diperlukan';
                  }
                  if (val.length < 6) return 'Minimum 6 aksara';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Nombor Telefon (pilihan)',
                ),
              ),
              const SizedBox(height: 24),
              DropdownButtonFormField<UserRole>(
                initialValue: _selectedRole,
                decoration: const InputDecoration(labelText: 'Peranan'),
                items: const [
                  DropdownMenuItem(
                      value: UserRole.pentadbir, child: Text('Pentadbir')),
                  DropdownMenuItem(
                      value: UserRole.ketua_program,
                      child: Text('Ketua Program')),
                  DropdownMenuItem(
                      value: UserRole.ketua_jabatan,
                      child: Text('Ketua Jabatan')),
                  DropdownMenuItem(
                      value: UserRole.pensyarah, child: Text('Pensyarah')),
                ],
                onChanged: _isSubmitting
                    ? null
                    : (val) {
                        if (val == null) return;
                        setState(() => _selectedRole = val);
                      },
              ),
              const SizedBox(height: 16),
              if (_requiresProgram)
                DropdownButtonFormField<String>(
                  initialValue: _selectedProgramId,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Program'),
                  items: _programs
                      .map((p) =>
                          DropdownMenuItem(value: p.id, child: Text(p.name)))
                      .toList(),
                  validator: (val) => val == null ? 'Program diperlukan' : null,
                  onChanged: _isSubmitting
                      ? null
                      : (val) => setState(() => _selectedProgramId = val),
                )
              else if (_selectedRole == UserRole.ketua_jabatan)
                DropdownButtonFormField<String>(
                  initialValue: _selectedDepartmentId,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Jabatan'),
                  items: _departments
                      .map((d) =>
                          DropdownMenuItem(value: d.id, child: Text(d.name)))
                      .toList(),
                  validator: (val) => val == null ? 'Jabatan diperlukan' : null,
                  onChanged: _isSubmitting
                      ? null
                      : (val) => setState(() => _selectedDepartmentId = val),
                )
              else
                const _ScopeNote(
                  text: 'Pentadbir tidak memerlukan program atau jabatan.',
                ),
              if (_requiresProgram && selectedProgram != null) ...[
                const SizedBox(height: 12),
                _ScopeNote(
                  text: selectedProgram.departmentId == null
                      ? 'Program ini tiada Ketua Jabatan. departmentId akan disimpan sebagai null.'
                      : 'departmentId akan disimpan sebagai ${selectedProgram.departmentId}.',
                ),
              ],
              const SizedBox(height: 16),
              SwitchListTile(
                value: _isActive,
                contentPadding: EdgeInsets.zero,
                title: const Text('Akaun Aktif'),
                subtitle: const Text(
                  'Pengguna hanya boleh log masuk jika akaun aktif.',
                ),
                onChanged: _isSubmitting
                    ? null
                    : (value) => setState(() => _isActive = value),
              ),
              if (_showRepairPanel) ...[
                const SizedBox(height: 16),
                _RepairProfilePanel(
                  message: _repairMessage ??
                      'Akaun Auth wujud tetapi profil Firestore tidak dijumpai.',
                  uidController: authUidController,
                  isSubmitting: _isSubmitting,
                  onRepair: _repairFirestoreProfile,
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isSubmitting ? null : _registerUser,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.person_add_alt_1),
                  label: Text(
                    _isSubmitting ? 'Mendaftar...' : 'Daftar Akaun',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScopeNote extends StatelessWidget {
  const _ScopeNote({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xfff8fafc),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xffe2e8f0)),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Color(0xff475569), fontSize: 13),
      ),
    );
  }
}

class _RepairProfilePanel extends StatelessWidget {
  const _RepairProfilePanel({
    required this.message,
    required this.uidController,
    required this.isSubmitting,
    required this.onRepair,
  });

  final String message;
  final TextEditingController uidController;
  final bool isSubmitting;
  final VoidCallback onRepair;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xfffffbeb),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: const Color(0xfff59e0b).withValues(alpha: .35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.warning_amber_rounded, color: Color(0xffb45309)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Repair Missing Firestore Profile',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: const Color(0xff92400e),
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      message,
                      style: const TextStyle(
                        color: Color(0xff92400e),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Gunakan medan nama, emel, peranan, program/jabatan, telefon dan status aktif di atas. Tindakan ini hanya mencipta profil Firestore; ia tidak mencipta akaun Auth baharu dan tidak menukar kata laluan.',
            style: TextStyle(color: Color(0xff78350f), height: 1.35),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: uidController,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              labelText: 'Firebase Auth UID',
              helperText:
                  'Salin UID daripada Firebase Console > Authentication > Users.',
              prefixIcon: Icon(Icons.key_outlined),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.icon(
                onPressed: isSubmitting ? null : onRepair,
                icon: isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.build_circle_outlined),
                label: const Text('Save Missing Firestore Profile'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
