import '../core/constants/timetable_template.dart';
import '../core/utils/subject_id_normalizer.dart';
import '../models/timetable_import_result.dart';

class TimetableImportService {
  const TimetableImportService();

  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static final _timePattern = RegExp(r'^([01]\d|2[0-3]):[0-5]\d$');

  /// Parses and validates CSV timetable content only.
  ///
  /// This phase does not resolve lecturerEmail, programId, classId, roomId, or
  /// subjectId against Firestore and does not save any timetable data.
  TimetableImportResult parseAndValidate(String content) {
    final rows = _parseCsv(content)
        .where((row) => row.any((cell) => cell.trim().isNotEmpty))
        .toList();

    if (rows.isEmpty) {
      return const TimetableImportResult(
        totalRows: 0,
        validRows: 0,
        warningRows: 0,
        errorRows: 0,
        duplicateRows: 0,
        parsedRows: [],
        validationErrors: ['CSV file is empty.'],
        validationWarnings: [],
      );
    }

    final headers = rows.first.map((cell) => cell.trim()).toList();
    final normalizedHeaders = headers.map((header) => header.toLowerCase());
    final headerIndex = <String, int>{};
    final validationErrors = <String>[];
    final validationWarnings = <String>[];

    for (final entry in normalizedHeaders.toList().asMap().entries) {
      final header = entry.value;
      if (header.isEmpty) continue;
      if (headerIndex.containsKey(header)) {
        validationWarnings.add(
          'Duplicate CSV header "$header" found. The first column is used.',
        );
      } else {
        headerIndex[header] = entry.key;
      }
    }

    final requiredColumns = TimetableCsvTemplate.requiredColumns
        .map((column) => column.toLowerCase())
        .toSet();
    final allowedColumns = TimetableCsvTemplate.fullHeader
        .map((column) => column.toLowerCase())
        .toSet();

    final missing = TimetableCsvTemplate.requiredColumns
        .where((column) => !headerIndex.containsKey(column.toLowerCase()))
        .toList();
    if (missing.isNotEmpty) {
      validationErrors.add('Missing required columns: ${missing.join(', ')}.');
    }

    final unknown = headers
        .where((header) =>
            header.trim().isNotEmpty &&
            !allowedColumns.contains(header.trim().toLowerCase()))
        .toList();
    if (unknown.isNotEmpty) {
      validationWarnings.add(
        'Unknown columns ignored: ${unknown.join(', ')}.',
      );
    }

    if (validationErrors.isNotEmpty) {
      return TimetableImportResult(
        totalRows: rows.length - 1,
        validRows: 0,
        warningRows: 0,
        errorRows: 0,
        duplicateRows: 0,
        parsedRows: const [],
        validationErrors: validationErrors,
        validationWarnings: validationWarnings,
      );
    }

    final parsedRows = <TimetableImportParsedRow>[];
    final seenKeys = <String, int>{};

    for (var i = 1; i < rows.length; i++) {
      final row = rows[i];
      final rawData = <String, String>{};

      for (final column in TimetableCsvTemplate.fullHeader) {
        rawData[column] = _readCell(row, headerIndex[column.toLowerCase()]);
      }
      for (final column in requiredColumns) {
        rawData.putIfAbsent(column, () => '');
      }

      final rowErrors = <String>[];
      final rowWarnings = <String>[];
      final draft = _buildDraft(rawData, rowErrors, rowWarnings);

      if (draft != null) {
        final duplicateKey = _duplicateKey(draft);
        final previousRow = seenKeys[duplicateKey];
        if (previousRow != null) {
          rowErrors.add(
            'Duplicate timetable row. Same slot already appears at row $previousRow.',
          );
        } else {
          seenKeys[duplicateKey] = i + 1;
        }
      }

      final status = rowErrors.isNotEmpty
          ? rowErrors.any((error) => error.startsWith('Duplicate'))
              ? TimetableImportRowStatus.duplicate
              : TimetableImportRowStatus.error
          : rowWarnings.isNotEmpty
              ? TimetableImportRowStatus.warning
              : TimetableImportRowStatus.valid;

      parsedRows.add(
        TimetableImportParsedRow(
          rowNumber: i + 1,
          rawData: rawData,
          draft: draft,
          status: status,
          errors: List.unmodifiable(rowErrors),
          warnings: List.unmodifiable(rowWarnings),
        ),
      );
    }

    return TimetableImportResult(
      totalRows: parsedRows.length,
      validRows: parsedRows
          .where((row) => row.status == TimetableImportRowStatus.valid)
          .length,
      warningRows: parsedRows
          .where((row) => row.status == TimetableImportRowStatus.warning)
          .length,
      errorRows: parsedRows
          .where((row) => row.status == TimetableImportRowStatus.error)
          .length,
      duplicateRows: parsedRows
          .where((row) => row.status == TimetableImportRowStatus.duplicate)
          .length,
      parsedRows: List.unmodifiable(parsedRows),
      validationErrors: List.unmodifiable(validationErrors),
      validationWarnings: List.unmodifiable(validationWarnings),
    );
  }

  TimetableSlotDraft? _buildDraft(
    Map<String, String> rawData,
    List<String> errors,
    List<String> warnings,
  ) {
    final academicSessionId = _required(rawData, 'academicSessionId', errors);
    final programId = _normalizeProgramId(
      _required(rawData, 'programId', errors),
    );
    final classId = _required(rawData, 'classId', errors);
    final subjectCode = _required(rawData, 'subjectCode', errors);
    final subjectName = _required(rawData, 'subjectName', errors);
    final lecturerEmail = _required(rawData, 'lecturerEmail', errors);
    final roomId = _required(rawData, 'roomId', errors);
    final dayOfWeek = _normalizeDay(rawData['dayOfWeek'] ?? '', errors);
    final startTime =
        _readTime(rawData['startTime'] ?? '', 'startTime', errors);
    final endTime = _readTime(rawData['endTime'] ?? '', 'endTime', errors);
    final weekStart =
        _readWeek(rawData['weekStart'] ?? '', 'weekStart', errors);
    final weekEnd = _readWeek(rawData['weekEnd'] ?? '', 'weekEnd', errors);
    final status = _readStatus(rawData['status'] ?? '', errors);

    if (lecturerEmail.isNotEmpty && !_emailPattern.hasMatch(lecturerEmail)) {
      errors.add('lecturerEmail must be a valid email address.');
    }
    if (startTime != null &&
        endTime != null &&
        _timeToMinutes(startTime) >= _timeToMinutes(endTime)) {
      errors.add('startTime must be before endTime.');
    }
    if (weekStart != null && weekStart < 1) {
      errors.add('weekStart must be 1 or higher.');
    }
    if (weekEnd != null && weekEnd > 18) {
      errors.add('weekEnd must be 18 or lower.');
    }
    if (weekStart != null && weekEnd != null && weekStart > weekEnd) {
      errors.add('weekStart must be before or equal to weekEnd.');
    }

    if (errors.isNotEmpty) return null;

    final subjectId = (rawData['subjectId'] ?? '').trim().isEmpty
        ? buildSubjectId(programId: programId, subjectCode: subjectCode)
        : rawData['subjectId']!.trim();
    final lecturerName = _optional(rawData, 'lecturerName');
    final roomName = _optional(rawData, 'roomName');
    final remarks = _optional(rawData, 'remarks');

    if (lecturerName == null) {
      warnings.add('lecturerName is blank and will be resolved later.');
    }
    if (roomName == null) {
      warnings.add('roomName is blank and will be resolved later.');
    }

    return TimetableSlotDraft(
      academicSessionId: academicSessionId,
      programId: programId,
      departmentId: null,
      classId: classId,
      subjectId: subjectId,
      subjectCode: subjectCode,
      subjectName: subjectName,
      lecturerEmail: lecturerEmail.toLowerCase(),
      lecturerName: lecturerName,
      roomId: roomId,
      roomName: roomName,
      dayOfWeek: dayOfWeek!,
      startTime: startTime!,
      endTime: endTime!,
      weekStart: weekStart!,
      weekEnd: weekEnd!,
      status: status,
      remarks: remarks,
    );
  }

  String _required(
    Map<String, String> rawData,
    String column,
    List<String> errors,
  ) {
    final value = (rawData[column] ?? '').trim();
    if (value.isEmpty) {
      errors.add('$column is required.');
    }
    return value;
  }

  String? _optional(Map<String, String> rawData, String column) {
    final value = (rawData[column] ?? '').trim();
    return value.isEmpty ? null : value;
  }

  String _normalizeProgramId(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return trimmed;
    final trailingCode =
        RegExp(r'\(([A-Za-z0-9]{2,4})\)\s*$').firstMatch(trimmed)?.group(1);
    return (trailingCode ?? trimmed).toUpperCase();
  }

  String? _normalizeDay(String value, List<String> errors) {
    final trimmed = value.trim();
    final day = TimetableCsvTemplate.allowedDayOfWeekValues
        .where((allowed) => allowed.toLowerCase() == trimmed.toLowerCase())
        .firstOrNull;
    if (day == null) {
      errors.add(
        'dayOfWeek must be one of: ${TimetableCsvTemplate.allowedDayOfWeekValues.join(', ')}.',
      );
    }
    return day;
  }

  String? _readTime(String value, String column, List<String> errors) {
    final trimmed = value.trim();
    if (!_timePattern.hasMatch(trimmed)) {
      errors.add('$column must use HH:mm format.');
      return null;
    }
    return trimmed;
  }

  int _timeToMinutes(String value) {
    final parts = value.split(':');
    return (int.parse(parts[0]) * 60) + int.parse(parts[1]);
  }

  int? _readWeek(String value, String column, List<String> errors) {
    final parsed = int.tryParse(value.trim());
    if (parsed == null) {
      errors.add('$column must be an integer.');
    }
    return parsed;
  }

  String _readStatus(String value, List<String> errors) {
    final trimmed = value.trim().toLowerCase();
    if (trimmed.isEmpty) return 'active';
    if (!TimetableCsvTemplate.allowedStatusValues.contains(trimmed)) {
      errors.add(
        'status must be blank or one of: ${TimetableCsvTemplate.allowedStatusValues.join(', ')}.',
      );
    }
    return trimmed;
  }

  String _duplicateKey(TimetableSlotDraft draft) {
    return [
      draft.academicSessionId,
      draft.programId,
      draft.classId,
      draft.subjectCode,
      draft.lecturerEmail,
      draft.dayOfWeek,
      draft.startTime,
      draft.endTime,
      draft.roomId,
      draft.weekStart.toString(),
      draft.weekEnd.toString(),
    ].join('|').toLowerCase();
  }

  String _readCell(List<String> row, int? index) {
    if (index == null || index >= row.length) return '';
    return row[index].trim();
  }

  List<List<String>> _parseCsv(String content) {
    final rows = <List<String>>[];
    final row = <String>[];
    final cell = StringBuffer();
    var quoted = false;

    for (var i = 0; i < content.length; i++) {
      final char = content[i];
      if (char == '"') {
        if (quoted && i + 1 < content.length && content[i + 1] == '"') {
          cell.write('"');
          i++;
        } else {
          quoted = !quoted;
        }
      } else if (!quoted && char == ',') {
        row.add(cell.toString());
        cell.clear();
      } else if (!quoted && (char == '\n' || char == '\r')) {
        if (char == '\r' && i + 1 < content.length && content[i + 1] == '\n') {
          i++;
        }
        row.add(cell.toString());
        rows.add(List<String>.from(row));
        row.clear();
        cell.clear();
      } else {
        cell.write(char);
      }
    }

    if (cell.isNotEmpty || row.isNotEmpty) {
      row.add(cell.toString());
      rows.add(List<String>.from(row));
    }
    return rows;
  }
}
