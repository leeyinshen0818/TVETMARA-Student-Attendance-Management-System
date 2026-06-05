import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tvetmara_student_attendance/main.dart';
import 'package:tvetmara_student_attendance/state/app_scope.dart';
import 'package:tvetmara_student_attendance/state/app_state.dart';
import 'package:tvetmara_student_attendance/widgets/status_chip.dart';

void main() {
  testWidgets('shows Malay login screen', (tester) async {
    await tester.pumpWidget(
      AppScope(
        state: AppState(),
        child: const TvetmaraApp(),
      ),
    );

    expect(find.text('Log Masuk'), findsWidgets);
    expect(find.byIcon(Icons.login), findsOneWidget);
    expect(find.text('SYARIFAH BINTI ABDUL RAHIM'), findsOneWidget);
    expect(find.text('Zabhin bin Mohd Arbai'), findsOneWidget);
    expect(find.text('Pensyarah DED'), findsNothing);
    expect(find.text('Pensyarah DGS'), findsNothing);
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
