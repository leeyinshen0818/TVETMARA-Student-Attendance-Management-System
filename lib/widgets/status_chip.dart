import 'package:flutter/material.dart';

class StatusChip extends StatelessWidget {
  const StatusChip(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = switch (label) {
      'active' ||
      'Approved' ||
      'approved' ||
      'Action Taken' ||
      'Closed' ||
      'Completed' ||
      'completed' ||
      'Attendance Completed' ||
      'Present' ||
      'Active' ||
      'Safe' ||
      'Available' =>
        Colors.green,
      'inactive' ||
      'cancelled' ||
      'canceled' ||
      'Rejected' ||
      'rejected' ||
      'Cancelled' ||
      'Absent' ||
      'High' ||
      'Critical' ||
      'Unavailable' =>
        scheme.error,
      'pending' ||
      'Pending' ||
      'Reviewed' ||
      'Under Review' ||
      'Attendance Not Taken' ||
      'Ongoing' ||
      'Late' ||
      'Warning' =>
        Colors.orange,
      'MC' || 'CK' => Colors.blueGrey,
      'Replacement Class' || 'Kelas Ganti' => Colors.purple,
      _ => scheme.primary,
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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        border: Border.all(color: color.withValues(alpha: .22)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        displayLabel,
        style:
            TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
  }
}
