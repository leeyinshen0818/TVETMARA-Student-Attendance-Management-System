import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tvetmara_student_attendance/main.dart';
import 'package:tvetmara_student_attendance/state/app_scope.dart';
import 'package:tvetmara_student_attendance/state/app_state.dart';

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
  });
}
