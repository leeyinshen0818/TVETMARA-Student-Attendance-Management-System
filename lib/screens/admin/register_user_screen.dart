import 'package:flutter/material.dart';

import '../../models/app_models.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';

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

  UserRole _selectedRole = UserRole.pensyarah;
  String? _selectedDepartmentId;
  String? _selectedProgramId;

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
    super.dispose();
  }

  Future<void> _loadHierarchy() async {
    final fs = FirestoreService.instance;
    try {
      final depts = await fs.getDepartments();
      final progs = await fs.getPrograms();
      setState(() {
        _departments = depts;
        _programs = progs;
        _loadingData = false;
        if (_departments.isNotEmpty) {
          _selectedDepartmentId = _departments.first.id;
        }
        if (_programs.isNotEmpty) _selectedProgramId = _programs.first.id;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  Future<void> _registerUser() async {
    if (!_formKey.currentState!.validate()) return;

    // Additional Validation
    if (_selectedRole == UserRole.ketua_jabatan &&
        _selectedDepartmentId == null) {
      _showError('Sila pilih Jabatan.');
      return;
    }
    if ((_selectedRole == UserRole.ketua_program ||
            _selectedRole == UserRole.pensyarah) &&
        _selectedProgramId == null) {
      _showError('Sila pilih Program.');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // 1. Create User in Firebase Auth using the Admin bypass
      final credential = await AuthService.instance.registerNewUserByAdmin(
        emailController.text,
        passwordController.text,
      );

      final uid = credential.user!.uid;

      // 2. Create User Profile in Firestore
      final newUser = AppUser(
        uid: uid,
        name: nameController.text.trim(),
        email: emailController.text.trim(),
        role: _selectedRole,
        departmentId: _selectedRole == UserRole.ketua_jabatan
            ? _selectedDepartmentId
            : null,
        programId: (_selectedRole == UserRole.ketua_program ||
                _selectedRole == UserRole.pensyarah)
            ? _selectedProgramId
            : null,
        isActive: true,
      );

      await FirestoreService.instance.createUserProfile(newUser);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pendaftaran pengguna berjaya!')),
        );
        _formKey.currentState!.reset();
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingData) {
      return const Center(child: CircularProgressIndicator());
    }

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
                  'Cipta akaun untuk Ketua Jabatan, Ketua Program, atau Pensyarah.'),
              const SizedBox(height: 24),

              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Nama Penuh'),
                validator: (val) => val == null || val.isEmpty
                    ? 'Kemasukan Nama Diperlukan'
                    : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Emel (TVETMARA)'),
                validator: (val) {
                  if (val == null || val.isEmpty) {
                    return 'Kemasukan Emel Diperlukan';
                  }
                  if (!val.contains('@')) return 'Format Emel Tidak Sah';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                    labelText: 'Kata Laluan (min 6 aksara)'),
                validator: (val) =>
                    val != null && val.length < 6 ? 'Minima 6 Aksara' : null,
              ),
              const SizedBox(height: 24),

              DropdownButtonFormField<UserRole>(
                initialValue: _selectedRole,
                decoration: const InputDecoration(labelText: 'Peranan (Role)'),
                items: const [
                  DropdownMenuItem(
                      value: UserRole.ketua_jabatan,
                      child: Text('Ketua Jabatan')),
                  DropdownMenuItem(
                      value: UserRole.ketua_program,
                      child: Text('Ketua Program')),
                  DropdownMenuItem(
                      value: UserRole.pensyarah, child: Text('Pensyarah')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _selectedRole = val);
                },
              ),
              const SizedBox(height: 16),

              // Dynamic Dropdowns
              if (_selectedRole == UserRole.ketua_jabatan)
                DropdownButtonFormField<String>(
                  initialValue: _selectedDepartmentId,
                  decoration:
                      const InputDecoration(labelText: 'Jabatan (Department)'),
                  items: _departments
                      .map((d) =>
                          DropdownMenuItem(value: d.id, child: Text(d.name)))
                      .toList(),
                  onChanged: (val) =>
                      setState(() => _selectedDepartmentId = val),
                )
              else
                DropdownButtonFormField<String>(
                  initialValue: _selectedProgramId,
                  isExpanded: true,
                  decoration:
                      const InputDecoration(labelText: 'Program (Course)'),
                  items: _programs
                      .map((p) =>
                          DropdownMenuItem(value: p.id, child: Text(p.name)))
                      .toList(),
                  onChanged: (val) => setState(() => _selectedProgramId = val),
                ),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isSubmitting ? null : _registerUser,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Text('Daftar Akaun'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
