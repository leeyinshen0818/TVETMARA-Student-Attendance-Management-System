import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'screens/home_shell.dart';
import 'screens/login_screen.dart';
import 'screens/timetable_slots_screen.dart';
import 'models/app_models.dart';
import 'state/app_scope.dart';
import 'state/app_state.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
    runApp(AppScope(state: AppState(), child: const TvetmaraApp()));
  } catch (error, stackTrace) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stackTrace,
        library: 'app startup',
      ),
    );
    runApp(StartupErrorApp(error: error));
  }
}

class StartupErrorApp extends StatelessWidget {
  const StartupErrorApp({super.key, required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xfff8fafc),
        body: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 560),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xffe2e8f0)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.error_outline,
                    color: Color(0xffdc2626), size: 32),
                const SizedBox(height: 14),
                const Text(
                  'Aplikasi gagal dimulakan',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Color(0xff0f172a),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Sila semak sambungan Firebase atau muat semula halaman.',
                  style: TextStyle(color: Color(0xff64748b)),
                ),
                const SizedBox(height: 12),
                SelectableText(
                  '$error',
                  style: const TextStyle(
                    color: Color(0xff991b1b),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
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
      onGenerateRoute: (settings) {
        if (settings.name == '/timetable/slots') {
          final args = settings.arguments;
          AppUser? selectedUser;
          if (args is Map<String, Object?>) {
            selectedUser = args['user'] as AppUser?;
          }
          return MaterialPageRoute(
            builder: (context) => TimetableSlotsScreen(
              selectedUser: selectedUser,
            ),
            settings: settings,
          );
        }
        return null;
      },
      home: SelectionArea(
        child: Builder(
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
      ),
    );
  }
}
