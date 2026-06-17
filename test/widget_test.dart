import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tvetmara_student_attendance/main.dart';
import 'package:tvetmara_student_attendance/state/app_scope.dart';
import 'package:tvetmara_student_attendance/state/app_state.dart';
import 'package:tvetmara_student_attendance/widgets/status_chip.dart';

void main() {
  testWidgets('shows Malay login screen', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      AppScope(
        state: AppState(),
        child: const TvetmaraApp(),
      ),
    );

    expect(find.text('Log Masuk'), findsWidgets);
    expect(find.byIcon(Icons.login), findsOneWidget);
    expect(find.text('Demo Accounts'), findsOneWidget);
    expect(find.text('KJ Elektrik'), findsNothing);

    final demoPanel = find.byKey(const ValueKey('demo-accounts-expansion'));
    await tester.ensureVisible(demoPanel);
    await tester.tap(demoPanel);
    await tester.pumpAndSettle();

    expect(find.text('KJ Elektrik'), findsOneWidget);
    expect(find.text('Skop: DED / DCP / DCB'), findsOneWidget);
    expect(find.text('KP DGS'), findsOneWidget);
    expect(find.text('Program tanpa KJ: DGS sahaja'), findsOneWidget);
    expect(find.text('SYARIFAH BINTI ABDUL RAHIM'), findsOneWidget);
    expect(find.text('Zabhin bin Mohd Arbai'), findsOneWidget);
    expect(find.text('Pensyarah DED'), findsNothing);
    expect(find.text('Pensyarah DGS'), findsNothing);
  });

  testWidgets('demo login buttons fill the intended lecturer emails',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      AppScope(
        state: AppState(),
        child: const TvetmaraApp(),
      ),
    );

    final demoPanel = find.byKey(const ValueKey('demo-accounts-expansion'));
    await tester.ensureVisible(demoPanel);
    await tester.tap(demoPanel);
    await tester.pumpAndSettle();

    final syarifahButton = find
        .byKey(const ValueKey('demo-login-lecturer046@tvetmara.edu.my'))
        .first;
    await tester.tap(syarifahButton);
    await tester.pump();
    expect(find.text('lecturer046@tvetmara.edu.my'), findsOneWidget);

    final demoDedButton = find
        .byKey(const ValueKey('demo-login-pensyarah_ded@tvetmara.edu.my'))
        .first;
    await tester.tap(demoDedButton);
    await tester.pump();
    expect(find.text('pensyarah_ded@tvetmara.edu.my'), findsOneWidget);
    expect(find.text('lecturer046@tvetmara.edu.my'), findsNothing);
  });

  testWidgets('forgot password dialog validates email before sending',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      AppScope(
        state: AppState(),
        child: const TvetmaraApp(),
      ),
    );

    await tester.tap(find.text('Forgot Password?'));
    await tester.pumpAndSettle();

    expect(find.text('Reset Password'), findsOneWidget);
    expect(
      find.text(
        'Enter your email address and we will send a password reset link.',
      ),
      findsOneWidget,
    );
    expect(
      find.text(
        'Gunakan emel yang wujud dalam Firebase Auth dan boleh diakses untuk menerima pautan reset.',
      ),
      findsOneWidget,
    );

    final resetEmailField = find.widgetWithText(TextField, 'Email address');
    await tester.enterText(resetEmailField, '');
    await tester.tap(find.text('Send Reset Link'));
    await tester.pump();
    expect(find.text('Please enter your email address.'), findsOneWidget);

    await tester.enterText(resetEmailField, 'not-an-email');
    await tester.tap(find.text('Send Reset Link'));
    await tester.pump();
    expect(find.text('Format emel tidak sah.'), findsOneWidget);
  });

  testWidgets('status chip localizes lowercase timetable status',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: StatusChip('active'),
        ),
      ),
    );

    expect(find.text('Aktif'), findsOneWidget);
    expect(find.text('active'), findsNothing);
  });
}
