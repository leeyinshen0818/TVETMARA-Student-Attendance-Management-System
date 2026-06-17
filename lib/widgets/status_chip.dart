import 'package:flutter/material.dart';

import 'app_theme.dart';

class StatusChip extends StatelessWidget {
  const StatusChip(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final normalized = label.trim().toLowerCase();
    final color = switch (normalized) {
      'active' ||
      'approved' ||
      'action taken' ||
      'closed' ||
      'completed' ||
      'attendance completed' ||
      'present' ||
      'safe' ||
      'selamat' ||
      'aktif' ||
      'available' ||
      'tersedia' ||
      'rasmi' ||
      'diluluskan' ||
      'selesai' =>
        AppColors.success,
      'inactive' ||
      'cancelled' ||
      'canceled' ||
      'rejected' ||
      'absent' ||
      'high' ||
      'critical' ||
      'kritikal' ||
      'tidak aktif' ||
      'unavailable' ||
      'tidak tersedia' ||
      'konflik' ||
      'ditolak' ||
      'bawah 80%' =>
        AppColors.danger,
      'pending' ||
      'reviewed' ||
      'under review' ||
      'attendance not taken' ||
      'ongoing' ||
      'late' ||
      'warning' ||
      'amaran' ||
      'menunggu' ||
      'menunggu semakan' ||
      'draf' ||
      'bawah 95%' =>
        AppColors.warning,
      'bawah 90%' || 'bawah 85%' => const Color(0xffea580c),
      'mc' || 'ck' || 'tindakan diambil' || 'disemak' => AppColors.info,
      'replacement class' || 'kelas ganti' => AppColors.accent,
      'diarkibkan' || 'archived' => AppColors.muted,
      _ => AppColors.primary,
    };
    final displayLabel = switch (label) {
      'active' => 'Aktif',
      'Approved' => 'Diluluskan',
      'approved' => 'Diluluskan',
      'Action Taken' => 'Tindakan Diambil',
      'Closed' => 'Ditutup',
      'Completed' => 'Selesai',
      'completed' => 'Selesai',
      'Attendance Completed' => 'Kehadiran Selesai',
      'Present' => 'Hadir',
      'Active' => 'Aktif',
      'Safe' => 'Selamat',
      'Available' => 'Tersedia',
      'inactive' => 'Tidak Aktif',
      'cancelled' => 'Dibatalkan',
      'canceled' => 'Dibatalkan',
      'Rejected' => 'Ditolak',
      'rejected' => 'Ditolak',
      'Cancelled' => 'Dibatalkan',
      'Absent' => 'Tidak Hadir',
      'High' => 'Tinggi',
      'Critical' => 'Kritikal',
      'Unavailable' => 'Tidak Tersedia',
      'pending' => 'Menunggu',
      'Pending' => 'Menunggu',
      'Reviewed' => 'Disemak',
      'Under Review' => 'Dalam Semakan',
      'Attendance Not Taken' => 'Belum Diambil',
      'Attendance Pending' => 'Menunggu Kehadiran',
      'Ongoing' => 'Sedang Berlangsung',
      'Late' => 'Lewat',
      'Warning' => 'Amaran',
      'Replacement Class' => 'Kelas Ganti',
      'Kelas Ganti' => 'Kelas Ganti',
      'Kelas Biasa' => 'Kelas Biasa',
      'Upcoming' => 'Akan Datang',
      'Inactive' => 'Tidak Aktif',
      'Normal Class' => 'Kelas Biasa',
      _ => label,
    };

    final surfaceColor = switch (color) {
      AppColors.success => AppColors.successSurface,
      AppColors.danger => AppColors.dangerSurface,
      AppColors.warning => AppColors.warningSurface,
      AppColors.info => AppColors.infoSurface,
      AppColors.muted => const Color(0xffF1F5F9), // Slate 100
      _ => color.withValues(alpha: .12),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: surfaceColor,
        border: Border.all(color: color.withValues(alpha: .24)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        displayLabel,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
