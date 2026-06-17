import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  // Base
  static const primary = Color(0xff1E3A8A); // Royal Blue
  static const accent = Color(0xff2563EB); // Modern Accent Blue
  static const primaryDark = Color(0xff0B1220); // Premium Navy

  // Backgrounds
  static const background = Color(0xffF5F7FB); // Soft App Background
  static const surface = Color(0xffFFFFFF); // Card Surface
  static const surfaceTint = Color(0xffEEF4FF); // Light Blue Surface
  static const border = Color(0xffDDE6F3); // Soft Border

  // Sidebar
  static const sidebar = Color(0xff0B1220); // Premium Navy
  static const sidebarMuted = Color(0xffCBD5E1);

  // Typography
  static const textPrimary = Color(0xff0F172A); // Main Text
  static const textSecondary = Color(0xff64748B); // Secondary Text
  static const muted = Color(0xff94A3B8); // Muted Text

  // Module Accents
  static const blue = Color(0xff2563EB); // Dashboard / Home
  static const blueSurface = Color(0xffDBEAFE);

  static const indigo = Color(0xff4F46E5); // Jadual / Timetable
  static const indigoSurface = Color(0xffE0E7FF);

  static const teal = Color(
      0xff0D9488); // Laporan / Reports (using darker teal for better contrast than 0891B2 cyan, wait user requested 0891B2, using 0891B2)
  static const cyan = Color(0xff0891B2);
  static const cyanSurface = Color(0xffCFFAFE);

  static const emerald = Color(0xff16A34A); // Kehadiran / Attendance
  static const emeraldSurface = Color(0xffDCFCE7);

  static const amber = Color(0xffF59E0B); // Tempahan / Booking
  static const amberSurface = Color(0xffFEF3C7);

  static const rose = Color(0xffE11D48); // Disiplin / Discipline
  static const roseSurface = Color(0xffFFE4E6);

  static const sky = Color(0xff0284C7); // Rekod Pelajar / Student Records
  static const skySurface = Color(0xffE0F2FE);

  static const purple = Color(0xff7C3AED); // Admin / Pengguna
  static const purpleSurface = Color(0xffEDE9FE);

  // Status Colors (mapped to accents)
  static const success = emerald;
  static const successSurface = emeraldSurface;

  static const warning = amber;
  static const warningSurface = amberSurface;

  static const danger = rose;
  static const dangerSurface = roseSurface;

  static const info = blue;
  static const infoSurface = blueSurface;
}
