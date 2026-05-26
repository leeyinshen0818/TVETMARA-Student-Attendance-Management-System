import 'package:flutter_test/flutter_test.dart';
import 'package:tvetmara_student_attendance/core/utils/subject_id_normalizer.dart';
import 'package:tvetmara_student_attendance/data/subject_seed_data.dart';

void main() {
  test('subjectId normalization handles spaces and slash', () {
    expect(
      buildSubjectId(programId: 'DED', subjectCode: 'DUM 20132'),
      'DED_DUM_20132',
    );
    expect(
      buildSubjectId(programId: 'DGS', subjectCode: 'CUB2/31022'),
      'DGS_CUB2_31022',
    );
  });

  test('subject seed data has stable count and no duplicate ids', () {
    expect(subjectSeedTeachingRowsParsed, 368);
    expect(subjectSeedData.length, 303);

    final ids = subjectSeedData.map((subject) => subject.subjectId).toList();
    expect(ids.toSet().length, ids.length);
    expect(ids.any((id) => id.contains('/')), isFalse);
  });

  test('subjects for missing program master ids are reported as skipped', () {
    expect(subjectSeedRowsSkipped, 24);
    expect(subjectSeedMissingProgramIds, containsAll(['DCW', 'SPN']));
    expect(
      subjectSeedData.any((subject) => subject.programId == 'DCW'),
      isFalse,
    );
    expect(
      subjectSeedData.any((subject) => subject.programId == 'SPN'),
      isFalse,
    );
  });
}
