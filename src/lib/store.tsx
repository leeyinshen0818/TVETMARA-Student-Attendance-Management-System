import * as React from "react";
import {
  TIMETABLE,
  STUDENTS,
  LECTURERS,
  USERS,
  DISCIPLINE_REPORTS,
  BOOKINGS,
  generateAttendanceForSlot,
  type Role,
  type User,
  type TimetableSlot,
  type AttendanceRecord,
  type DisciplineReport,
  type BookingRequest,
  type Student,
  type Lecturer,
} from "./mock-data";

interface AppState {
  currentUser: User | null;
  login: (role: Role) => void;
  loginWithEmail: (email: string, password: string) => boolean;
  logout: () => void;
  users: User[];
  setUsers: React.Dispatch<React.SetStateAction<User[]>>;
  students: Student[];
  lecturers: Lecturer[];
  timetable: TimetableSlot[];
  setTimetable: React.Dispatch<React.SetStateAction<TimetableSlot[]>>;
  attendance: Record<string, AttendanceRecord[]>;
  saveAttendance: (slotId: string, records: AttendanceRecord[]) => void;
  disciplineReports: DisciplineReport[];
  addDiscipline: (r: DisciplineReport) => void;
  updateDiscipline: (id: string, patch: Partial<DisciplineReport>) => void;
  bookings: BookingRequest[];
  addBooking: (b: BookingRequest) => void;
  updateBooking: (id: string, patch: Partial<BookingRequest>) => void;
  settings: {
    threshold: number;
    mcAsPresent: boolean;
    ckAsPresent: boolean;
    editDeadline: string;
    qrWindow: number;
    emailTemplate: string;
    session: string;
    semester: number;
  };
  setSettings: React.Dispatch<React.SetStateAction<AppState["settings"]>>;
}

const Ctx = React.createContext<AppState | null>(null);

export function AppProvider({ children }: { children: React.ReactNode }) {
  const [currentUser, setCurrentUser] = React.useState<User | null>(null);
  const [users, setUsers] = React.useState<User[]>(USERS);
  const [timetable, setTimetable] = React.useState<TimetableSlot[]>(TIMETABLE);
  const [attendance, setAttendance] = React.useState<Record<string, AttendanceRecord[]>>(() => {
    const map: Record<string, AttendanceRecord[]> = {};
    TIMETABLE.filter((t) => t.status === "Attendance Completed").forEach((t) => {
      map[t.id] = generateAttendanceForSlot(t.id);
    });
    return map;
  });
  const [disciplineReports, setDiscipline] = React.useState<DisciplineReport[]>(DISCIPLINE_REPORTS);
  const [bookings, setBookings] = React.useState<BookingRequest[]>(BOOKINGS);
  const [settings, setSettings] = React.useState({
    threshold: 80,
    mcAsPresent: true,
    ckAsPresent: true,
    editDeadline: "24 hours",
    qrWindow: 15,
    emailTemplate: "Dear {student}, your attendance for {subject} is below the required percentage.",
    session: "2025/2026",
    semester: 2,
  });

  const login = (role: Role) => {
    const map: Record<Role, string> = {
      admin: "admin@tvetmara.edu.my",
      lecturer: "lecturer@tvetmara.edu.my",
      staff: "academic@tvetmara.edu.my",
    };
    const user = users.find((u) => u.email === map[role]) || users.find((u) => u.role === role) || users[0];
    setCurrentUser(user);
  };
  const loginWithEmail = (email: string, _password: string) => {
    const user = users.find((u) => u.email.toLowerCase() === email.toLowerCase());
    if (!user) return false;
    setCurrentUser(user);
    return true;
  };
  const logout = () => setCurrentUser(null);

  const saveAttendance = (slotId: string, records: AttendanceRecord[]) => {
    setAttendance((prev) => ({ ...prev, [slotId]: records }));
    setTimetable((prev) => prev.map((t) => (t.id === slotId ? { ...t, status: "Attendance Completed" } : t)));
  };

  const addDiscipline = (r: DisciplineReport) => setDiscipline((p) => [r, ...p]);
  const updateDiscipline = (id: string, patch: Partial<DisciplineReport>) =>
    setDiscipline((p) => p.map((d) => (d.id === id ? { ...d, ...patch } : d)));

  const addBooking = (b: BookingRequest) => setBookings((p) => [b, ...p]);
  const updateBooking = (id: string, patch: Partial<BookingRequest>) => {
    setBookings((p) => p.map((b) => (b.id === id ? { ...b, ...patch } : b)));
    if (patch.status === "Approved") {
      const booking = bookings.find((b) => b.id === id);
      if (booking) {
        const newSlot: TimetableSlot = {
          id: `T${Date.now()}`,
          session: settings.session,
          semester: settings.semester,
          program: timetable.find((t) => t.section === booking.section)?.program || "",
          section: booking.section,
          subjectCode: timetable.find((t) => t.subjectName === booking.subject)?.subjectCode || "REP",
          subjectName: booking.subject,
          lecturerId: booking.lecturerId,
          lecturerName: booking.lecturerName,
          day: new Date(booking.replacementDate).toLocaleDateString("en-US", { weekday: "long" }),
          date: booking.replacementDate,
          startTime: booking.replacementStart,
          endTime: booking.replacementEnd,
          room: booking.room,
          classType: "Theory",
          weekRange: "Replacement",
          slotType: "Replacement Class",
          status: "Upcoming",
        };
        setTimetable((prev) => [...prev, newSlot]);
      }
    }
  };

  return (
    <Ctx.Provider
      value={{
        currentUser,
        login,
        loginWithEmail,
        logout,
        users,
        setUsers,
        students: STUDENTS,
        lecturers: LECTURERS,
        timetable,
        setTimetable,
        attendance,
        saveAttendance,
        disciplineReports,
        addDiscipline,
        updateDiscipline,
        bookings,
        addBooking,
        updateBooking,
        settings,
        setSettings,
      }}
    >
      {children}
    </Ctx.Provider>
  );
}

export function useApp() {
  const c = React.useContext(Ctx);
  if (!c) throw new Error("useApp must be inside AppProvider");
  return c;
}