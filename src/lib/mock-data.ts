export type Role = "admin" | "lecturer" | "staff";

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
  status: "New" | "Under Review" | "Action Taken" | "Resolved" | "Escalated";
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

export const PROGRAMS = [
  "Electrical Installation",
  "Automotive Technology",
  "Welding Technology",
  "Mechanical Maintenance",
  "Air Conditioning Technology",
  "Computer System Technology",
];

export const SECTIONS = ["ELI-1A", "ELI-1B", "AUTO-2A", "WELD-1A", "MECH-2B", "AC-1C"];

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
  { code: "WT101", name: "Welding Practical", program: "Welding Technology" },
  { code: "MM201", name: "Mechanical Maintenance", program: "Mechanical Maintenance" },
  { code: "AC101", name: "Air Conditioning System", program: "Air Conditioning Technology" },
];

export const LECTURERS: Lecturer[] = [
  { id: "L001", name: "Encik Ahmad bin Ismail", email: "ahmad@tvetmara.edu.my", department: "Electrical", subjects: ["EE101", "EE103"] },
  { id: "L002", name: "Puan Siti Nurhaliza", email: "siti@tvetmara.edu.my", department: "Electrical", subjects: ["EE102", "EE104"] },
  { id: "L003", name: "Encik Razak bin Hamid", email: "razak@tvetmara.edu.my", department: "Automotive", subjects: ["AT201"] },
  { id: "L004", name: "Encik Faizal bin Omar", email: "faizal@tvetmara.edu.my", department: "Welding", subjects: ["WT101"] },
  { id: "L005", name: "Puan Norazlin binti Hassan", email: "norazlin@tvetmara.edu.my", department: "Mechanical", subjects: ["MM201"] },
  { id: "L006", name: "Encik Khairul bin Anuar", email: "khairul@tvetmara.edu.my", department: "Air Conditioning", subjects: ["AC101"] },
  { id: "L007", name: "Puan Zarina binti Yusof", email: "zarina@tvetmara.edu.my", department: "Electrical", subjects: ["EE101", "EE104"] },
  { id: "L008", name: "Encik Hafiz bin Ramli", email: "hafiz@tvetmara.edu.my", department: "Computer", subjects: ["EE102"] },
];

const FIRST = ["Ahmad", "Muhammad", "Aiman", "Hafiz", "Iman", "Zaki", "Faris", "Danial", "Amin", "Syafiq", "Rizal", "Adam", "Haziq", "Irfan", "Naim", "Nurul", "Aishah", "Farah", "Hana", "Sarah", "Aina", "Liyana", "Diana", "Aliya", "Maisarah"];
const LAST = ["Ismail", "Hassan", "Rahman", "Yusof", "Omar", "Ali", "Karim", "Hashim", "Razak", "Aziz", "Othman", "Ibrahim", "Bakar", "Zainal", "Salleh"];

function rand<T>(arr: T[], i: number): T { return arr[i % arr.length]; }

export const STUDENTS: Student[] = Array.from({ length: 42 }, (_, i) => {
  const first = rand(FIRST, i * 3 + 1);
  const last = rand(LAST, i * 5 + 2);
  const isFemale = ["Nurul", "Aishah", "Farah", "Hana", "Sarah", "Aina", "Liyana", "Diana", "Aliya", "Maisarah"].includes(first);
  const fullName = isFemale ? `${first} binti ${last}` : `${first} bin ${last}`;
  const sectionIdx = i % SECTIONS.length;
  const section = SECTIONS[sectionIdx];
  const programMap: Record<string, string> = {
    "ELI-1A": "Electrical Installation",
    "ELI-1B": "Electrical Installation",
    "AUTO-2A": "Automotive Technology",
    "WELD-1A": "Welding Technology",
    "MECH-2B": "Mechanical Maintenance",
    "AC-1C": "Air Conditioning Technology",
  };
  const att = 60 + ((i * 7) % 40);
  return {
    id: `S${(2024000 + i + 1).toString()}`,
    name: fullName,
    ic: `0${2 + (i % 7)}${(1000000000 + i * 12345).toString().slice(0, 10)}`,
    email: `${first.toLowerCase()}${i}@student.tvetmara.edu.my`,
    phone: `01${(i % 9) + 1}-${(1000000 + i * 7777).toString().slice(0, 7)}`,
    program: programMap[section],
    course: `Diploma in ${programMap[section]}`,
    semester: ((i % 4) + 1),
    section,
    status: "Active",
    attendance: att,
  };
});

export const USERS: User[] = [
  { id: "U001", name: "Admin TVETMARA", email: "admin@tvetmara.edu.my", role: "admin", department: "Administration", status: "Active", lastLogin: "2026-04-29 08:12" },
  { id: "L001", name: "Encik Ahmad bin Ismail", email: "lecturer@tvetmara.edu.my", role: "lecturer", department: "Electrical", status: "Active", lastLogin: "2026-04-29 07:45" },
  { id: "U003", name: "Puan Aminah binti Yahya", email: "academic@tvetmara.edu.my", role: "staff", department: "Academic", status: "Active", lastLogin: "2026-04-28 16:20" },
  { id: "U004", name: "Puan Siti Nurhaliza", email: "siti@tvetmara.edu.my", role: "lecturer", department: "Electrical", status: "Active", lastLogin: "2026-04-29 08:00" },
  { id: "U005", name: "Encik Razak bin Hamid", email: "razak@tvetmara.edu.my", role: "lecturer", department: "Automotive", status: "Active", lastLogin: "2026-04-28 14:00" },
  { id: "U006", name: "Puan Faridah binti Latif", email: "faridah@tvetmara.edu.my", role: "staff", department: "Academic", status: "Inactive", lastLogin: "2026-04-20 10:30" },
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
  const slots: TimetableSlot[] = [];
  let id = 1;
  SECTIONS.forEach((section, sIdx) => {
    DAYS.forEach((day, dIdx) => {
      const slotCount = ((sIdx + dIdx) % 2) + 1;
      for (let k = 0; k < slotCount; k++) {
        const subj = SUBJECTS[(sIdx + dIdx + k) % SUBJECTS.length];
        const lect = LECTURERS[(sIdx + dIdx + k) % LECTURERS.length];
        const [start, end] = TIME_SLOTS[(dIdx + k) % TIME_SLOTS.length];
        const room = ROOMS[(sIdx + k) % ROOMS.length];
        const date = dateForDay(day);
        const today = "2026-04-29";
        let status: TimetableSlot["status"] = "Upcoming";
        if (date < today) status = Math.random() > 0.2 ? "Attendance Completed" : "Attendance Not Taken";
        else if (date === today) {
          if (start < "12:00") status = "Attendance Completed";
          else if (start < "14:00") status = "Ongoing";
          else status = "Attendance Not Taken";
        }
        slots.push({
          id: `T${(id++).toString().padStart(3, "0")}`,
          session: "2025/2026",
          semester: 2,
          program: STUDENTS.find((s) => s.section === section)?.program || "",
          section,
          subjectCode: subj.code,
          subjectName: subj.name,
          lecturerId: lect.id,
          lecturerName: lect.name,
          day,
          date,
          startTime: start,
          endTime: end,
          room,
          classType: k % 2 === 0 ? "Theory" : "Practical",
          weekRange: "Week 1-18",
          slotType: "Normal Class",
          status,
        });
      }
    });
  });
  return slots;
})();

export const DISCIPLINE_REPORTS: DisciplineReport[] = [
  {
    id: "D001",
    studentId: STUDENTS[3].id,
    studentName: STUDENTS[3].name,
    section: STUDENTS[3].section,
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
    studentId: STUDENTS[8].id,
    studentName: STUDENTS[8].name,
    section: STUDENTS[8].section,
    subject: "Welding Practical",
    lecturer: "Encik Faizal bin Omar",
    date: "2026-04-25",
    issueType: "Late to Class",
    severity: "Low",
    description: "Late for 3 consecutive practical sessions.",
    followUp: false,
    status: "New",
  },
  {
    id: "D003",
    studentId: STUDENTS[12].id,
    studentName: STUDENTS[12].name,
    section: STUDENTS[12].section,
    subject: "Automotive Service Practice",
    lecturer: "Encik Razak bin Hamid",
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