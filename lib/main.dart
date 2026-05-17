import 'package:flutter/material.dart';

import 'screens/home_shell.dart';
import 'screens/login_screen.dart';
import 'state/app_scope.dart';
import 'state/app_state.dart';

void main() {
  runApp(AppScope(state: AppState(), child: const TvetmaraApp()));
}

class TvetmaraApp extends StatelessWidget {
  const TvetmaraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TVETMARA Attendance',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xff2563eb),
          brightness: Brightness.light,
        ),
        cardTheme: const CardThemeData(
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
            side: BorderSide(color: Color(0xffe5e7eb)),
          ),
        ),
      ),
      home: Builder(
        builder: (context) {
          final state = AppScope.of(context);
          return AnimatedBuilder(
            animation: state,
            builder: (context, _) =>
                state.currentUser == null ? const LoginScreen() : const HomeShell(),
          );
        },
      ),
    );
  }
}
