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
      title: 'Kehadiran TVETMARA',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xfff6f8fb),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xff1d4ed8),
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xff0f172a),
          elevation: 0,
        ),
        cardTheme: const CardThemeData(
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            side: BorderSide(color: Color(0xffe2e8f0)),
          ),
        ),
        chipTheme: const ChipThemeData(
          side: BorderSide(color: Color(0xffe2e8f0)),
          shape: StadiumBorder(),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xfff8fafc),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xffcbd5e1)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xffcbd5e1)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xff2563eb), width: 1.4),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
        dataTableTheme: const DataTableThemeData(
          headingTextStyle: TextStyle(
            color: Color(0xff334155),
            fontWeight: FontWeight.w800,
          ),
          dataTextStyle: TextStyle(color: Color(0xff1e293b)),
          dividerThickness: .7,
        ),
      ),
      home: Builder(
        builder: (context) {
          final state = AppScope.of(context);
          return AnimatedBuilder(
            animation: state,
            builder: (context, _) => state.currentUser == null
                ? const LoginScreen()
                : const HomeShell(),
          );
        },
      ),
    );
  }
}
