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

  UserRole _selectedRole = UserRole.pensyarah;
  String? _selectedDepartmentId;
  String? _selectedProgramId;
  bool _isActive = true;

  List<Department> _departments = [];
  List<ProgramCode> _programs = [];
  bool _loadingData = true;
  bool _isSubmitting = false;

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
      final credential = await AuthService.instance.registerNewUserByAdmin(
        emailController.text,
        passwordController.text,
      );

      final uid = credential.user?.uid;
      if (uid == null) {
        _showError('Akaun Firebase berjaya dibuat tetapi UID tidak ditemui.');
        return;
      }

      final newUser = AppUser(
        uid: uid,
        name: nameController.text.trim(),
        email: emailController.text.trim().toLowerCase(),
        role: _selectedRole,
        programId: _requiresProgram ? selectedProgram?.id : null,
        departmentId: _departmentIdForProfile(selectedProgram),
        phoneNumber: phoneController.text.trim().isEmpty
            ? null
            : phoneController.text.trim(),
        isActive: _isActive,
      );

      await FirestoreService.instance.createUserProfile(newUser);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Akaun pengguna berjaya dicipta.')),
      );
      _clearForm();
    } on FirebaseAuthException catch (e) {
      _showError(_messageForAuthError(e));
    } catch (e) {
      _showError('Pendaftaran gagal: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
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
    setState(() {
      _selectedRole = UserRole.pensyarah;
      _selectedProgramId = _programs.isEmpty ? null : _programs.first.id;
      _selectedDepartmentId =
          _departments.isEmpty ? null : _departments.first.id;
      _isActive = true;
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
