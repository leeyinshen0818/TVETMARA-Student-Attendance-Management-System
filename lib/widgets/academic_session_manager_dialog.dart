import 'package:flutter/material.dart';

import '../models/app_models.dart';
import '../state/app_state.dart';
import 'status_chip.dart';

Future<void> showAcademicSessionManagerDialog({
  required BuildContext context,
  required AppState state,
}) async {
  if (!state.canManageAcademicSessions) return;
  await showDialog<void>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          final sessions = List<AcademicSession>.from(state.academicSessions)
            ..sort(
              (a, b) => a.academicSessionId.compareTo(b.academicSessionId),
            );
          final dialogWidth =
              (MediaQuery.sizeOf(context).width * 0.92).clamp(320.0, 960.0);
          return AlertDialog(
            insetPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            title: const Text('Pengurusan Sesi Akademik'),
            content: SizedBox(
              width: dialogWidth.toDouble(),
              child: sessions.isEmpty
                  ? const Text('Tiada sesi akademik dijumpai.')
                  : SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minWidth: 820),
                          child: DataTable(
                            horizontalMargin: 12,
                            columnSpacing: 18,
                            columns: const [
                              DataColumn(label: Text('Kod Sesi')),
                              DataColumn(label: Text('Nama Sesi')),
                              DataColumn(label: Text('Tarikh Mula')),
                              DataColumn(label: Text('Tarikh Tamat')),
                              DataColumn(label: Text('Status')),
                              DataColumn(label: Text('Aktif')),
                              DataColumn(label: Text('Tindakan')),
                            ],
                            rows: sessions.map((session) {
                              return DataRow(cells: [
                                DataCell(_SessionTableText(
                                  session.academicSessionId,
                                  width: 128,
                                  bold: true,
                                )),
                                DataCell(_SessionTableText(
                                  session.name,
                                  width: 150,
                                )),
                                DataCell(_SessionTableText(
                                  session.startDate ?? '-',
                                  width: 96,
                                )),
                                DataCell(_SessionTableText(
                                  session.endDate ?? '-',
                                  width: 96,
                                )),
                                DataCell(
                                  StatusChip(
                                    _academicSessionStatusLabel(
                                      session.status,
                                    ),
                                  ),
                                ),
                                DataCell(
                                    Text(session.isActive ? 'Ya' : 'Tidak')),
                                DataCell(SizedBox(
                                  width: 96,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        tooltip: 'Edit Sesi',
                                        visualDensity: VisualDensity.compact,
                                        constraints: const BoxConstraints(
                                          minWidth: 36,
                                          minHeight: 36,
                                        ),
                                        onPressed: () async {
                                          final saved =
                                              await _showAcademicSessionForm(
                                            context,
                                            state,
                                            session: session,
                                          );
                                          if (saved && context.mounted) {
                                            setDialogState(() {});
                                          }
                                        },
                                        icon: const Icon(Icons.edit_outlined),
                                      ),
                                      IconButton(
                                        tooltip: 'Arkibkan Sesi',
                                        visualDensity: VisualDensity.compact,
                                        constraints: const BoxConstraints(
                                          minWidth: 36,
                                          minHeight: 36,
                                        ),
                                        onPressed: session.status == 'archived'
                                            ? null
                                            : () async {
                                                final archived =
                                                    await _confirmArchiveSession(
                                                  context,
                                                  state,
                                                  session,
                                                );
                                                if (archived &&
                                                    context.mounted) {
                                                  setDialogState(() {});
                                                }
                                              },
                                        icon:
                                            const Icon(Icons.archive_outlined),
                                      ),
                                    ],
                                  ),
                                )),
                              ]);
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
            ),
            actions: [
              SizedBox(
                width: dialogWidth.toDouble(),
                child: Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () async {
                        final saved =
                            await _showAcademicSessionForm(context, state);
                        if (saved && context.mounted) setDialogState(() {});
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Tambah Sesi'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Tutup'),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      );
    },
  );
}

Future<bool> _showAcademicSessionForm(
  BuildContext context,
  AppState state, {
  AcademicSession? session,
}) async {
  if (!state.canManageAcademicSessions) return false;
  final isEdit = session != null;
  final idCtrl = TextEditingController(text: session?.academicSessionId ?? '');
  final nameCtrl = TextEditingController(text: session?.name ?? '');
  final startCtrl = TextEditingController(text: session?.startDate ?? '');
  final endCtrl = TextEditingController(text: session?.endDate ?? '');
  var status = session?.status ?? 'upcoming';
  var isActive = session?.isActive ?? status != 'archived';
  String? error;

  final saved = await showDialog<bool>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) {
        void syncStatus(String value) {
          setDialogState(() {
            status = value;
            if (status == 'archived') isActive = false;
          });
        }

        return AlertDialog(
          title: Text(isEdit ? 'Edit Sesi Akademik' : 'Tambah Sesi'),
          content: SizedBox(
            width: _dialogWidth(context, maxWidth: 520),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: idCtrl,
                    enabled: !isEdit,
                    decoration: const InputDecoration(
                      labelText: 'Kod Sesi',
                      hintText: 'JUL_DEC_2026',
                    ),
                  ),
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nama Sesi',
                      hintText: 'Jul-Dec 2026',
                    ),
                  ),
                  TextField(
                    controller: startCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Tarikh Mula',
                      hintText: '2026-07-01',
                    ),
                  ),
                  TextField(
                    controller: endCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Tarikh Tamat',
                      hintText: '2026-12-31',
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: status,
                    decoration: const InputDecoration(labelText: 'Status'),
                    items: const [
                      DropdownMenuItem(value: 'active', child: Text('Aktif')),
                      DropdownMenuItem(
                          value: 'upcoming', child: Text('Akan Datang')),
                      DropdownMenuItem(value: 'archived', child: Text('Arkib')),
                    ],
                    onChanged: (value) {
                      if (value != null) syncStatus(value);
                    },
                  ),
                  CheckboxListTile(
                    value: isActive,
                    onChanged: status == 'archived'
                        ? null
                        : (value) => setDialogState(
                              () => isActive = value ?? isActive,
                            ),
                    title: const Text('Aktif untuk pilihan jadual'),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                  if (error != null)
                    Text(
                      error!,
                      style: const TextStyle(color: Color(0xffb91c1c)),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () async {
                final validation = _validateAcademicSessionForm(
                  state,
                  idCtrl.text,
                  nameCtrl.text,
                  startCtrl.text,
                  endCtrl.text,
                  status,
                  isEdit: isEdit,
                );
                if (validation != null) {
                  setDialogState(() => error = validation);
                  return;
                }
                final cleanStatus = status.trim();
                final savedSession = AcademicSession(
                  academicSessionId: isEdit
                      ? session.academicSessionId
                      : idCtrl.text.trim().toUpperCase(),
                  name: nameCtrl.text.trim(),
                  startDate: startCtrl.text.trim(),
                  endDate: endCtrl.text.trim(),
                  status: cleanStatus,
                  isActive: cleanStatus == 'archived' ? false : isActive,
                  createdAt: session?.createdAt,
                  updatedAt: session?.updatedAt,
                );
                final navigator = Navigator.of(context);
                if (isEdit) {
                  await state.updateAcademicSessionRecord(savedSession);
                } else {
                  await state.createAcademicSession(savedSession);
                }
                navigator.pop(true);
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    ),
  );

  idCtrl.dispose();
  nameCtrl.dispose();
  startCtrl.dispose();
  endCtrl.dispose();
  return saved ?? false;
}

String? _validateAcademicSessionForm(
  AppState state,
  String id,
  String name,
  String startDate,
  String endDate,
  String status, {
  required bool isEdit,
}) {
  final cleanId = id.trim().toUpperCase();
  if (cleanId.isEmpty) return 'Kod sesi diperlukan.';
  if (!RegExp(r'^[A-Z0-9_]+$').hasMatch(cleanId)) {
    return 'Kod sesi mesti huruf besar/nombor/underscore tanpa ruang atau slash.';
  }
  if (!isEdit &&
      state.academicSessions.any((item) => item.academicSessionId == cleanId)) {
    return 'Kod sesi telah wujud.';
  }
  if (name.trim().isEmpty) return 'Nama sesi diperlukan.';
  final start = DateTime.tryParse(startDate.trim());
  final end = DateTime.tryParse(endDate.trim());
  if (start == null) return 'Tarikh mula mesti format YYYY-MM-DD.';
  if (end == null) return 'Tarikh tamat mesti format YYYY-MM-DD.';
  if (!start.isBefore(end)) return 'Tarikh mula mesti sebelum tarikh tamat.';
  if (!{'active', 'upcoming', 'archived'}.contains(status)) {
    return 'Status tidak sah.';
  }
  return null;
}

Future<bool> _confirmArchiveSession(
  BuildContext context,
  AppState state,
  AcademicSession session,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Arkibkan Sesi Akademik?'),
      content: const Text(
        'Sesi ini tidak akan dipadam, tetapi tidak akan dipilih untuk muat naik jadual baharu.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Arkibkan'),
        ),
      ],
    ),
  );
  if (confirmed != true) return false;
  await state.archiveAcademicSession(session.academicSessionId);
  return true;
}

String _academicSessionStatusLabel(String status) {
  return switch (status.toLowerCase()) {
    'active' => 'Aktif',
    'upcoming' => 'Akan Datang',
    'archived' => 'Diarkibkan',
    _ => status,
  };
}

double _dialogWidth(BuildContext context, {required double maxWidth}) {
  return (MediaQuery.sizeOf(context).width * 0.9).clamp(320.0, maxWidth);
}

class _SessionTableText extends StatelessWidget {
  const _SessionTableText(
    this.value, {
    required this.width,
    this.bold = false,
  });

  final String value;
  final double width;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: value,
      child: SizedBox(
        width: width,
        child: Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontWeight: bold ? FontWeight.w800 : null),
        ),
      ),
    );
  }
}
