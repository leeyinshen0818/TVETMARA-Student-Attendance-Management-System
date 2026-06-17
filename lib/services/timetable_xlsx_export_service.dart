import 'package:excel/excel.dart';

import '../models/app_models.dart';

// ---------------------------------------------------------------------------
// Data class holding all export context
// ---------------------------------------------------------------------------

class TimetableXlsxExportParams {
  const TimetableXlsxExportParams({
    required this.slots,
    required this.academicSessionId,
    required this.scopeTitle,
    required this.scopeProgramIds,
    required this.generatedByName,
    required this.generatedByRole,
    required this.generatedAt,
    this.filterProgram,
    this.filterClass,
    this.filterLecturer,
    this.filterRoom,
    this.filterDay,
    this.filterStatus,
  });

  final List<TimetableSlot> slots;
  final String academicSessionId;
  final String scopeTitle;
  final List<String> scopeProgramIds;
  final String generatedByName;
  final String generatedByRole;
  final DateTime generatedAt;
  final String? filterProgram;
  final String? filterClass;
  final String? filterLecturer;
  final String? filterRoom;
  final String? filterDay;
  final String? filterStatus;
}

// ---------------------------------------------------------------------------
// Status label mapping (mirrors screen _statusLabel logic)
// ---------------------------------------------------------------------------

String xlsxStatusLabel(String status) {
  return switch (status.toLowerCase()) {
    'active' || 'upcoming' => 'Rasmi',
    'draft' => 'Draf',
    'conflict_pending' => 'Konflik',
    'inactive' => 'Tidak Aktif',
    'cancelled' || 'canceled' => 'Dibatalkan',
    _ => status.isEmpty ? 'Rasmi' : status,
  };
}

String xlsxTimetableStatusLabel(List<TimetableSlot> slots) {
  if (slots.isEmpty) return 'Tiada Rekod';
  final draftSlots = slots.where(_isDraftSlot).toList();
  if (draftSlots.isEmpty) return 'Rasmi';
  final markedConflict = draftSlots.any((slot) {
    final status = slot.status.toLowerCase();
    final importStatus = slot.importStatus?.toLowerCase();
    return status == 'conflict_pending' ||
        importStatus == 'conflict_pending' ||
        slot.hasConflict ||
        slot.conflictTypes.isNotEmpty;
  });
  return markedConflict || _hasCoreConflict(slots) ? 'Draf / Konflik' : 'Draf';
}

bool _isDraftSlot(TimetableSlot slot) {
  final status = slot.status.toLowerCase();
  final importStatus = slot.importStatus?.toLowerCase();
  return !slot.isOfficial ||
      status == 'draft' ||
      status == 'conflict_pending' ||
      importStatus == 'draft_saved' ||
      importStatus == 'conflict_pending';
}

// ---------------------------------------------------------------------------
// Filename builder
// ---------------------------------------------------------------------------

String buildExportFilename(TimetableXlsxExportParams params) {
  final segments = <String>['jadual_rasmi'];
  if (params.filterClass != null && params.filterClass!.isNotEmpty) {
    segments.add(_safe(params.filterClass!));
  } else if (params.filterProgram != null && params.filterProgram!.isNotEmpty) {
    segments.add(_safe(params.filterProgram!));
  } else {
    segments.add(_safe(params.scopeTitle));
  }
  segments.add(_safe(params.academicSessionId));
  return '${segments.join('_')}.xlsx';
}

String _safe(String value) {
  return value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
}

// ---------------------------------------------------------------------------
// Day normalisation helpers (shared with timetable_view_export_service.dart)
// ---------------------------------------------------------------------------

String _normalDay(String value) {
  final upper = value.trim().toUpperCase();
  return switch (upper) {
    'MONDAY' || 'ISNIN' => 'Isnin',
    'TUESDAY' || 'SELASA' => 'Selasa',
    'WEDNESDAY' || 'RABU' => 'Rabu',
    'THURSDAY' || 'KHAMIS' => 'Khamis',
    'FRIDAY' || 'JUMAAT' => 'Jumaat',
    'SATURDAY' || 'SABTU' => 'Sabtu',
    'SUNDAY' || 'AHAD' => 'Ahad',
    _ => value,
  };
}

int _dayOrder(String day) {
  return switch (day) {
    'Isnin' => 1,
    'Selasa' => 2,
    'Rabu' => 3,
    'Khamis' => 4,
    'Jumaat' => 5,
    'Sabtu' => 6,
    'Ahad' => 7,
    _ => 99,
  };
}

bool _hasCoreConflict(List<TimetableSlot> slots) {
  final relevant = slots.where(_isConflictRelevant).toList();
  for (var i = 0; i < relevant.length; i++) {
    for (var j = i + 1; j < relevant.length; j++) {
      final a = relevant[i];
      final b = relevant[j];
      if (!_sameWindow(a, b)) continue;
      if (_sameNonEmpty(a.roomId ?? a.room, b.roomId ?? b.room) ||
          _sameNonEmpty(a.lecturerId, b.lecturerId) ||
          _sameNonEmpty(a.classId ?? a.section, b.classId ?? b.section)) {
        return true;
      }
    }
  }
  return false;
}

bool _isConflictRelevant(TimetableSlot slot) {
  final status = slot.status.toLowerCase();
  return status != 'inactive' && status != 'cancelled' && status != 'canceled';
}

bool _sameNonEmpty(String a, String b) {
  final left = a.trim();
  final right = b.trim();
  return left.isNotEmpty && left == right;
}

bool _sameWindow(TimetableSlot a, TimetableSlot b) {
  if ((a.academicSessionId ?? a.session) !=
      (b.academicSessionId ?? b.session)) {
    return false;
  }
  if (_normalDay(a.dayOfWeek ?? a.day) != _normalDay(b.dayOfWeek ?? b.day)) {
    return false;
  }
  final startA = _minutes(a.startTime);
  final endA = _minutes(a.endTime);
  final startB = _minutes(b.startTime);
  final endB = _minutes(b.endTime);
  if (startA == null || endA == null || startB == null || endB == null) {
    return false;
  }
  if (!(startA < endB && startB < endA)) return false;

  final weekStartA = int.tryParse(a.weekStart ?? a.date) ?? 1;
  final weekEndA = int.tryParse(a.weekEnd ?? a.date) ?? weekStartA;
  final weekStartB = int.tryParse(b.weekStart ?? b.date) ?? 1;
  final weekEndB = int.tryParse(b.weekEnd ?? b.date) ?? weekStartB;
  return weekStartA <= weekEndB && weekStartB <= weekEndA;
}

int? _minutes(String value) {
  final parts = value.trim().split(':');
  if (parts.length != 2) return null;
  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);
  if (hour == null || minute == null) return null;
  return (hour * 60) + minute;
}

// ---------------------------------------------------------------------------
// Slot value helpers (mirrors screen helpers)
// ---------------------------------------------------------------------------

String _slotProgramValue(TimetableSlot slot) {
  final normalized = slot.programId?.trim();
  if (normalized != null && normalized.isNotEmpty) return normalized;
  return slot.program.trim();
}

String _slotClassValue(TimetableSlot slot) {
  final normalized = slot.classId?.trim();
  if (normalized != null && normalized.isNotEmpty) return normalized;
  return slot.section.trim();
}

String _slotRoomValue(TimetableSlot slot) {
  final normalized = slot.roomName?.trim();
  if (normalized != null && normalized.isNotEmpty) return normalized;
  return slot.room.trim();
}

String _weekText(TimetableSlot slot) {
  final start = slot.weekStart;
  final end = slot.weekEnd;
  if (start != null && end != null) return '$start-$end';
  if (slot.date.isNotEmpty) return slot.date;
  return '-';
}

// ---------------------------------------------------------------------------
// Colour constants
// ---------------------------------------------------------------------------

const _darkBlue = '#1B3A5C';
const _darkBlueText = '#1B3A5C';
const _white = '#FFFFFF';
const _altRowBg = '#EBF0FA';
const _metaBg = '#F0F4FA';
const _greyText = '#6C757D';

ExcelColor _color(String hex) => ExcelColor.fromHexString(hex);

// ---------------------------------------------------------------------------
// Shared cell styles
// ---------------------------------------------------------------------------

CellStyle _titleStyle() => CellStyle(
      bold: true,
      fontSize: 16,
      fontColorHex: _color(_darkBlueText),
      horizontalAlign: HorizontalAlign.Left,
      verticalAlign: VerticalAlign.Center,
    );

CellStyle _subtitleStyle() => CellStyle(
      bold: true,
      fontSize: 12,
      fontColorHex: _color(_darkBlueText),
      horizontalAlign: HorizontalAlign.Left,
      verticalAlign: VerticalAlign.Center,
    );

CellStyle _metaLabelStyle() => CellStyle(
      bold: true,
      fontSize: 10,
      fontColorHex: _color(_darkBlueText),
      horizontalAlign: HorizontalAlign.Left,
      verticalAlign: VerticalAlign.Center,
    );

CellStyle _metaValueStyle() => CellStyle(
      fontSize: 10,
      horizontalAlign: HorizontalAlign.Left,
      verticalAlign: VerticalAlign.Center,
    );

CellStyle _filterLabelStyle() => CellStyle(
      bold: true,
      fontSize: 10,
      fontColorHex: _color(_darkBlueText),
      backgroundColorHex: _color(_metaBg),
      horizontalAlign: HorizontalAlign.Left,
      verticalAlign: VerticalAlign.Center,
    );

CellStyle _filterValueStyle() => CellStyle(
      fontSize: 10,
      backgroundColorHex: _color(_metaBg),
      horizontalAlign: HorizontalAlign.Left,
      verticalAlign: VerticalAlign.Center,
    );

CellStyle _tableHeaderStyle() => CellStyle(
      bold: true,
      fontSize: 10,
      fontColorHex: _color(_white),
      backgroundColorHex: _color(_darkBlue),
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      textWrapping: TextWrapping.WrapText,
      leftBorder: Border(borderStyle: BorderStyle.Thin),
      rightBorder: Border(borderStyle: BorderStyle.Thin),
      topBorder: Border(borderStyle: BorderStyle.Thin),
      bottomBorder: Border(borderStyle: BorderStyle.Thin),
    );

CellStyle _dataCellStyle({bool altRow = false, bool wrap = false}) => CellStyle(
      fontSize: 10,
      backgroundColorHex: altRow ? _color(_altRowBg) : _color(_white),
      horizontalAlign: HorizontalAlign.Left,
      verticalAlign: VerticalAlign.Center,
      textWrapping: wrap ? TextWrapping.WrapText : TextWrapping.Clip,
      leftBorder: Border(borderStyle: BorderStyle.Thin),
      rightBorder: Border(borderStyle: BorderStyle.Thin),
      topBorder: Border(borderStyle: BorderStyle.Thin),
      bottomBorder: Border(borderStyle: BorderStyle.Thin),
    );

CellStyle _footerStyle() => CellStyle(
      italic: true,
      fontSize: 9,
      fontColorHex: _color(_greyText),
      horizontalAlign: HorizontalAlign.Left,
      verticalAlign: VerticalAlign.Center,
    );

// ---------------------------------------------------------------------------
// Formatted date/time for display
// ---------------------------------------------------------------------------

String _formatDateTime(DateTime dt) {
  final day = dt.day.toString().padLeft(2, '0');
  final month = dt.month.toString().padLeft(2, '0');
  final year = dt.year.toString();
  final hour = dt.hour.toString().padLeft(2, '0');
  final minute = dt.minute.toString().padLeft(2, '0');
  return '$day/$month/$year $hour:$minute';
}

// ---------------------------------------------------------------------------
// Table column definitions
// ---------------------------------------------------------------------------

const _tableColumns = [
  'Bil.',
  'Kod Kursus',
  'Nama Subjek',
  'Program',
  'Kelas',
  'Pensyarah',
  'Hari',
  'Masa',
  'Bilik',
  'Minggu',
];

const _columnWidths = <double>[
  8, // Bil.
  14, // Kod Kursus
  38, // Nama Subjek
  12, // Program
  14, // Kelas
  34, // Pensyarah
  14, // Hari
  16, // Masa
  24, // Bilik
  14, // Minggu
];

// Columns that should text-wrap: Nama Subjek (2), Pensyarah (5), Bilik (8)
const _wrapColumns = {2, 5, 8};

// ---------------------------------------------------------------------------
// Main builder
// ---------------------------------------------------------------------------

List<int> buildTimetableXlsx(TimetableXlsxExportParams params) {
  final excel = Excel.createExcel();

  // Use first default sheet and rename it
  final defaultSheetName = excel.getDefaultSheet() ?? 'Sheet1';
  excel.rename(defaultSheetName, 'Jadual Rasmi');
  final sheet = excel['Jadual Rasmi'];

  // Set column widths
  for (var col = 0; col < _columnWidths.length; col++) {
    sheet.setColumnWidth(col, _columnWidths[col]);
  }

  final totalCols = _tableColumns.length;
  var row = 0;

  // ---- Row 0: Main Title ----
  _mergedTextRow(sheet, row, totalCols, 'TVETMARA', _titleStyle());
  row++;

  // ---- Row 1: Subtitle ----
  _mergedTextRow(
    sheet,
    row,
    totalCols,
    'SISTEM KEHADIRAN TVETMARA',
    _subtitleStyle(),
  );
  row++;

  // ---- Row 2: Blank ----
  row++;

  // ---- Row 3: Scope Title ----
  _mergedTextRow(
    sheet,
    row,
    totalCols,
    'JADUAL RASMI ${params.scopeTitle.toUpperCase()}',
    _subtitleStyle(),
  );
  row++;

  // ---- Row 4-7: Metadata ----
  _labelValueRow(
    sheet,
    row,
    'Sesi Akademik:',
    params.academicSessionId,
    _metaLabelStyle(),
    _metaValueStyle(),
  );
  row++;

  final scopeDesc = params.scopeProgramIds.isNotEmpty
      ? '${params.scopeTitle} (${params.scopeProgramIds.join(', ')})'
      : params.scopeTitle;
  _labelValueRow(
      sheet, row, 'Skop:', scopeDesc, _metaLabelStyle(), _metaValueStyle());
  row++;

  _labelValueRow(sheet, row, 'Dijana Oleh:', params.generatedByRole,
      _metaLabelStyle(), _metaValueStyle());
  row++;

  _labelValueRow(
    sheet,
    row,
    'Tarikh Dijana:',
    _formatDateTime(params.generatedAt),
    _metaLabelStyle(),
    _metaValueStyle(),
  );
  row++;

  _labelValueRow(
    sheet,
    row,
    'Status Jadual:',
    xlsxTimetableStatusLabel(params.slots),
    _metaLabelStyle(),
    _metaValueStyle(),
  );
  row++;

  // ---- Row 8: Blank spacing ----
  row++;

  // ---- Rows 9+: Filter/Summary section ----
  _mergedTextRow(sheet, row, totalCols, 'MAKLUMAT PENAPIS PAPARAN SEMASA',
      _subtitleStyle());
  row++;

  final filterRows = <(String, String)>[
    ('Jumlah Rekod:', '${params.slots.length}'),
    ('Sesi Akademik:', params.academicSessionId),
    ('Program:', params.filterProgram ?? 'Semua'),
    ('Kelas:', params.filterClass ?? 'Semua'),
    ('Pensyarah:', params.filterLecturer ?? 'Semua'),
    ('Bilik:', params.filterRoom ?? 'Semua'),
    ('Hari:', params.filterDay ?? 'Semua'),
    (
      'Status:',
      params.filterStatus != null
          ? xlsxStatusLabel(params.filterStatus!)
          : 'Semua'
    ),
  ];

  for (final (label, value) in filterRows) {
    _labelValueRow(
        sheet, row, label, value, _filterLabelStyle(), _filterValueStyle());
    row++;
  }

  // ---- Blank spacing before table ----
  row++;

  // ---- Table header row ----
  final headerStyle = _tableHeaderStyle();
  for (var col = 0; col < _tableColumns.length; col++) {
    final cell = sheet.cell(
      CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row),
    );
    cell.value = TextCellValue(_tableColumns[col]);
    cell.cellStyle = headerStyle;
  }
  row++;

  // ---- Data rows ----
  if (params.slots.isEmpty) {
    // Empty state message
    _mergedTextRow(
      sheet,
      row,
      totalCols,
      'Tiada rekod jadual untuk penapis semasa.',
      CellStyle(
        italic: true,
        fontSize: 11,
        fontColorHex: _color(_greyText),
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
      ),
    );
    row++;
  } else {
    // Sort slots by day → time → class → subject code
    final sorted = List<TimetableSlot>.from(params.slots)
      ..sort((a, b) {
        final dayA = _dayOrder(_normalDay(a.dayOfWeek ?? a.day));
        final dayB = _dayOrder(_normalDay(b.dayOfWeek ?? b.day));
        if (dayA != dayB) return dayA.compareTo(dayB);
        final timeCompare = a.startTime.compareTo(b.startTime);
        if (timeCompare != 0) return timeCompare;
        final classCompare = _slotClassValue(a).compareTo(_slotClassValue(b));
        if (classCompare != 0) return classCompare;
        return a.subjectCode.compareTo(b.subjectCode);
      });

    for (var i = 0; i < sorted.length; i++) {
      final slot = sorted[i];
      final altRow = i.isOdd;
      final values = <String>[
        '${i + 1}',
        slot.subjectCode,
        slot.subjectName,
        _slotProgramValue(slot),
        _slotClassValue(slot),
        slot.lecturerName,
        _normalDay(slot.dayOfWeek ?? slot.day),
        '${slot.startTime}-${slot.endTime}',
        _slotRoomValue(slot),
        _weekText(slot),
      ];

      for (var col = 0; col < values.length; col++) {
        final cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row),
        );
        cell.value = TextCellValue(values[col]);
        cell.cellStyle = _dataCellStyle(
          altRow: altRow,
          wrap: _wrapColumns.contains(col),
        );
      }
      row++;
    }
  }

  // ---- Blank spacing after table ----
  row++;

  // ---- Footer ----
  _mergedTextRow(
    sheet,
    row,
    totalCols,
    'Dokumen ini dijana secara automatik oleh Sistem Kehadiran TVETMARA.',
    _footerStyle(),
  );
  row++;

  _mergedTextRow(
    sheet,
    row,
    totalCols,
    'Jumlah rekod dieksport: ${params.slots.length}  |  '
    'Dijana: ${_formatDateTime(params.generatedAt)}',
    _footerStyle(),
  );

  // ---- Freeze pane at table header (optional, skip if not supported) ----
  // The excel 4.0.6 package does not reliably support freeze panes or
  // auto-filter. These features are skipped to avoid generating
  // a corrupted file.

  final bytes = excel.encode();
  if (bytes == null) return [];
  return bytes;
}

// ---------------------------------------------------------------------------
// Sheet helper: merged text row spanning all columns
// ---------------------------------------------------------------------------

void _mergedTextRow(
  Sheet sheet,
  int row,
  int totalCols,
  String text,
  CellStyle style,
) {
  final cell = sheet.cell(
    CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row),
  );
  cell.value = TextCellValue(text);
  cell.cellStyle = style;

  // Merge across table width
  if (totalCols > 1) {
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row),
      CellIndex.indexByColumnRow(columnIndex: totalCols - 1, rowIndex: row),
    );
  }
}

// ---------------------------------------------------------------------------
// Sheet helper: label + value on the same row (cols 0-1 for label, 2+ for value)
// ---------------------------------------------------------------------------

void _labelValueRow(
  Sheet sheet,
  int row,
  String label,
  String value,
  CellStyle labelStyle,
  CellStyle valueStyle,
) {
  // Label in column 0-1 (merged)
  final labelCell = sheet.cell(
    CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row),
  );
  labelCell.value = TextCellValue(label);
  labelCell.cellStyle = labelStyle;
  sheet.merge(
    CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row),
    CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row),
  );

  // Value in column 2+ (merged across remaining width)
  final valueCell = sheet.cell(
    CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row),
  );
  valueCell.value = TextCellValue(value);
  valueCell.cellStyle = valueStyle;
  sheet.merge(
    CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row),
    CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: row),
  );
}
// ---------------------------------------------------------------------------
// Class Timetable Export
// ---------------------------------------------------------------------------

List<int> buildClassTimetableXlsx({
  required String programId,
  required String programName,
  required String classId,
  required String academicSessionId,
  required String generatedBy,
  required DateTime generatedAt,
  required List<TimetableSlot> slots,
}) {
  final excel = Excel.createExcel();
  final sheet = excel['Jadual Kelas'];
  excel.setDefaultSheet('Jadual Kelas');

  if (excel.sheets.containsKey('Sheet1')) {
    excel.delete('Sheet1');
  }

  // Set column widths
  sheet.setColumnWidth(0, 15); // Masa
  sheet.setColumnWidth(1, 15); // Hari
  sheet.setColumnWidth(2, 15); // Kod Kursus
  sheet.setColumnWidth(3, 40); // Nama Kursus
  sheet.setColumnWidth(4, 30); // Pensyarah
  sheet.setColumnWidth(5, 20); // Bilik
  sheet.setColumnWidth(6, 15); // Minggu
  sheet.setColumnWidth(7, 15); // Jenis Slot
  sheet.setColumnWidth(8, 15); // Status

  final titleStyle = _titleStyle();
  final metaLabelStyle = _metaLabelStyle();
  final metaValueStyle = _metaValueStyle();

  int currentRow = 0;

  // Title
  _mergedTextRow(sheet, currentRow, 9, 'JADUAL WAKTU KELAS', titleStyle);
  currentRow += 2;

  // Meta details
  _labelValueRow(sheet, currentRow++, 'Program', '$programId - $programName',
      metaLabelStyle, metaValueStyle);
  _labelValueRow(
      sheet, currentRow++, 'Kelas', classId, metaLabelStyle, metaValueStyle);
  _labelValueRow(sheet, currentRow++, 'Sesi Akademik', academicSessionId,
      metaLabelStyle, metaValueStyle);
  _labelValueRow(sheet, currentRow++, 'Dijana Oleh', generatedBy,
      metaLabelStyle, metaValueStyle);
  _labelValueRow(sheet, currentRow++, 'Tarikh Jana',
      _formatDateTime(generatedAt), metaLabelStyle, metaValueStyle);
  currentRow++;

  // Table header
  final headerStyle = _tableHeaderStyle();
  final headers = [
    'Masa',
    'Hari',
    'Kod Kursus',
    'Nama Kursus',
    'Pensyarah',
    'Bilik',
    'Minggu',
    'Jenis Slot',
    'Status',
  ];

  for (var i = 0; i < headers.length; i++) {
    final cell = sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: currentRow));
    cell.value = TextCellValue(headers[i]);
    cell.cellStyle = headerStyle;
  }
  currentRow++;

  // Table rows
  final dataStyle = _dataCellStyle();
  final altDataStyle = _dataCellStyle(altRow: true);

  for (var i = 0; i < slots.length; i++) {
    final slot = slots[i];
    final rowStyle = (i % 2 == 0) ? dataStyle : altDataStyle;

    final rowData = [
      '${slot.startTime}-${slot.endTime}',
      _normalDay(slot.dayOfWeek ?? slot.day),
      slot.subjectCode,
      slot.subjectName,
      slot.lecturerName,
      slot.roomName ?? slot.room,
      '${slot.weekStart ?? '1'}-${slot.weekEnd ?? '18'}',
      slot.slotType,
      xlsxStatusLabel(slot.status),
    ];

    for (var j = 0; j < rowData.length; j++) {
      final cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: j, rowIndex: currentRow));
      cell.value = TextCellValue(rowData[j]);
      cell.cellStyle = rowStyle;
    }
    currentRow++;
  }

  return excel.encode()!;
}
