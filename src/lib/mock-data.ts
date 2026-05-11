export type Role = "admin" | "lecturer";

export interface User {
  id: string;
  name: string;
  email: string;
  role: Role;
  department?: string;
  status: "Active" | "Inactive";
  lastLogin: string;
}

export interface Student {
  id: string;
  name: string;
  ic: string;
  email: string;
  phone: string;
  program: string;
  course: string;
  semester: number;
  section: string;
  status: "Active" | "Inactive";
  attendance: number;
}

export interface Lecturer {
  id: string;
  name: string;
  email: string;
  department: string;
  subjects: string[];
}

export interface Subject {
  code: string;
  name: string;
  program: string;
}

export interface TimetableSlot {
  id: string;
  session: string;
  semester: number;
  program: string;
  section: string;
  subjectCode: string;
  subjectName: string;
  lecturerId: string;
  lecturerName: string;
  day: string;
  date: string; // ISO
  startTime: string;
  endTime: string;
  room: string;
  capacity?: number;
  enrolled?: number;
  classType: "Theory" | "Practical";
  weekRange: string;
  slotType: "Normal Class" | "Replacement Class";
  status:
    | "Upcoming"
    | "Ongoing"
    | "Attendance Not Taken"
    | "Attendance Completed"
    | "Attendance Pending"
    | "Cancelled"
    | "Rescheduled";
}

export type AttendanceStatus = "Present" | "Absent" | "MC" | "CK" | "Late";

export interface AttendanceRecord {
  slotId: string;
  studentId: string;
  status: AttendanceStatus;
  checkIn: string;
  remarks: string;
}

export interface DisciplineReport {
  id: string;
  studentId: string;
  studentName: string;
  section: string;
  subject: string;
  lecturer: string;
  date: string;
  issueType: string;
  severity: "Low" | "Medium" | "High";
  description: string;
  followUp: boolean;
  status: "New" | "Under Review" | "Action Taken" | "Resolved" | "Escalated" | "Approved" | "Rejected";
}

export interface BookingRequest {
  id: string;
  lecturerId: string;
  lecturerName: string;
  subject: string;
  section: string;
  originalDate: string;
  originalTime: string;
  replacementDate: string;
  replacementStart: string;
  replacementEnd: string;
  room: string;
  reason: string;
  remarks: string;
  status: "Pending" | "Approved" | "Rejected" | "Cancelled" | "Completed";
}

export const PROGRAMS = ["Electrical Installation", "Automotive Technology", "Computer System Technology"];

export const SECTIONS = ["ELI-1A", "ELI-1B", "ELI-1C", "AUTO-2A", "AUTO-2B", "AUTO-2C", "CST-1A", "CST-1B", "CST-1C"];

export const ROOMS = [
  "Lab Elektrik 1",
  "Lab Elektrik 2",
  "Bengkel Automotif",
  "Bengkel Kimpalan",
  "Makmal Komputer",
  "Lecture Room A",
  "Lecture Room B",
];

export const SUBJECTS: Subject[] = [
  { code: "EE101", name: "Electrical Installation Theory", program: "Electrical Installation" },
  { code: "EE102", name: "Electrical Installation Practice", program: "Electrical Installation" },
  { code: "EE103", name: "Electrical Supply Act and Regulations", program: "Electrical Installation" },
  { code: "EE104", name: "Electrical Motor Control", program: "Electrical Installation" },
  { code: "AT201", name: "Automotive Service Practice", program: "Automotive Technology" },
  { code: "AT202", name: "Vehicle Electrical System", program: "Automotive Technology" },
  { code: "CS101", name: "Computer Hardware Maintenance", program: "Computer System Technology" },
  { code: "CS102", name: "Network Fundamentals", program: "Computer System Technology" },
];

export const LECTURERS: Lecturer[] = [
  { id: "L001", name: "Encik Ahmad bin Ismail", email: "ahmad@tvetmara.edu.my", department: "Electrical", subjects: ["EE101", "EE103"] },
  { id: "L002", name: "Puan Siti Nurhaliza", email: "siti@tvetmara.edu.my", department: "Electrical", subjects: ["EE102", "EE104"] },
  { id: "L003", name: "Encik Razak bin Hamid", email: "razak@tvetmara.edu.my", department: "Automotive", subjects: ["AT201", "AT202"] },
  { id: "L004", name: "Encik Faizal bin Omar", email: "faizal@tvetmara.edu.my", department: "Automotive", subjects: ["AT201", "AT202"] },
  { id: "L005", name: "Puan Norazlin binti Hassan", email: "norazlin@tvetmara.edu.my", department: "Computer", subjects: ["CS101"] },
  { id: "L006", name: "Encik Khairul bin Anuar", email: "khairul@tvetmara.edu.my", department: "Computer", subjects: ["CS102"] },
  { id: "L007", name: "Puan Zarina binti Yusof", email: "zarina@tvetmara.edu.my", department: "Computer", subjects: ["CS101", "CS102"] },
  { id: "L008", name: "Encik Hafiz bin Ramli", email: "hafiz@tvetmara.edu.my", department: "Computer", subjects: ["CS101", "CS102"] },
];

const FIRST = ["Ahmad", "Muhammad", "Aiman", "Hafiz", "Iman", "Zaki", "Faris", "Danial", "Amin", "Syafiq", "Rizal", "Adam", "Haziq", "Irfan", "Naim", "Nurul", "Aishah", "Farah", "Hana", "Sarah", "Aina", "Liyana", "Diana", "Aliya", "Maisarah"];
const LAST = ["Ismail", "Hassan", "Rahman", "Yusof", "Omar", "Ali", "Karim", "Hashim", "Razak", "Aziz", "Othman", "Ibrahim", "Bakar", "Zainal", "Salleh"];

function rand<T>(arr: T[], i: number): T { return arr[i % arr.length]; }

const CLASS_BREAKDOWN = [
  { section: "ELI-1A", program: "Electrical Installation", count: 34 },
  { section: "ELI-1B", program: "Electrical Installation", count: 33 },
  { section: "ELI-1C", program: "Electrical Installation", count: 33 },
  { section: "AUTO-2A", program: "Automotive Technology", count: 34 },
  { section: "AUTO-2B", program: "Automotive Technology", count: 33 },
  { section: "AUTO-2C", program: "Automotive Technology", count: 33 },
  { section: "CST-1A", program: "Computer System Technology", count: 34 },
  { section: "CST-1B", program: "Computer System Technology", count: 33 },
  { section: "CST-1C", program: "Computer System Technology", count: 33 },
];

export const STUDENTS: Student[] = CLASS_BREAKDOWN.flatMap((klass, classIndex) =>
  Array.from({ length: klass.count }, (_, localIndex) => {
    const i = CLASS_BREAKDOWN.slice(0, classIndex).reduce((sum, c) => sum + c.count, 0) + localIndex;
    const first = rand(FIRST, i * 3 + 1);
    const last = rand(LAST, i * 5 + 2);
    const isFemale = ["Nurul", "Aishah", "Farah", "Hana", "Sarah", "Aina", "Liyana", "Diana", "Aliya", "Maisarah"].includes(first);
    const fullName = isFemale ? `${first} binti ${last}` : `${first} bin ${last}`;
    const att = i % 12 === 0 ? 62 + (i % 14) : 82 + ((i * 5) % 18);
    return {
      id: `S${(2026000 + i + 1).toString()}`,
      name: fullName,
      ic: `0${2 + (i % 7)}${(1000000000 + i * 12345).toString().slice(0, 10)}`,
      email: `${first.toLowerCase()}${i + 1}@student.tvetmara.edu.my`,
      phone: `01${(i % 9) + 1}-${(1000000 + i * 7777).toString().slice(0, 7)}`,
      program: klass.program,
      course: `Diploma in ${klass.program}`,
      semester: klass.section.startsWith("AUTO") ? 2 : 1,
      section: klass.section,
      status: "Active",
      attendance: att,
    };
  }),
);

export const USERS: User[] = [
  { id: "U001", name: "Admin TVETMARA", email: "admin@tvetmara.edu.my", role: "admin", department: "Administration", status: "Active", lastLogin: "2026-04-29 08:12" },
  { id: "L001", name: "Encik Ahmad bin Ismail", email: "lecturer@tvetmara.edu.my", role: "lecturer", department: "Electrical", status: "Active", lastLogin: "2026-04-29 07:45" },
  { id: "L002", name: "Puan Siti Nurhaliza", email: "siti@tvetmara.edu.my", role: "lecturer", department: "Electrical", status: "Active", lastLogin: "2026-04-29 08:00" },
  { id: "L003", name: "Encik Razak bin Hamid", email: "razak@tvetmara.edu.my", role: "lecturer", department: "Automotive", status: "Active", lastLogin: "2026-04-28 14:00" },
  { id: "L004", name: "Encik Faizal bin Omar", email: "faizal@tvetmara.edu.my", role: "lecturer", department: "Automotive", status: "Active", lastLogin: "2026-04-28 13:35" },
  { id: "L007", name: "Puan Zarina binti Yusof", email: "zarina@tvetmara.edu.my", role: "lecturer", department: "Computer", status: "Active", lastLogin: "2026-04-28 10:20" },
  { id: "L008", name: "Encik Hafiz bin Ramli", email: "hafiz@tvetmara.edu.my", role: "lecturer", department: "Computer", status: "Active", lastLogin: "2026-04-28 09:10" },
  { id: "U007", name: "Encik Hafiz bin Omar", email: "hafiz.admin@tvetmara.edu.my", role: "admin", department: "Administration", status: "Active", lastLogin: "2026-04-28 09:10" },
];

const DAYS = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"];

function dateForDay(dayName: string): string {
  // produce a date this week for the given day; today is Wed Apr 29 2026
  const today = new Date("2026-04-29");
  const dow = today.getDay(); // Wed = 3
  const targetDow = DAYS.indexOf(dayName) + 1; // Mon=1
  const diff = targetDow - dow;
  const d = new Date(today);
  d.setDate(today.getDate() + diff);
  return d.toISOString().slice(0, 10);
}

const TIME_SLOTS = [
  ["08:00", "10:00"],
  ["10:15", "12:15"],
  ["13:30", "15:30"],
  ["15:45", "17:45"],
];

export const TIMETABLE: TimetableSlot[] = (() => {
  const offerings = [
    ["ELI-1A", "EE101", "L001", 0, 0],
    ["ELI-1B", "EE101", "L001", 1, 1],
    ["ELI-1C", "EE103", "L001", 2, 2],
    ["ELI-1A", "EE102", "L002", 3, 1],
    ["ELI-1B", "EE104", "L002", 4, 2],
    ["ELI-1C", "EE102", "L002", 0, 3],
    ["AUTO-2A", "AT201", "L003", 1, 0],
    ["AUTO-2B", "AT201", "L003", 2, 1],
    ["AUTO-2C", "AT202", "L003", 3, 2],
    ["AUTO-2A", "AT202", "L004", 4, 0],
    ["AUTO-2B", "AT202", "L004", 0, 1],
    ["AUTO-2C", "AT201", "L004", 1, 2],
    ["CST-1A", "CS101", "L008", 2, 0],
    ["CST-1B", "CS101", "L008", 3, 1],
    ["CST-1C", "CS102", "L008", 4, 2],
    ["CST-1A", "CS102", "L007", 0, 2],
    ["CST-1B", "CS102", "L007", 1, 3],
    ["CST-1C", "CS101", "L007", 2, 3],
    ["ELI-1A", "EE103", "L001", 3, 3],
    ["ELI-1A", "EE104", "L002", 2, 0],
    ["AUTO-2A", "AT202", "L003", 4, 3],
    ["AUTO-2B", "AT201", "L004", 2, 3],
    ["CST-1A", "CS102", "L008", 1, 2],
    ["CST-1B", "CS101", "L007", 3, 0],
  ] as const;

  return offerings.map(([section, subjectCode, lecturerId, dayIndex, timeIndex], index) => {
    const subj = SUBJECTS.find((s) => s.code === subjectCode)!;
    const lect = LECTURERS.find((l) => l.id === lecturerId)!;
    const day = DAYS[dayIndex];
    const [start, end] = TIME_SLOTS[timeIndex];
    const enrolled = STUDENTS.filter((s) => s.section === section).length;
    const capacity = enrolled + (index % 3 === 0 ? 2 : index % 3 === 1 ? 4 : 5);
    const status: TimetableSlot["status"] = index % 5 === 0 ? "Attendance Not Taken" : index % 4 === 0 ? "Ongoing" : "Upcoming";
    return {
      id: `T${(index + 1).toString().padStart(3, "0")}`,
      session: "2025/2026",
      semester: section.startsWith("AUTO") ? 2 : 1,
      program: subj.program,
      section,
      subjectCode: subj.code,
      subjectName: subj.name,
      lecturerId: lect.id,
      lecturerName: lect.name,
      day,
      date: dateForDay(day),
      startTime: start,
      endTime: end,
      room: ROOMS[index % ROOMS.length],
      enrolled,
      capacity,
      classType: subjectCode.includes("102") || subjectCode.includes("201") ? "Practical" : "Theory",
      weekRange: "Week 1-18",
      slotType: "Normal Class",
      status,
    };
  });
})();

const studentInSection = (section: string, offset = 0) => STUDENTS.filter((student) => student.section === section)[offset];

export const DISCIPLINE_REPORTS: DisciplineReport[] = [
  {
    id: "D001",
    studentId: studentInSection("ELI-1A", 3).id,
    studentName: studentInSection("ELI-1A", 3).name,
    section: "ELI-1A",
    subject: "Electrical Installation Theory",
    lecturer: "Encik Ahmad bin Ismail",
    date: "2026-04-22",
    issueType: "Frequent Absence",
    severity: "High",
    description: "Student absent for 5 consecutive sessions without notice.",
    followUp: true,
    status: "Under Review",
  },
  {
    id: "D002",
    studentId: studentInSection("AUTO-2A", 4).id,
    studentName: studentInSection("AUTO-2A", 4).name,
    section: "AUTO-2A",
    subject: "Automotive Service Practice",
    lecturer: "Encik Razak bin Hamid",
    date: "2026-04-25",
    issueType: "Late to Class",
    severity: "Low",
    description: "Late for 3 consecutive practical sessions.",
    followUp: false,
    status: "New",
  },
  {
    id: "D003",
    studentId: studentInSection("CST-1A", 2).id,
    studentName: studentInSection("CST-1A", 2).name,
    section: "CST-1A",
    subject: "Computer Hardware Maintenance",
    lecturer: "Encik Hafiz bin Ramli",
    date: "2026-04-18",
    issueType: "Misconduct",
    severity: "Medium",
    description: "Disruptive behaviour during workshop session.",
    followUp: true,
    status: "Action Taken",
  },
];

export const BOOKINGS: BookingRequest[] = [
  {
    id: "B001",
    lecturerId: "L001",
    lecturerName: "Encik Ahmad bin Ismail",
    subject: "Electrical Installation Theory",
    section: "ELI-1A",
    originalDate: "2026-04-22",
    originalTime: "08:00 - 10:00",
    replacementDate: "2026-05-03",
    replacementStart: "14:00",
    replacementEnd: "16:00",
    room: "Lecture Room A",
    reason: "Public holiday",
    remarks: "Replacement for Hari Raya holiday.",
    status: "Approved",
  },
  {
    id: "B002",
    lecturerId: "L003",
    lecturerName: "Encik Razak bin Hamid",
    subject: "Automotive Service Practice",
    section: "AUTO-2A",
    originalDate: "2026-04-28",
    originalTime: "10:15 - 12:15",
    replacementDate: "2026-05-05",
    replacementStart: "10:15",
    replacementEnd: "12:15",
    room: "Bengkel Automotif",
    reason: "Lecturer unavailable",
    remarks: "Lecturer attending training.",
    status: "Pending",
  },
  {
    id: "B003",
    lecturerId: "L001",
    lecturerName: "Encik Ahmad bin Ismail",
    subject: "Electrical Supply Act and Regulations",
    section: "ELI-1C",
    originalDate: "2026-04-29",
    originalTime: "13:30 - 15:30",
    replacementDate: "2026-05-06",
    replacementStart: "10:15",
    replacementEnd: "12:15",
    room: "Lab Elektrik 1",
    reason: "Training / Meeting",
    remarks: "Lecturer attending TVET assessment briefing.",
    status: "Pending",
  },
];

export function generateAttendanceForSlot(slotId: string): AttendanceRecord[] {
  const slot = TIMETABLE.find((t) => t.id === slotId);
  if (!slot) return [];
  const students = STUDENTS.filter((s) => s.section === slot.section);
  return students.map((s, i) => {
    const r = (i + slotId.length) % 10;
    let status: AttendanceStatus = "Present";
    if (r === 0) status = "Absent";
    else if (r === 1) status = "Late";
    else if (r === 2) status = "MC";
    else if (r === 3) status = "CK";
    return {
      slotId,
      studentId: s.id,
      status,
      checkIn: status === "Absent" || status === "MC" || status === "CK" ? "—" : `${slot.startTime}`,
      remarks: status === "MC" ? "Medical certificate submitted" : status === "CK" ? "Approved leave" : status === "Late" ? "Late 15 minutes" : "",
    };
  });
}
