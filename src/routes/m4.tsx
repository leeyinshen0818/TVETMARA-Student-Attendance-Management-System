import * as React from "react";
import { createFileRoute } from "@tanstack/react-router";
import { toast } from "sonner";
import { FileSpreadsheet, RefreshCcw, Save, Trash2, Upload } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { PageHeader } from "@/components/page-header";
import { StatusBadge } from "@/components/status-badge";
import { useApp } from "@/lib/store";
import { LECTURERS, PROGRAMS, SECTIONS, SUBJECTS, type TimetableSlot } from "@/lib/mock-data";

export const Route = createFileRoute("/m4")({ component: M4 });

type Meeting = { day: string; startTime: string; endTime: string; venue: string; date: string };
type SheetRow = {
  no: number;
  code: string;
  courseName: string;
  section: string;
  program: string;
  capacity: number;
  meeting1: Meeting;
  meeting2: Meeting;
  lecturerId: string;
  lecturer: string;
  email: string;
  status: "Valid" | "Missing Data" | "Invalid Time" | "Clash";
};

const courseCodes: Record<string, string> = {
  "Electrical Installation": "ELI",
  "Automotive Technology": "AUTO",
  "Computer System Technology": "CST",
};

const dayDate: Record<string, string> = {
  MON: "2026-05-11",
  TUE: "2026-05-12",
  WED: "2026-05-13",
  THU: "2026-05-14",
  FRI: "2026-05-15",
};

const dayNames: Record<string, string> = {
  MON: "Monday",
  TUE: "Tuesday",
  WED: "Wednesday",
  THU: "Thursday",
  FRI: "Friday",
};

function makeMeeting(day: string, startTime: string, endTime: string, venue: string): Meeting {
  return { day, startTime, endTime, venue, date: dayDate[day] };
}

function sampleRows(course: string, semester: number): SheetRow[] {
  const sections = SECTIONS.filter((section) => section.startsWith(courseCodes[course]));
  const subjects = SUBJECTS.filter((subject) => subject.program === course);
  return subjects.slice(0, 3).flatMap((subject, subjectIndex) =>
    sections.map((section, sectionIndex) => {
      const lecturer = LECTURERS[(subjectIndex + sectionIndex) % LECTURERS.length];
      const meetingA = [
        makeMeeting("MON", "08:00", "10:00", "Lecture Room A"),
        makeMeeting("TUE", "10:15", "12:15", "Makmal Komputer"),
        makeMeeting("WED", "11:00", "13:00", "KejoRA Hall"),
      ][subjectIndex];
      const meetingB = [
        makeMeeting("THU", "10:00", "11:00", "BK4"),
        makeMeeting("THU", "08:00", "10:00", "N28A-MP2"),
        makeMeeting("FRI", "08:00", "10:00", "BK1"),
      ][sectionIndex % 3];
      return {
        no: subjectIndex * sections.length + sectionIndex + 1,
        code: subject.code,
        courseName: subject.name,
        section: section.replace(courseCodes[course] + "-", "").replace(/[A-Z]$/, (letter) => `-${letter}`),
        program: courseCodes[course],
        capacity: sectionIndex === 0 ? 40 : 35,
        meeting1: meetingA,
        meeting2: meetingB,
        lecturerId: lecturer.id,
        lecturer: lecturer.name,
        email: lecturer.email,
        status: "Valid",
      };
    }),
  );
}

function M4() {
  const { setTimetable } = useApp();
  const [course, setCourse] = React.useState(PROGRAMS[0]);
  const [semester, setSemester] = React.useState("2");
  const [fileName, setFileName] = React.useState<string | null>("Previous upload: timetable-sem2-electrical.xlsx");
  const [rows, setRows] = React.useState<SheetRow[]>([]);

  const sectionsForCourse = SECTIONS.filter((section) => section.startsWith(courseCodes[course]));
  const uploadedAt = rows.length ? "11 May 2026, 3:58 PM" : "29 April 2026, 8:10 AM";

  const loadFile = () => {
    setFileName(`timetable-${courseCodes[course].toLowerCase()}-sem${semester}-20252026.xlsx`);
    setRows(sampleRows(course, Number(semester)));
    toast.success("Timetable file loaded for review.");
  };

  const removeFile = () => {
    setFileName(null);
    setRows([]);
    toast("Uploaded file removed.");
  };

  const update = (no: number, patch: Partial<SheetRow>) => {
    setRows((current) => current.map((row) => (row.no === no ? validateRow({ ...row, ...patch }) : row)));
  };

  const save = () => {
    const validRows = rows.filter((row) => row.status === "Valid");
    const slots: TimetableSlot[] = validRows.flatMap((row) =>
      [row.meeting1, row.meeting2].map((meeting, index) => ({
        id: `UP${Date.now()}-${row.no}-${index}`,
        session: "2025/2026",
        semester: Number(semester),
        program: course,
        section: `${courseCodes[course]}-${row.section.replace("-", "")}`,
        subjectCode: row.code,
        subjectName: row.courseName,
        lecturerId: row.lecturerId,
        lecturerName: row.lecturer,
        day: dayNames[meeting.day],
        date: meeting.date,
        startTime: meeting.startTime,
        endTime: meeting.endTime,
        room: meeting.venue,
        enrolled: Math.max(0, row.capacity - (row.no % 5) - 1),
        capacity: row.capacity,
        classType: "Theory",
        weekRange: "Week 1-18",
        slotType: "Normal Class",
        status: "Upcoming",
      })),
    );

    if (!slots.length) {
      toast.error("No valid rows to save.");
      return;
    }

    setTimetable((current) => [...current, ...slots]);
    toast.success(`${slots.length} timetable slot(s) saved to Showing Timetable Slot.`);
  };

  return (
    <div className="space-y-5">
      <PageHeader
        title="M4: Upload Time Schedule"
        subtitle="Upload course timetable by semester using the official spreadsheet format."
      />

      <Card>
        <CardContent className="grid gap-4 p-4 lg:grid-cols-[1fr_340px]">
          <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
            <div>
              <Label className="text-xs">Course</Label>
              <Select value={course} onValueChange={(value) => { setCourse(value); setRows([]); }}>
                <SelectTrigger className="h-9 mt-1"><SelectValue /></SelectTrigger>
                <SelectContent>{PROGRAMS.map((item) => <SelectItem key={item} value={item}>{item}</SelectItem>)}</SelectContent>
              </Select>
            </div>
            <div>
              <Label className="text-xs">Semester</Label>
              <Select value={semester} onValueChange={(value) => { setSemester(value); setRows([]); }}>
                <SelectTrigger className="h-9 mt-1"><SelectValue /></SelectTrigger>
                <SelectContent>{[1, 2, 3, 4].map((item) => <SelectItem key={item} value={String(item)}>Semester {item}</SelectItem>)}</SelectContent>
              </Select>
            </div>
            <ReadOnly label="Sessions" value="2025/2026" />
            <ReadOnly label="Section" value={sectionsForCourse.join(", ")} />
          </div>

          <div className="rounded-md border bg-muted/30 p-3">
            <div className="flex items-center gap-2 text-sm font-semibold">
              <FileSpreadsheet className="h-4 w-4" /> Uploaded File
            </div>
            {fileName ? (
              <div className="mt-2 space-y-2 text-xs">
                <div className="font-medium">{fileName}</div>
                <div className="text-muted-foreground">Last uploaded: {uploadedAt}</div>
                <div className="flex gap-2">
                  <Button size="sm" variant="outline" className="h-7 text-xs" onClick={loadFile}><RefreshCcw className="h-3 w-3 mr-1" /> Reupload</Button>
                  <Button size="sm" variant="ghost" className="h-7 text-xs text-destructive" onClick={removeFile}><Trash2 className="h-3 w-3 mr-1" /> Remove</Button>
                </div>
              </div>
            ) : (
              <div className="mt-2 space-y-2 text-xs text-muted-foreground">
                <div>No timetable file uploaded for this course and semester.</div>
                <Button size="sm" className="h-7 text-xs" onClick={loadFile}><Upload className="h-3 w-3 mr-1" /> Upload File</Button>
              </div>
            )}
          </div>
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle className="text-base">Required Spreadsheet Format</CardTitle>
        </CardHeader>
        <CardContent className="grid gap-2 text-xs text-muted-foreground md:grid-cols-2 lg:grid-cols-4">
          <div>No., Code, Course Name, Section</div>
          <div>Program, Capacity</div>
          <div>Day/Time Venue 1 and 2</div>
          <div>Lecturer and Email</div>
        </CardContent>
      </Card>

      {rows.length > 0 && (
        <Card>
          <CardHeader className="flex flex-row items-center justify-between">
            <CardTitle className="text-base">Timetable Preview</CardTitle>
            <Button onClick={save}><Save className="h-4 w-4 mr-1.5" /> Save Timetable</Button>
          </CardHeader>
          <CardContent className="p-0 overflow-x-auto">
            <table className="w-full min-w-[1180px] border-collapse text-xs">
              <thead>
                <tr className="bg-slate-800 text-white">
                  <th colSpan={11} className="p-2 text-center text-base">TIMETABLE FOR {course.toUpperCase()} SEMESTER {semester}, SESSION 2025/2026</th>
                </tr>
                <tr className="bg-slate-700 text-white">
                  <th colSpan={11} className="p-2 text-center">BILANGAN PELAJAR: {rows.reduce((sum, row) => sum + row.capacity, 0)}</th>
                </tr>
                <tr className="bg-orange-100 text-foreground">
                  {["NO.", "CODE", "NAMA KURSUS", "SEKSYEN", "PROGRAM", "CAPACITY", "HARI/MASA LOKASI", "HARI/MASA LOKASI", "PENSYARAH", "EMAIL", "STATUS"].map((header) => (
                    <th key={header} className="border p-2 text-left">{header}</th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {rows.map((row, index) => (
                  <React.Fragment key={row.no}>
                    {index % sectionsForCourse.length === 0 && (
                      <tr className="bg-blue-200">
                        <td colSpan={11} className="border p-1 text-center font-semibold">{row.program}</td>
                      </tr>
                    )}
                    <tr>
                      <td className="border p-2 text-center">{row.no}</td>
                      <td className="border p-2"><Input className="h-8 w-24" value={row.code} onChange={(event) => update(row.no, { code: event.target.value })} /></td>
                      <td className="border p-2"><Input className="h-8 w-64" value={row.courseName} onChange={(event) => update(row.no, { courseName: event.target.value })} /></td>
                      <td className="border p-2"><Input className="h-8 w-20 text-center" value={row.section} onChange={(event) => update(row.no, { section: event.target.value })} /></td>
                      <td className="border p-2"><Input className="h-8 w-24 text-center" value={row.program} onChange={(event) => update(row.no, { program: event.target.value })} /></td>
                      <td className="border p-2"><Input className="h-8 w-20 text-center" type="number" value={row.capacity} onChange={(event) => update(row.no, { capacity: Number(event.target.value) })} /></td>
                      <td className="border p-2"><MeetingEditor meeting={row.meeting1} onChange={(meeting) => update(row.no, { meeting1: meeting })} /></td>
                      <td className="border p-2"><MeetingEditor meeting={row.meeting2} onChange={(meeting) => update(row.no, { meeting2: meeting })} /></td>
                      <td className="border p-2">
                        <Select
                          value={row.lecturerId}
                          onValueChange={(value) => {
                            const lecturer = LECTURERS.find((item) => item.id === value);
                            update(row.no, { lecturerId: value, lecturer: lecturer?.name || row.lecturer, email: lecturer?.email || row.email });
                          }}
                        >
                          <SelectTrigger className="h-8 w-56"><SelectValue /></SelectTrigger>
                          <SelectContent>{LECTURERS.map((item) => <SelectItem key={item.id} value={item.id}>{item.name}</SelectItem>)}</SelectContent>
                        </Select>
                      </td>
                      <td className="border p-2 text-center">{row.email.split("@")[0]}</td>
                      <td className="border p-2"><StatusBadge status={row.status} /></td>
                    </tr>
                  </React.Fragment>
                ))}
              </tbody>
            </table>
          </CardContent>
        </Card>
      )}
    </div>
  );
}

function validateRow(row: SheetRow): SheetRow {
  const meetings = [row.meeting1, row.meeting2];
  const missing = !row.code || !row.courseName || !row.section || !row.program || !row.lecturer || meetings.some((meeting) => !meeting.day || !meeting.startTime || !meeting.endTime || !meeting.venue);
  const invalidTime = meetings.some((meeting) => meeting.startTime >= meeting.endTime);
  return { ...row, status: missing ? "Missing Data" : invalidTime ? "Invalid Time" : "Valid" };
}

function ReadOnly({ label, value }: { label: string; value: string }) {
  return (
    <div>
      <Label className="text-xs">{label}</Label>
      <Input className="h-9 mt-1" value={value} readOnly />
    </div>
  );
}

function MeetingEditor({ meeting, onChange }: { meeting: Meeting; onChange: (meeting: Meeting) => void }) {
  return (
    <div className="grid gap-1">
      <Select value={meeting.day} onValueChange={(day) => onChange({ ...meeting, day, date: dayDate[day] })}>
        <SelectTrigger className="h-7 w-24"><SelectValue /></SelectTrigger>
        <SelectContent>{Object.keys(dayDate).map((day) => <SelectItem key={day} value={day}>{day}</SelectItem>)}</SelectContent>
      </Select>
      <div className="flex gap-1">
        <Input className="h-7 w-20" type="time" value={meeting.startTime} onChange={(event) => onChange({ ...meeting, startTime: event.target.value })} />
        <Input className="h-7 w-20" type="time" value={meeting.endTime} onChange={(event) => onChange({ ...meeting, endTime: event.target.value })} />
      </div>
      <Input className="h-7 w-36" value={meeting.venue} onChange={(event) => onChange({ ...meeting, venue: event.target.value })} />
    </div>
  );
}
