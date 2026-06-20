# TVETMARA Student Attendance Management System

A web-based system for managing student attendance, timetables, reports, room
bookings, and discipline records at TVETMARA.

## Live System

https://tvetmara-7e520.web.app

## Technology Stack

- **Flutter** — Responsive web application interface
- **Dart** — Application programming language
- **Firebase Authentication** — User login and account access
- **Cloud Firestore** — Stores users, students, attendance, timetables,
  bookings, and reports
- **Firebase Hosting** — Hosts the deployed web system
- **PDF and Excel Export** — Generates downloadable reports and timetable
  files

## Main Features

### Dashboard

- View a summary based on the signed-in user's role.
- See classes, attendance status, bookings, discipline reports, and items that
  require attention.
- Quickly open frequently used modules.

### Timetable Management

- Lecturers can view their assigned timetable.
- Heads of Department can manage official timetable records.
- Add or edit timetable slots.
- Import timetable data from a CSV file.
- Detect timetable conflicts.
- View timetables by list, week, room, lecturer, programme, or class.
- Export timetable information.

### Student Attendance

- Lecturers can select a class and record attendance.
- Mark students as Present, Late, Absent, MC, or CK.
- Submit completed attendance sessions.
- Review and correct previously submitted attendance with an edit reason.
- Keep an attendance edit history for reference.

### Student Records

- Heads of Department and Heads of Programme can view students within their
  assigned scope.
- Search and filter students by programme, class, semester, status, and
  attendance risk.
- View individual attendance summaries and discipline records.
- Identify students who require attention.

### Attendance Reports

- View weekly attendance reports.
- View combined reports for all weeks.
- Filter reports by programme, class, week, and attendance threshold.
- Identify students below 95%, 90%, 85%, or 80% attendance.
- Review eligibility for semester progression.
- Export reports as PDF.

### Room Booking

- Lecturers can request rooms for replacement classes.
- Check room availability and possible timetable conflicts.
- Track pending, approved, and rejected requests.
- Heads of Programme and Heads of Department can review requests within their
  assigned scope.

### Discipline Reports

- Lecturers can submit discipline reports for students in their classes.
- View the progress and history of submitted reports.
- Heads of Programme and Heads of Department can review reports, add notes,
  reject reports, or record follow-up actions.

### User Management

- Administrators can register staff accounts.
- View and manage system users.
- Review student and lecturer assignment information.
- Activate or update user profiles.

## Access by Role

### Administrator

- View the system-wide dashboard.
- Register and manage user accounts.
- Review users, students, and lecturer assignments.

### Head of Department

- Manage department timetables.
- View student records and attendance reports.
- Review room bookings and discipline reports for the department.

### Head of Programme

- View programme timetables.
- View programme student records and attendance reports.
- Review relevant room bookings and discipline reports.

### Lecturer

- View personal teaching timetable.
- Record and edit attendance.
- Request rooms for replacement classes.
- Submit and monitor discipline reports.

## Demo Accounts

| Role | Email | Password |
|---|---|---|
| Administrator | `admin@tvetmara.edu.my` | `admin123` |
| Head of Electrical Department | `kj_elektrik@tvetmara.edu.my` | `password123` |
| Head of DED Programme | `kp_ded@tvetmara.edu.my` | `password123` |
| Electrical Lecturer | `lecturer046@tvetmara.edu.my` | `password123` |
| DGS Lecturer | `lecturer001@tvetmara.edu.my` | `password123` |

> Demo accounts and displayed information are intended for prototype
> demonstration and testing.
