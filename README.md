# TVETMARA Student Attendance

TVETMARA Student Attendance Management System rebuilt with Flutter.

## Getting Started

```bash
flutter run -d chrome (run in terminal)
```

## Demo Data And Login Accounts

These accounts are for demo/development testing only. Do not rely on
`users.json` for login testing; Firebase Authentication plus Firestore
`users/{firebaseAuthUid}` is the source of truth.

In a debug build, open the login screen and click **Seed Demo Data (Debug
Only)**. Confirm the dialog to create demo Firebase Authentication accounts,
write matching Firestore user profiles, and seed related demo records. This
does not run automatically.

| Role | Email | Password | programId | departmentId | Expected menu access |
|---|---|---|---|---|---|
| pentadbir | admin@tvetmara.edu.my | admin123 | - | Pentadbiran | Dashboard, Tetapan Sistem, Daftar Akaun |
| ketua_jabatan | kj_elektrik@tvetmara.edu.my | password123 | - | elektrik | Dashboard, Jadual, Laporan, Laporan Disiplin, Rekod Pelajar |
| ketua_program with KJ | kp_ded@tvetmara.edu.my | password123 | DED | - | Dashboard, Laporan, Tempahan Bilik, Rekod Pelajar |
| ketua_program without KJ | kp_dgs@tvetmara.edu.my | password123 | DGS | - | Dashboard, Jadual, Laporan, Tempahan Bilik, Laporan Disiplin, Rekod Pelajar |
| pensyarah with KJ | pensyarah_ded@tvetmara.edu.my | password123 | DED | elektrik | Dashboard, Kehadiran, Tempahan Bilik, Laporan Disiplin |
| pensyarah without KJ | pensyarah_dgs@tvetmara.edu.my | password123 | DGS | Umum | Dashboard, Kehadiran, Tempahan Bilik, Laporan Disiplin |

