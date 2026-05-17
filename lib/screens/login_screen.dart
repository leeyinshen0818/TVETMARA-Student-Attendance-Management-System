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
        const SnackBar(content: Text('Invalid demo email. Use admin or lecturer account.')),
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
              color: const Color(0xff1e3a8a),
              padding: const EdgeInsets.all(40),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.school, size: 44, color: Colors.white),
                  Spacer(),
                  Text(
                    'TVETMARA Student Attendance Management System',
                    style: TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Centralized attendance, timetable, discipline and replacement class management.',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  Spacer(),
                  Text('Prototype Flutter build', style: TextStyle(color: Colors.white54)),
                ],
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
                        Text('Sign in', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        const Text('Select a demo account. Any password is accepted.'),
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
                              label: const Text('Admin'),
                            ),
                            OutlinedButton.icon(
                              onPressed: () {
                                email.text = 'lecturer@tvetmara.edu.my';
                                password.text = 'lecturer123';
                              },
                              icon: const Icon(Icons.menu_book),
                              label: const Text('Lecturer'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: email,
                          decoration: const InputDecoration(labelText: 'Username / Email', prefixIcon: Icon(Icons.email_outlined)),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: password,
                          obscureText: true,
                          decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock_outline)),
                        ),
                        const SizedBox(height: 20),
                        FilledButton.icon(
                          onPressed: _login,
                          icon: const Icon(Icons.login),
                          label: const Text('Login'),
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
