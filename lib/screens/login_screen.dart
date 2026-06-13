import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../data/seed_firestore.dart';
import '../state/app_scope.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final email = TextEditingController(text: 'admin@tvetmara.edu.my');
  final password = TextEditingController(text: 'admin123');
  bool _loggingIn = false;
  bool _seedingDemo = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_loggingIn) return;
    setState(() => _loggingIn = true);

    final state = AppScope.of(context);
    final ok = await state.login(email.text, password.text);

    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.loginError ??
              'Log masuk gagal. Sila semak emel dan kata laluan.'),
        ),
      );
    }

    if (mounted) setState(() => _loggingIn = false);
  }

  Future<void> _seedDemoData() async {
    if (_seedingDemo) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Seed Demo Data'),
        content: const Text(
          'This debug-only action rebuilds demo Firebase data for testing. '
          'It should only be used with the demo/development Firebase project.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Run Seed'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!mounted) return;

    setState(() => _seedingDemo = true);
    final appState = AppScope.of(context);
    try {
      await seedFirestore();
      appState.clearDataCache();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Demo data seeded. You can now use demo logins.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Demo seed failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _seedingDemo = false);
    }
  }

  void _fillDemo(String demoEmail, String demoPassword) {
    email.text = demoEmail;
    password.text = demoPassword;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 860;
          final intro = _LoginIntro(compact: constraints.maxHeight < 580);
          final form = _LoginForm(
            email: email,
            password: password,
            loggingIn: _loggingIn,
            seedingDemo: _seedingDemo,
            obscurePassword: _obscurePassword,
            onTogglePassword: () {
              setState(() => _obscurePassword = !_obscurePassword);
            },
            onSubmit: _login,
            onSeedDemo: _seedDemoData,
            onFillDemo: _fillDemo,
          );

          if (wide) {
            return Row(
              children: [
                Expanded(child: intro),
                Expanded(child: form),
              ],
            );
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: intro,
                ),
                form,
              ],
            ),
          );
        },
      ),
    );
  }
}

class _LoginIntro extends StatelessWidget {
  const _LoginIntro({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: Color(0xff0f172a)),
      padding: EdgeInsets.all(compact ? 24 : 40),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: compact ? 260 : 420),
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
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sistem Pengurusan Kehadiran Pelajar TVETMARA',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: compact ? 26 : 34,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Pengurusan berpusat untuk kehadiran, jadual, disiplin dan kelas ganti.',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 22),
                  const Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _LoginFeatureChip('Had 80%'),
                      _LoginFeatureChip('PDF Mingguan'),
                      _LoginFeatureChip('Tempahan Bilik'),
                      _LoginFeatureChip('Firebase Cloud'),
                    ],
                  ),
                ],
              ),
            ),
            const Text(
              'Flutter + Firebase',
              style: TextStyle(color: Colors.white54),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoginForm extends StatelessWidget {
  const _LoginForm({
    required this.email,
    required this.password,
    required this.loggingIn,
    required this.seedingDemo,
    required this.obscurePassword,
    required this.onTogglePassword,
    required this.onSubmit,
    required this.onSeedDemo,
    required this.onFillDemo,
  });

  final TextEditingController email;
  final TextEditingController password;
  final bool loggingIn;
  final bool seedingDemo;
  final bool obscurePassword;
  final VoidCallback onTogglePassword;
  final VoidCallback onSubmit;
  final VoidCallback onSeedDemo;
  final void Function(String email, String password) onFillDemo;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Log Masuk',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: const Color(0xff0f172a),
                        ),
                  ),
                  const SizedBox(height: 8),
                  const Text('Masukkan emel dan kata laluan Firebase anda.'),
                  if (kDebugMode) ...[
                    const SizedBox(height: 24),
                    const Text(
                      'Demo sahaja - akses pantas:',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Pilih akaun demo mengikut skop ujian. Contoh: gunakan KJ Elektrik untuk jadual DED/DCP/DCB, dan KP DGS untuk jadual DGS.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: const Color(0xff64748b),
                          ),
                    ),
                    const SizedBox(height: 8),
                    _DemoLoginSection(
                      title: 'Pentadbir',
                      buttons: [
                        _DemoLoginButton(
                          label: 'Pentadbir Sistem',
                          subtitle: 'Daftar akaun dan tetapan',
                          icon: Icons.admin_panel_settings,
                          email: 'admin@tvetmara.edu.my',
                          onPressed: () =>
                              onFillDemo('admin@tvetmara.edu.my', 'admin123'),
                        ),
                      ],
                    ),
                    _DemoLoginSection(
                      title: 'Ketua Jabatan',
                      buttons: [
                        _DemoLoginButton(
                          label: 'KJ Elektrik',
                          subtitle: 'Skop: DED / DCP / DCB',
                          icon: Icons.account_balance,
                          email: 'kj_elektrik@tvetmara.edu.my',
                          onPressed: () => onFillDemo(
                              'kj_elektrik@tvetmara.edu.my', 'password123'),
                        ),
                        _DemoLoginButton(
                          label: 'KJ Mekanikal',
                          subtitle: 'Skop: ITW / SLR / SMI',
                          icon: Icons.account_balance,
                          email: 'kj_mekanikal@tvetmara.edu.my',
                          onPressed: () => onFillDemo(
                              'kj_mekanikal@tvetmara.edu.my', 'password123'),
                        ),
                        _DemoLoginButton(
                          label: 'KJ Automotif',
                          subtitle: 'Skop: IMF / SMM / DMM',
                          icon: Icons.account_balance,
                          email: 'kj_automotif@tvetmara.edu.my',
                          onPressed: () => onFillDemo(
                              'kj_automotif@tvetmara.edu.my', 'password123'),
                        ),
                      ],
                    ),
                    _DemoLoginSection(
                      title: 'Ketua Program',
                      buttons: [
                        _DemoLoginButton(
                          label: 'KP DGS',
                          subtitle: 'Program tanpa KJ: DGS sahaja',
                          icon: Icons.school,
                          email: 'kp_dgs@tvetmara.edu.my',
                          onPressed: () => onFillDemo(
                              'kp_dgs@tvetmara.edu.my', 'password123'),
                        ),
                        _DemoLoginButton(
                          label: 'KP DED',
                          subtitle: 'Program dengan KJ: DED sahaja',
                          icon: Icons.account_tree,
                          email: 'kp_ded@tvetmara.edu.my',
                          onPressed: () => onFillDemo(
                              'kp_ded@tvetmara.edu.my', 'password123'),
                        ),
                      ],
                    ),
                    _DemoLoginSection(
                      title: 'Pensyarah Real Demo',
                      buttons: [
                        _DemoLoginButton(
                          label: 'SYARIFAH BINTI ABDUL RAHIM',
                          subtitle: 'Pensyarah Elektrik - akaun sebenar demo',
                          icon: Icons.menu_book,
                          email: 'lecturer046@tvetmara.edu.my',
                          onPressed: () => onFillDemo(
                              'lecturer046@tvetmara.edu.my', 'password123'),
                        ),
                        _DemoLoginButton(
                          label: 'Zabhin bin Mohd Arbai',
                          subtitle: 'Pensyarah DGS - akaun sebenar demo',
                          icon: Icons.menu_book,
                          email: 'lecturer001@tvetmara.edu.my',
                          onPressed: () => onFillDemo(
                              'lecturer001@tvetmara.edu.my', 'password123'),
                        ),
                      ],
                    ),
                    _DemoLoginSection(
                      title: 'Legacy Demo Pensyarah',
                      buttons: [
                        _DemoLoginButton(
                          label: 'Demo Pensyarah DED',
                          subtitle: 'Akaun demo lama - bukan pensyarah sebenar',
                          icon: Icons.person_outline,
                          email: 'pensyarah_ded@tvetmara.edu.my',
                          onPressed: () => onFillDemo(
                              'pensyarah_ded@tvetmara.edu.my', 'password123'),
                        ),
                        _DemoLoginButton(
                          label: 'Demo Pensyarah DGS',
                          subtitle: 'Akaun demo lama - bukan pensyarah sebenar',
                          icon: Icons.person_outline,
                          email: 'pensyarah_dgs@tvetmara.edu.my',
                          onPressed: () => onFillDemo(
                              'pensyarah_dgs@tvetmara.edu.my', 'password123'),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 20),
                  TextField(
                    controller: email,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.email],
                    decoration: const InputDecoration(
                      labelText: 'Emel',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: password,
                    obscureText: obscurePassword,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.password],
                    onSubmitted: (_) => loggingIn ? null : onSubmit(),
                    decoration: InputDecoration(
                      labelText: 'Kata Laluan',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        tooltip: obscurePassword
                            ? 'Tunjuk kata laluan'
                            : 'Sembunyi kata laluan',
                        onPressed: onTogglePassword,
                        icon: Icon(obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: loggingIn ? null : onSubmit,
                    icon: loggingIn
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.login),
                    label: Text(loggingIn ? 'Mengesahkan...' : 'Log Masuk'),
                  ),
                  if (kDebugMode) ...[
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: seedingDemo ? null : onSeedDemo,
                      icon: seedingDemo
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.dataset_outlined),
                      label: Text(seedingDemo
                          ? 'Seeding Demo Data...'
                          : 'Seed Demo Data (Debug Only)'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DemoLoginSection extends StatelessWidget {
  const _DemoLoginSection({
    required this.title,
    required this.buttons,
  });

  final String title;
  final List<Widget> buttons;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: const Color(0xff475569),
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: buttons,
          ),
        ],
      ),
    );
  }
}

class _DemoLoginButton extends StatelessWidget {
  const _DemoLoginButton({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.email,
    required this.onPressed,
  });

  final String label;
  final String subtitle;
  final IconData icon;
  final String email;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: '$label\n$subtitle\n$email',
      child: OutlinedButton.icon(
        key: ValueKey('demo-login-$email'),
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 210),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                subtitle,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: const Color(0xff64748b),
                    ),
              ),
            ],
          ),
        ),
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
