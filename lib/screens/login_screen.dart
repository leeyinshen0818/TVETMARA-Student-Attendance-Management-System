import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../data/seed_firestore.dart';
import '../state/app_scope.dart';
import '../widgets/app_theme.dart';

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

  bool _looksLikeEmail(String value) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value);
  }

  String _resetPasswordMessage(Object error) {
    if (error is FirebaseAuthException) {
      debugPrint('Password reset Firebase error: '
          '${error.code} ${error.message}');
      switch (error.code) {
        case 'invalid-email':
          return 'Format emel tidak sah.';
        case 'user-not-found':
          return 'Jika emel ini wujud, pautan tetapan semula akan dihantar.';
        case 'too-many-requests':
          return 'Terlalu banyak permintaan. Sila cuba semula kemudian.';
        case 'network-request-failed':
          return 'Ralat rangkaian. Sila semak sambungan internet.';
      }
    }
    debugPrint('Password reset unexpected error: $error');
    return 'Pautan tetapan semula tidak dapat dihantar. Sila cuba semula.';
  }

  Future<void> _showForgotPasswordDialog() async {
    final resetEmail = TextEditingController(text: email.text.trim());

    try {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          var sending = false;
          String? errorText;

          return StatefulBuilder(
            builder: (context, setDialogState) {
              Future<void> sendResetLink() async {
                if (sending) return;

                final value = resetEmail.text.trim();
                if (value.isEmpty) {
                  setDialogState(() {
                    errorText = 'Please enter your email address.';
                  });
                  return;
                }

                if (!_looksLikeEmail(value)) {
                  setDialogState(() {
                    errorText = 'Format emel tidak sah.';
                  });
                  return;
                }

                setDialogState(() {
                  sending = true;
                  errorText = null;
                });

                try {
                  await FirebaseAuth.instance
                      .sendPasswordResetEmail(email: value);
                  if (!dialogContext.mounted) return;
                  Navigator.pop(dialogContext);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Pautan tetapan semula kata laluan telah dihantar. Sila semak emel anda.',
                      ),
                    ),
                  );
                } catch (e) {
                  if (!dialogContext.mounted) return;
                  setDialogState(() {
                    sending = false;
                    errorText = _resetPasswordMessage(e);
                  });
                }
              }

              final width = MediaQuery.sizeOf(context).width;
              final mobile = width < 600;

              return AlertDialog(
                insetPadding: EdgeInsets.symmetric(
                  horizontal: mobile ? 16 : 40,
                  vertical: 24,
                ),
                title: const Text('Reset Password'),
                content: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Enter your email address and we will send a password reset link.',
                        style: TextStyle(color: AppColors.muted, height: 1.35),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Gunakan emel yang wujud dalam Firebase Auth dan boleh diakses untuk menerima pautan reset.',
                        style: TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 18),
                      TextField(
                        controller: resetEmail,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.done,
                        enabled: !sending,
                        autofillHints: const [AutofillHints.email],
                        onSubmitted: (_) => sendResetLink(),
                        decoration: InputDecoration(
                          labelText: 'Email address',
                          hintText: 'nama@tvetmara.edu.my',
                          prefixIcon: const Icon(Icons.email_outlined),
                          border: const OutlineInputBorder(),
                          errorText: errorText,
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed:
                        sending ? null : () => Navigator.pop(dialogContext),
                    child: const Text('Cancel'),
                  ),
                  FilledButton.icon(
                    onPressed: sending ? null : sendResetLink,
                    icon: sending
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.mark_email_read_outlined),
                    label: Text(sending ? 'Sending...' : 'Send Reset Link'),
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      resetEmail.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 860;
            final mobile = constraints.maxWidth < 600;
            final intro = _LoginIntro(
              compact: mobile || constraints.maxHeight < 620,
              mobile: mobile,
            );
            final form = _LoginForm(
              email: email,
              password: password,
              loggingIn: _loggingIn,
              seedingDemo: _seedingDemo,
              obscurePassword: _obscurePassword,
              mobile: mobile,
              onTogglePassword: () {
                setState(() => _obscurePassword = !_obscurePassword);
              },
              onSubmit: _login,
              onForgotPassword: _showForgotPasswordDialog,
              onSeedDemo: _seedDemoData,
              onFillDemo: _fillDemo,
            );

            if (wide) {
              return Padding(
                padding: const EdgeInsets.all(28),
                child: Row(
                  children: [
                    Expanded(
                      flex: 11,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: intro,
                      ),
                    ),
                    const SizedBox(width: 28),
                    Expanded(
                      flex: 10,
                      child: form,
                    ),
                  ],
                ),
              );
            }

            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(16, mobile ? 14 : 24, 16, 24),
              child: Column(
                children: [
                  SizedBox(width: double.infinity, child: intro),
                  SizedBox(height: mobile ? 14 : 20),
                  form,
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _LoginIntro extends StatelessWidget {
  const _LoginIntro({required this.compact, required this.mobile});

  final bool compact;
  final bool mobile;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryDark,
            AppColors.primary,
          ],
        ),
        borderRadius: mobile ? BorderRadius.circular(24) : null,
      ),
      padding: EdgeInsets.all(mobile ? 24 : 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                width: mobile ? 40 : 48,
                height: mobile ? 40 : 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: .1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.school,
                    color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 14),
              Text(
                'TVETMARA',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: mobile ? 18 : 22,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          SizedBox(height: mobile ? 32 : 56),
          Text(
            'Sistem Kehadiran TVETMARA',
            style: TextStyle(
              color: Colors.white,
              fontSize: mobile ? 28 : (compact ? 36 : 46),
              fontWeight: FontWeight.w900,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Pengurusan kehadiran, jadual dan laporan pelajar dalam satu platform.',
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: .85),
              fontSize: mobile ? 14 : 17,
              height: 1.45,
            ),
          ),
        ],
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
    required this.mobile,
    required this.onTogglePassword,
    required this.onSubmit,
    required this.onForgotPassword,
    required this.onSeedDemo,
    required this.onFillDemo,
  });

  final TextEditingController email;
  final TextEditingController password;
  final bool loggingIn;
  final bool seedingDemo;
  final bool obscurePassword;
  final bool mobile;
  final VoidCallback onTogglePassword;
  final VoidCallback onSubmit;
  final VoidCallback onForgotPassword;
  final VoidCallback onSeedDemo;
  final void Function(String email, String password) onFillDemo;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: mobile ? 0 : 16,
          vertical: mobile ? 0 : 24,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryDark.withValues(alpha: .07),
                  blurRadius: 32,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(mobile ? 20 : 30),
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
                  const Text(
                    'Masukkan emel dan kata laluan rasmi anda untuk meneruskan.',
                    style: TextStyle(color: AppColors.muted, height: 1.35),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: email,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.email],
                    decoration: const InputDecoration(
                      labelText: 'Emel',
                      hintText: 'nama@tvetmara.edu.my',
                      prefixIcon: Icon(Icons.email_outlined),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: password,
                    obscureText: obscurePassword,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.password],
                    onSubmitted: (_) => loggingIn ? null : onSubmit(),
                    decoration: InputDecoration(
                      labelText: 'Kata Laluan',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: const OutlineInputBorder(),
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
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: loggingIn ? null : onForgotPassword,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        minimumSize: const Size(44, 40),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('Forgot Password?'),
                    ),
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    height: 48,
                    child: FilledButton.icon(
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
                  ),
                  if (kDebugMode) ...[
                    const SizedBox(height: 16),
                    _DemoAccountsPanel(onFillDemo: onFillDemo),
                    const SizedBox(height: 10),
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

class _DemoAccountsPanel extends StatelessWidget {
  const _DemoAccountsPanel({required this.onFillDemo});

  final void Function(String email, String password) onFillDemo;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceTint,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: const ValueKey('demo-accounts-expansion'),
          tilePadding: const EdgeInsets.symmetric(horizontal: 14),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          leading: const Icon(Icons.science_outlined,
              color: AppColors.primary, size: 20),
          title: const Text(
            'Demo Accounts',
            style: TextStyle(
              color: AppColors.primaryDark,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          children: [
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
                  onPressed: () =>
                      onFillDemo('kj_elektrik@tvetmara.edu.my', 'password123'),
                ),
                _DemoLoginButton(
                  label: 'KJ Mekanikal',
                  subtitle: 'Skop: ITW / SLR / SMI',
                  icon: Icons.account_balance,
                  email: 'kj_mekanikal@tvetmara.edu.my',
                  onPressed: () =>
                      onFillDemo('kj_mekanikal@tvetmara.edu.my', 'password123'),
                ),
                _DemoLoginButton(
                  label: 'KJ Automotif',
                  subtitle: 'Skop: IMF / SMM / DMM',
                  icon: Icons.account_balance,
                  email: 'kj_automotif@tvetmara.edu.my',
                  onPressed: () =>
                      onFillDemo('kj_automotif@tvetmara.edu.my', 'password123'),
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
                  onPressed: () =>
                      onFillDemo('kp_dgs@tvetmara.edu.my', 'password123'),
                ),
                _DemoLoginButton(
                  label: 'KP DED',
                  subtitle: 'Program dengan KJ: DED sahaja',
                  icon: Icons.account_tree,
                  email: 'kp_ded@tvetmara.edu.my',
                  onPressed: () =>
                      onFillDemo('kp_ded@tvetmara.edu.my', 'password123'),
                ),
              ],
            ),
            _DemoLoginSection(
              title: 'Pensyarah Real Demo',
              buttons: [
                _DemoLoginButton(
                  label: 'SYARIFAH BINTI ABDUL RAHIM',
                  subtitle: 'Pensyarah Elektrik - akaun sebenar',
                  icon: Icons.menu_book,
                  email: 'lecturer046@tvetmara.edu.my',
                  onPressed: () =>
                      onFillDemo('lecturer046@tvetmara.edu.my', 'password123'),
                ),
                _DemoLoginButton(
                  label: 'Zabhin bin Mohd Arbai',
                  subtitle: 'Pensyarah DGS - akaun sebenar',
                  icon: Icons.menu_book,
                  email: 'lecturer001@tvetmara.edu.my',
                  onPressed: () =>
                      onFillDemo('lecturer001@tvetmara.edu.my', 'password123'),
                ),
              ],
            ),
          ],
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
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppColors.muted,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
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
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
          minimumSize: const Size(0, 32),
          visualDensity: VisualDensity.compact,
        ),
        icon: Icon(icon, size: 14),
        label: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
