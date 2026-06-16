import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tvetmara_student_attendance/models/app_models.dart';
import 'package:tvetmara_student_attendance/services/timetable_xlsx_export_service.dart';

TimetableSlot _makeSlot({
  String id = 'slot1',
  String subjectCode = 'DED10044',
  String subjectName = 'Wiring Practice',
  String lecturerName = 'Pn. Siti',
  String day = 'Isnin',
  String startTime = '08:00',
  String endTime = '12:00',
  String room = 'LAB A',
  String? roomName,
  String status = 'active',
  String program = 'DED',
  String? programId,
  String section = 'DED 1A',
  String? classId,
  String? weekStart,
  String? weekEnd,
  bool isOfficial = true,
  String? importStatus,
  bool hasConflict = false,
  List<String> conflictTypes = const [],
}) {
  return TimetableSlot(
    id: id,
    session: 'JAN_JUN_2026',
    semester: 1,
    program: program,
    programId: programId ?? program,
    section: section,
    classId: classId ?? section,
    subjectCode: subjectCode,
    subjectName: subjectName,
    lecturerId: 'lec1',
    lecturerName: lecturerName,
    day: day,
    date: '',
    startTime: startTime,
    endTime: endTime,
    weekStart: weekStart ?? '1',
    weekEnd: weekEnd ?? '18',
    room: room,
    roomName: roomName,
    enrolled: 30,
    capacity: 40,
    classType: 'lecture',
    slotType: 'regular',
    status: status,
    isOfficial: isOfficial,
    importStatus: importStatus,
    hasConflict: hasConflict,
    conflictTypes: conflictTypes,
  );
}

TimetableXlsxExportParams _defaultParams({
  List<TimetableSlot>? slots,
  String? filterProgram,
  String? filterClass,
  String? filterLecturer,
  String? filterRoom,
  String? filterDay,
  String? filterStatus,
}) {
  return TimetableXlsxExportParams(
    slots: slots ??
        [
          _makeSlot(),
          _makeSlot(
            id: 'slot2',
            subjectCode: 'DED10055',
            subjectName: 'Electrical Principles',
            day: 'Selasa',
            startTime: '14:00',
            endTime: '16:00',
            classId: 'DED 1B',
            section: 'DED 1B',
          ),
        ],
    academicSessionId: 'JAN_JUN_2026',
    scopeTitle: 'Jabatan Elektrik',
    scopeProgramIds: ['DED', 'DCP', 'DCB'],
    generatedByName: 'Ahmad',
    generatedByRole: 'KJ Elektrik',
    generatedAt: DateTime(2026, 6, 16, 11, 0),
    filterProgram: filterProgram,
    filterClass: filterClass,
    filterLecturer: filterLecturer,
    filterRoom: filterRoom,
    filterDay: filterDay,
    filterStatus: filterStatus,
  );
}

void main() {
  group('buildTimetableXlsx', () {
    test('returns non-empty bytes', () {
      final bytes = buildTimetableXlsx(_defaultParams());
      expect(bytes, isNotEmpty);
    });

    test('returns valid XLSX that can be decoded', () {
      final bytes = buildTimetableXlsx(_defaultParams());
      final decoded = Excel.decodeBytes(bytes);
      expect(decoded.tables, isNotEmpty);
      expect(decoded.tables.containsKey('Jadual Rasmi'), isTrue);
    });

    test('contains official title and session metadata', () {
      final bytes = buildTimetableXlsx(_defaultParams());
      final decoded = Excel.decodeBytes(bytes);
      final sheet = decoded.tables['Jadual Rasmi']!;
      final allText = sheet.rows
          .expand((row) => row.map((cell) => cell?.value?.toString() ?? ''))
          .join(' ');

      expect(allText, contains('TVETMARA'));
      expect(allText, contains('SISTEM KEHADIRAN TVETMARA'));
      expect(allText, contains('JADUAL RASMI JABATAN ELEKTRIK'));
      expect(allText, contains('JAN_JUN_2026'));
    });

    test('contains scope and generated info', () {
      final bytes = buildTimetableXlsx(_defaultParams());
      final decoded = Excel.decodeBytes(bytes);
      final sheet = decoded.tables['Jadual Rasmi']!;
      final allText = sheet.rows
          .expand((row) => row.map((cell) => cell?.value?.toString() ?? ''))
          .join(' ');

      expect(allText, contains('Jabatan Elektrik'));
      expect(allText, contains('DED'));
      expect(allText, contains('DCP'));
      expect(allText, contains('DCB'));
      expect(allText, contains('KJ Elektrik'));
      expect(allText, contains('16/06/2026'));
    });

    test('data rows match slot count', () {
      final slots = [
        _makeSlot(id: 's1'),
        _makeSlot(id: 's2', day: 'Selasa'),
        _makeSlot(id: 's3', day: 'Rabu'),
      ];
      final bytes = buildTimetableXlsx(_defaultParams(slots: slots));
      final decoded = Excel.decodeBytes(bytes);
      final sheet = decoded.tables['Jadual Rasmi']!;

      // Find the header row by looking for "Bil."
      int? headerRowIndex;
      for (var i = 0; i < sheet.rows.length; i++) {
        final rowValues =
            sheet.rows[i].map((c) => c?.value?.toString() ?? '').toList();
        if (rowValues.contains('Bil.')) {
          headerRowIndex = i;
          break;
        }
      }
      expect(headerRowIndex, isNotNull, reason: 'Table header row not found');

      // Count data rows after header (before footer)
      var dataRowCount = 0;
      for (var i = headerRowIndex! + 1; i < sheet.rows.length; i++) {
        final firstCell = sheet.rows[i].firstOrNull?.value?.toString() ?? '';
        // Data rows start with "1", "2", "3" etc. (Bil. column)
        if (int.tryParse(firstCell) != null) {
          dataRowCount++;
        }
      }
      expect(dataRowCount, 3);
    });

    test('contains table column headers without row-level status', () {
      final bytes = buildTimetableXlsx(_defaultParams());
      final decoded = Excel.decodeBytes(bytes);
      final sheet = decoded.tables['Jadual Rasmi']!;
      final headerRow = sheet.rows.firstWhere(
        (row) => row.any((cell) => cell?.value?.toString() == 'Bil.'),
      );
      final headerText =
          headerRow.map((cell) => cell?.value?.toString() ?? '').toList();

      expect(headerText, contains('Bil.'));
      expect(headerText, contains('Kod Kursus'));
      expect(headerText, contains('Nama Subjek'));
      expect(headerText, contains('Program'));
      expect(headerText, contains('Kelas'));
      expect(headerText, contains('Pensyarah'));
      expect(headerText, contains('Hari'));
      expect(headerText, contains('Masa'));
      expect(headerText, contains('Bilik'));
      expect(headerText, contains('Minggu'));
      expect(headerText, isNot(contains('Status')));
    });

    test('contains timetable status metadata', () {
      final bytes = buildTimetableXlsx(_defaultParams());
      final decoded = Excel.decodeBytes(bytes);
      final sheet = decoded.tables['Jadual Rasmi']!;
      final allText = sheet.rows
          .expand((row) => row.map((cell) => cell?.value?.toString() ?? ''))
          .join(' ');

      expect(allText, contains('Status Jadual:'));
      expect(allText, contains('Rasmi'));
    });

    test('contains footer text', () {
      final bytes = buildTimetableXlsx(_defaultParams());
      final decoded = Excel.decodeBytes(bytes);
      final sheet = decoded.tables['Jadual Rasmi']!;
      final allText = sheet.rows
          .expand((row) => row.map((cell) => cell?.value?.toString() ?? ''))
          .join(' ');

      expect(allText, contains('Dokumen ini dijana secara automatik'));
      expect(allText, contains('Jumlah rekod dieksport: 2'));
    });
  });

  group('xlsxStatusLabel', () {
    test('maps active to Rasmi', () {
      expect(xlsxStatusLabel('active'), 'Rasmi');
    });

    test('maps draft to Draf', () {
      expect(xlsxStatusLabel('draft'), 'Draf');
    });

    test('maps conflict_pending to Konflik', () {
      expect(xlsxStatusLabel('conflict_pending'), 'Konflik');
    });

    test('maps inactive to Tidak Aktif', () {
      expect(xlsxStatusLabel('inactive'), 'Tidak Aktif');
    });

    test('maps empty status to Rasmi', () {
      expect(xlsxStatusLabel(''), 'Rasmi');
    });

    test('is case-insensitive', () {
      expect(xlsxStatusLabel('ACTIVE'), 'Rasmi');
      expect(xlsxStatusLabel('Draft'), 'Draf');
      expect(xlsxStatusLabel('INACTIVE'), 'Tidak Aktif');
    });
  });

  group('buildExportFilename', () {
    test('includes scope and session for unfiltered export', () {
      final filename = buildExportFilename(_defaultParams());
      expect(filename, contains('jadual_rasmi'));
      expect(filename, contains('jan_jun_2026'));
      expect(filename, contains('jabatan_elektrik'));
      expect(filename, endsWith('.xlsx'));
    });

    test('uses program filter when active', () {
      final filename = buildExportFilename(
        _defaultParams(filterProgram: 'DED'),
      );
      expect(filename, contains('ded'));
      expect(filename, contains('jan_jun_2026'));
      expect(filename, endsWith('.xlsx'));
    });

    test('uses class filter when active (overrides program)', () {
      final filename = buildExportFilename(
        _defaultParams(filterProgram: 'DED', filterClass: 'DED 1A'),
      );
      expect(filename, contains('ded_1a'));
      expect(filename, contains('jan_jun_2026'));
      expect(filename, endsWith('.xlsx'));
    });

    test('KP DGS scope produces clean filename', () {
      final params = TimetableXlsxExportParams(
        slots: [],
        academicSessionId: 'JAN_JUN_2026',
        scopeTitle: 'Program DGS',
        scopeProgramIds: ['DGS'],
        generatedByName: 'Ali',
        generatedByRole: 'KP DGS',
        generatedAt: DateTime(2026, 6, 16),
      );
      final filename = buildExportFilename(params);
      expect(filename, contains('program_dgs'));
      expect(filename, endsWith('.xlsx'));
    });
  });

  group('empty state', () {
    test('empty slots produce valid XLSX with message', () {
      final params = _defaultParams(slots: []);
      final bytes = buildTimetableXlsx(params);
      expect(bytes, isNotEmpty);

      final decoded = Excel.decodeBytes(bytes);
      final sheet = decoded.tables['Jadual Rasmi']!;
      final allText = sheet.rows
          .expand((row) => row.map((cell) => cell?.value?.toString() ?? ''))
          .join(' ');

      expect(allText, contains('TVETMARA'));
      expect(allText, contains('Tiada rekod jadual untuk penapis semasa'));
      expect(allText, contains('Jumlah rekod dieksport: 0'));
    });
  });

  group('filter metadata display', () {
    test('shows active filters in summary section', () {
      final params = _defaultParams(
        filterProgram: 'DED',
        filterClass: 'DED 1A',
        filterDay: 'Isnin',
        filterStatus: 'active',
      );
      final bytes = buildTimetableXlsx(params);
      final decoded = Excel.decodeBytes(bytes);
      final sheet = decoded.tables['Jadual Rasmi']!;
      final allText = sheet.rows
          .expand((row) => row.map((cell) => cell?.value?.toString() ?? ''))
          .join(' ');

      expect(allText, contains('DED'));
      expect(allText, contains('DED 1A'));
      expect(allText, contains('Isnin'));
      expect(allText, contains('Rasmi')); // status label for 'active'
    });

    test('shows Semua for unset filters', () {
      final params = _defaultParams();
      final bytes = buildTimetableXlsx(params);
      final decoded = Excel.decodeBytes(bytes);
      final sheet = decoded.tables['Jadual Rasmi']!;
      final allText = sheet.rows
          .expand((row) => row.map((cell) => cell?.value?.toString() ?? ''))
          .join(' ');

      // All filters unset → should say 'Semua'
      expect(allText, contains('Semua'));
    });
  });

  group('slot data mapping', () {
    test('maps slot fields correctly in XLSX', () {
      final slot = _makeSlot(
        subjectCode: 'DED10044',
        subjectName: 'Wiring Practice',
        lecturerName: 'Pn. Siti',
        day: 'Isnin',
        startTime: '08:00',
        endTime: '12:00',
        roomName: 'ELEC LAB 1',
        weekStart: '1',
        weekEnd: '18',
        status: 'active',
        programId: 'DED',
        classId: 'DED 1A',
      );
      final params = _defaultParams(slots: [slot]);
      final bytes = buildTimetableXlsx(params);
      final decoded = Excel.decodeBytes(bytes);
      final sheet = decoded.tables['Jadual Rasmi']!;
      final allText = sheet.rows
          .expand((row) => row.map((cell) => cell?.value?.toString() ?? ''))
          .join(' ');

      expect(allText, contains('DED10044'));
      expect(allText, contains('Wiring Practice'));
      expect(allText, contains('Pn. Siti'));
      expect(allText, contains('Isnin'));
      expect(allText, contains('08:00-12:00'));
      expect(allText, contains('ELEC LAB 1'));
      expect(allText, contains('1-18'));
      expect(allText, contains('Rasmi'));
    });

    test('timetable status Draf appears for draft slots', () {
      final slot = _makeSlot(status: 'draft', isOfficial: false);
      final params = _defaultParams(slots: [slot]);
      final bytes = buildTimetableXlsx(params);
      final decoded = Excel.decodeBytes(bytes);
      final sheet = decoded.tables['Jadual Rasmi']!;
      final allText = sheet.rows
          .expand((row) => row.map((cell) => cell?.value?.toString() ?? ''))
          .join(' ');

      expect(allText, contains('Draf'));
    });

    test('timetable status Draf Konflik appears for conflicting draft slots',
        () {
      final slot = _makeSlot(
        status: 'draft',
        isOfficial: false,
        importStatus: 'conflict_pending',
      );
      final conflictSlot = _makeSlot(
        id: 'slot2',
        subjectCode: 'DED10055',
        status: 'draft',
        isOfficial: false,
        importStatus: 'conflict_pending',
      );
      final params = _defaultParams(slots: [slot, conflictSlot]);
      final bytes = buildTimetableXlsx(params);
      final decoded = Excel.decodeBytes(bytes);
      final sheet = decoded.tables['Jadual Rasmi']!;
      final allText = sheet.rows
          .expand((row) => row.map((cell) => cell?.value?.toString() ?? ''))
          .join(' ');

      expect(allText, contains('Draf / Konflik'));
    });
  });

  group('xlsxTimetableStatusLabel', () {
    test('maps official rows to Rasmi', () {
      expect(xlsxTimetableStatusLabel([_makeSlot()]), 'Rasmi');
    });

    test('maps draft rows without conflict to Draf', () {
      final slot = _makeSlot(
        status: 'draft',
        isOfficial: false,
        startTime: '08:00',
        endTime: '10:00',
      );
      final noConflictSlot = _makeSlot(
        id: 'slot2',
        status: 'draft',
        isOfficial: false,
        startTime: '10:00',
        endTime: '12:00',
      );
      expect(xlsxTimetableStatusLabel([slot, noConflictSlot]), 'Draf');
    });

    test('maps draft rows with conflict to Draf Konflik', () {
      final slot = _makeSlot(status: 'draft', isOfficial: false);
      final conflictSlot = _makeSlot(
        id: 'slot2',
        subjectCode: 'DED10055',
        status: 'draft',
        isOfficial: false,
      );
      expect(
        xlsxTimetableStatusLabel([slot, conflictSlot]),
        'Draf / Konflik',
      );
    });

    test('maps empty rows to Tiada Rekod', () {
      expect(xlsxTimetableStatusLabel(const []), 'Tiada Rekod');
    });

    test('legacy conflict status still maps to Konflik', () {
      final slot = _makeSlot(status: 'conflict_pending');
      final params = _defaultParams(slots: [slot]);
      final bytes = buildTimetableXlsx(params);
      final decoded = Excel.decodeBytes(bytes);
      final sheet = decoded.tables['Jadual Rasmi']!;
      final allText = sheet.rows
          .expand((row) => row.map((cell) => cell?.value?.toString() ?? ''))
          .join(' ');

      expect(allText, contains('Konflik'));
    });
  });
}
