import 'package:flutter/material.dart';

import '../state/app_scope.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final email = TextEditingController(text: 'admin@tvetmara.edu.my');
  final password = TextEditingController(text: 'admin123');

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  void _login() {
    final ok = AppScope.of(context).login(email.text);
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Emel demo tidak sah. Gunakan akaun admin atau pensyarah.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xff0f172a),
              ),
              padding: const EdgeInsets.all(40),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxHeight < 580;
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints:
                          BoxConstraints(minHeight: constraints.maxHeight),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: Color(0xffdbeafe),
                                foregroundColor: Color(0xff1d4ed8),
                                child: Icon(Icons.school),
                              ),
                              SizedBox(width: 12),
                              Text(
                                'TVETMARA',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Sistem Pengurusan Kehadiran Pelajar TVETMARA',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: compact ? 28 : 34,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Pengurusan berpusat untuk kehadiran, jadual, disiplin dan kelas ganti.',
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 16),
                              ),
                              const SizedBox(height: 22),
                              const Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _LoginFeatureChip('Had 80%'),
                                  _LoginFeatureChip('PDF Mingguan'),
                                  _LoginFeatureChip('Tempahan Bilik'),
                                ],
                              ),
                            ],
                          ),
                          const Padding(
                            padding: EdgeInsets.only(top: 18),
                            child: Text('Prototaip Flutter',
                                style: TextStyle(color: Colors.white54)),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Log Masuk',
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xff0f172a),
                                )),
                        const SizedBox(height: 8),
                        const Text(
                            'Pilih akaun demo. Sebarang kata laluan diterima.'),
                        const SizedBox(height: 24),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            FilledButton.icon(
                              onPressed: () {
                                email.text = 'admin@tvetmara.edu.my';
                                password.text = 'admin123';
                              },
                              icon: const Icon(Icons.admin_panel_settings),
                              label: const Text('Pentadbir'),
                            ),
                            OutlinedButton.icon(
                              onPressed: () {
                                email.text = 'lecturer@tvetmara.edu.my';
                                password.text = 'lecturer123';
                              },
                              icon: const Icon(Icons.menu_book),
                              label: const Text('Pensyarah'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: email,
                          decoration: const InputDecoration(
                              labelText: 'Nama Pengguna / Emel',
                              prefixIcon: Icon(Icons.email_outlined)),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: password,
                          obscureText: true,
                          decoration: const InputDecoration(
                              labelText: 'Kata Laluan',
                              prefixIcon: Icon(Icons.lock_outline)),
                        ),
                        const SizedBox(height: 20),
                        FilledButton.icon(
                          onPressed: _login,
                          icon: const Icon(Icons.login),
                          label: const Text('Log Masuk'),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Admin: admin@tvetmara.edu.my | Pensyarah: lecturer@tvetmara.edu.my',
                          textAlign: TextAlign.center,
                          style:
                              TextStyle(color: Color(0xff64748b), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginFeatureChip extends StatelessWidget {
  const _LoginFeatureChip(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .08),
        border: Border.all(color: Colors.white.withValues(alpha: .16)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
