import * as React from "react";
import { createFileRoute } from "@tanstack/react-router";
import { toast } from "sonner";
import { Download, FileText, Filter, Printer, Search } from "lucide-react";
import { Bar, BarChart, CartesianGrid, ResponsiveContainer, Tooltip, XAxis, YAxis } from "recharts";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { PageHeader } from "@/components/page-header";
import { StatCard } from "@/components/stat-card";
import { StatusBadge } from "@/components/status-badge";
import { useApp } from "@/lib/store";

export const Route = createFileRoute("/m3")({ component: M3 });

const ALL = "All";

function M3() {
  const { students: allStudents, timetable: allTimetable, disciplineReports: allReports, settings, currentUser } = useApp();
  const isLecturer = currentUser?.role === "lecturer";
  const [filters, setFilters] = React.useState({ semester: ALL, course: ALL, section: ALL, lecturer: ALL, q: "" });

  const scopedTimetable = isLecturer
    ? allTimetable.filter((t) => t.lecturerId === currentUser.id)
    : allTimetable;
  const scopedSections = isLecturer
    ? Array.from(new Set(scopedTimetable.map((t) => t.section)))
    : null;
  const baseStudents = scopedSections ? allStudents.filter((s) => scopedSections.includes(s.section)) : allStudents;
  const reports = isLecturer ? allReports.filter((r) => r.lecturer === currentUser.name) : allReports;

  const optionTimetable = scopedTimetable
    .filter((t) => filters.semester === ALL || String(t.semester) === filters.semester)
    .filter((t) => filters.course === ALL || t.program === filters.course)
    .filter((t) => filters.section === ALL || t.section === filters.section);

  const optionStudents = baseStudents
    .filter((s) => filters.semester === ALL || String(s.semester) === filters.semester)
    .filter((s) => filters.course === ALL || s.program === filters.course)
    .filter((s) => filters.section === ALL || s.section === filters.section);

  const options = {
    semester: Array.from(
      new Set(
        baseStudents
          .filter((s) => filters.course === ALL || s.program === filters.course)
          .filter((s) => filters.section === ALL || s.section === filters.section)
          .map((s) => String(s.semester)),
      ),
    ).sort(),
    course: Array.from(
      new Set(
        baseStudents
          .filter((s) => filters.semester === ALL || String(s.semester) === filters.semester)
          .filter((s) => filters.section === ALL || s.section === filters.section)
          .map((s) => s.program),
      ),
    ).sort(),
    section: Array.from(new Set(optionStudents.map((s) => s.section))).sort(),
    lecturer: Array.from(new Set(optionTimetable.map((t) => t.lecturerName))).sort(),
  };

  const filteredStudents = baseStudents
    .filter((s) => filters.semester === ALL || String(s.semester) === filters.semester)
    .filter((s) => filters.course === ALL || s.program === filters.course)
    .filter((s) => filters.section === ALL || s.section === filters.section)
    .filter((s) => !filters.q || [s.id, s.name, s.section, s.program].some((value) => value.toLowerCase().includes(filters.q.toLowerCase())));

  const filteredTimetable = scopedTimetable
    .filter((t) => filters.semester === ALL || String(t.semester) === filters.semester)
    .filter((t) => filters.course === ALL || t.program === filters.course)
    .filter((t) => filters.section === ALL || t.section === filters.section)
    .filter((t) => filters.lecturer === ALL || t.lecturerName === filters.lecturer);

  const avgAttendance = filteredStudents.length
    ? Math.round(filteredStudents.reduce((sum, student) => sum + student.attendance, 0) / filteredStudents.length)
    : 0;
  const below = filteredStudents.filter((student) => student.attendance < settings.threshold);
  const notSubmitted = filteredTimetable.filter((slot) => slot.status === "Attendance Not Taken" || slot.status === "Attendance Pending");
  const completed = filteredTimetable.filter((slot) => slot.status === "Attendance Completed");

  const classSummary = Array.from(new Set(filteredStudents.map((student) => student.section))).map((section) => {
    const students = filteredStudents.filter((student) => student.section === section);
    const slots = filteredTimetable.filter((slot) => slot.section === section);
    const course = students[0]?.program || slots[0]?.program || "-";
    return {
      section,
      course,
      students: students.length,
      avg: students.length ? Math.round(students.reduce((sum, student) => sum + student.attendance, 0) / students.length) : 0,
      below: students.filter((student) => student.attendance < settings.threshold).length,
      sessions: slots.length,
      pending: slots.filter((slot) => slot.status === "Attendance Not Taken" || slot.status === "Attendance Pending").length,
    };
  });

  const lecturerSummary = Array.from(new Set(filteredTimetable.map((slot) => slot.lecturerName))).map((lecturer) => {
    const slots = filteredTimetable.filter((slot) => slot.lecturerName === lecturer);
    const done = slots.filter((slot) => slot.status === "Attendance Completed").length;
    return {
      lecturer,
      classes: slots.length,
      completed: done,
      pending: slots.length - done,
      rate: slots.length ? Math.round((done / slots.length) * 100) : 0,
    };
  });

  const setF = (key: keyof typeof filters) => (value: string) =>
    setFilters((prev) => {
      const next = { ...prev, [key]: value };
      if (key === "semester" || key === "course") {
        next.section = ALL;
        next.lecturer = ALL;
      }
      if (key === "section") {
        next.lecturer = ALL;
      }
      return next;
    });

  const downloadCsv = (kind: "summary" | "below" | "lecturer") => {
    const data =
      kind === "below"
        ? [["Student ID", "Name", "Course", "Section", "Attendance"], ...below.map((s) => [s.id, s.name, s.program, s.section, `${s.attendance}%`])]
        : kind === "lecturer"
          ? [["Lecturer", "Classes", "Completed", "Pending", "Submission Rate"], ...lecturerSummary.map((l) => [l.lecturer, l.classes, l.completed, l.pending, `${l.rate}%`])]
          : [["Section", "Course", "Student", "Avg Attendance", "Below Threshold", "Sessions", "Pending"], ...classSummary.map((c) => [c.section, c.course, c.students, `${c.avg}%`, c.below, c.sessions, c.pending])];
    const csv = data.map((row) => row.map((cell) => `"${String(cell).replace(/"/g, '""')}"`).join(",")).join("\n");
    const blob = new Blob([csv], { type: "text/csv;charset=utf-8" });
    const url = URL.createObjectURL(blob);
    const link = document.createElement("a");
    link.href = url;
    link.download = `tvetmara-${kind}-report.csv`;
    link.click();
    URL.revokeObjectURL(url);
    toast.success("Report downloaded.");
  };

  return (
    <div className="space-y-5">
      <PageHeader
        title="Reporting Module"
        subtitle={isLecturer ? "Attendance report for your assigned sections." : "Attendance report for sections, submissions, and follow-up decisions."}
        actions={
          <>
            <Button size="sm" onClick={() => downloadCsv("summary")}>
              <Download className="h-4 w-4 mr-1.5" /> Download Summary
            </Button>
            <Button variant="outline" size="sm" onClick={() => window.print()}>
              <Printer className="h-4 w-4 mr-1.5" /> Print
            </Button>
          </>
        }
      />

      <Card>
        <CardHeader className="pb-3">
          <CardTitle className="text-sm flex items-center gap-2">
            <Filter className="h-4 w-4" /> Report Filters
          </CardTitle>
        </CardHeader>
        <CardContent className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-5 gap-3">
          <FilterSelect label="Semester" value={filters.semester} options={options.semester} onChange={setF("semester")} />
          <FilterSelect label="Course" value={filters.course} options={options.course} onChange={setF("course")} />
          <FilterSelect label="Section" value={filters.section} options={options.section} onChange={setF("section")} />
          {!isLecturer && <FilterSelect label="Lecturer" value={filters.lecturer} options={options.lecturer} onChange={setF("lecturer")} />}
          <div>
            <Label className="text-xs">Search</Label>
            <div className="relative mt-1">
              <Search className="absolute left-2.5 top-2.5 h-4 w-4 text-muted-foreground" />
              <Input className="h-9 pl-8" value={filters.q} onChange={(e) => setF("q")(e.target.value)} placeholder="Student, seksyen, kursus" />
            </div>
          </div>
        </CardContent>
      </Card>

      <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
        <StatCard label="Student" value={filteredStudents.length} />
        <StatCard label="Avg Attendance" value={`${avgAttendance}%`} tone="success" />
        <StatCard label={`Bawah ${settings.threshold}%`} value={below.length} tone="destructive" />
        <StatCard label="Pending Submissions" value={notSubmitted.length} tone="warning" />
      </div>

      <Card className="border-primary/20">
        <CardHeader className="pb-2">
          <CardTitle className="text-base">Report Actions</CardTitle>
        </CardHeader>
        <CardContent className="grid gap-3 lg:grid-cols-[1fr_auto]">
          <div className="grid gap-3 md:grid-cols-3">
          <Insight
            title={below.length ? "Follow-up required" : "Attendance is healthy"}
            text={below.length ? `${below.length} student(s) are below ${settings.threshold}% in the current filter.` : "No students in the current filter are below the attendance threshold."}
            tone={below.length ? "warning" : "success"}
          />
          <Insight
            title={notSubmitted.length ? "Submission pending" : "Submissions clear"}
            text={notSubmitted.length ? `${notSubmitted.length} slot jadual masih memerlukan hantaran kehadiran.` : "All filtered timetable slots have no pending submission."}
            tone={notSubmitted.length ? "warning" : "success"}
          />
          <Insight
            title="Download ready"
            text={isLecturer ? "Download a section report for your own teaching record." : "Download class, lecturer, or below-threshold reports for admin records."}
            tone="info"
          />
          </div>
          <div className="flex flex-col gap-2 sm:flex-row lg:w-56 lg:flex-col">
            <Button onClick={() => downloadCsv("summary")}>
              <FileText className="h-4 w-4 mr-1.5" /> Download Summary Section
            </Button>
            <Button variant="outline" onClick={() => downloadCsv("below")}>
              <Download className="h-4 w-4 mr-1.5" /> Download Below Threshold
            </Button>
            {!isLecturer && (
              <Button variant="outline" onClick={() => downloadCsv("lecturer")}>
                <Download className="h-4 w-4 mr-1.5" /> Download Lecturer Submission
              </Button>
            )}
          </div>
        </CardContent>
      </Card>

      <div className="grid lg:grid-cols-[1fr_360px] gap-4">
        <Card>
          <CardHeader>
            <CardTitle className="text-base">Attendance by Section</CardTitle>
            <p className="text-xs text-muted-foreground">Setiap bar menunjukkan purata kehadiran bagi seksyen in the current filter.</p>
          </CardHeader>
          <CardContent className="h-72">
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={classSummary}>
                <CartesianGrid strokeDasharray="3 3" opacity={0.25} />
                <XAxis dataKey="section" fontSize={11} />
                <YAxis domain={[0, 100]} fontSize={11} />
                <Tooltip />
                <Bar dataKey="avg" name="Average %" fill="oklch(0.55 0.18 230)" radius={[4, 4, 0, 0]} />
              </BarChart>
            </ResponsiveContainer>
          </CardContent>
        </Card>
        <Card>
          <CardHeader>
            <CardTitle className="text-base">Report Snapshot</CardTitle>
          </CardHeader>
          <CardContent className="space-y-3 text-sm">
            <ReportLine label="Sessions kehadiran selesai" value={completed.length} tone="success" />
            <ReportLine label="Sessions kehadiran menunggu" value={notSubmitted.length} tone="warning" />
            <ReportLine label="Discipline reports" value={reports.length} tone="info" />
            <ReportLine label="Sections included" value={classSummary.length} tone="info" />
            <Button className="w-full" variant="outline" onClick={() => downloadCsv("summary")}>
              <FileText className="h-4 w-4 mr-1.5" /> Download Summary
            </Button>
          </CardContent>
        </Card>
      </div>

      <Tabs defaultValue="class">
        <TabsList className="flex h-auto flex-wrap">
          <TabsTrigger value="class">Section Summary</TabsTrigger>
          <TabsTrigger value="lecturer">Lecturer Submission</TabsTrigger>
          <TabsTrigger value="below">Below Threshold</TabsTrigger>
          <TabsTrigger value="discipline">Discipline Status</TabsTrigger>
        </TabsList>

        <TabsContent value="class">
          <SimpleTable
            headers={["Section", "Course", "Student", "Avg", "Below Threshold", "Sessions", "Pending"]}
            rows={classSummary.map((c) => [c.section, c.course, c.students, `${c.avg}%`, c.below, c.sessions, c.pending])}
          />
        </TabsContent>

        <TabsContent value="lecturer">
          <div className="mb-3 flex justify-end">
            <Button size="sm" variant="outline" onClick={() => downloadCsv("lecturer")}>Download CSV Lecturer</Button>
          </div>
          <SimpleTable
            headers={["Lecturer", "Classes", "Completed", "Pending", "Submission Rate"]}
            rows={lecturerSummary.map((l) => [l.lecturer, l.classes, l.completed, l.pending, `${l.rate}%`])}
          />
        </TabsContent>

        <TabsContent value="below">
          <div className="mb-3 flex justify-end">
            <Button size="sm" variant="outline" onClick={() => downloadCsv("below")}>Download CSV Below Threshold</Button>
          </div>
          <SimpleTable
            headers={["Student ID", "Name", "Course", "Section", "Attendance", "Status"]}
            rows={below.map((s) => [s.id, s.name, s.program, s.section, `${s.attendance}%`, s.attendance < 60 ? "Critical" : "Warning"])}
            statusColumn={5}
          />
        </TabsContent>

        <TabsContent value="discipline">
          <SimpleTable
            headers={["Report ID", "Student", "Section", "Subject", "Lecturer", "Issue", "Severity", "Status"]}
            rows={reports.map((r) => [r.id, r.studentName, r.section, r.subject, r.lecturer, r.issueType, r.severity, r.status])}
            statusColumn={7}
          />
        </TabsContent>
      </Tabs>
    </div>
  );
}

function FilterSelect({ label, value, options, onChange }: { label: string; value: string; options: string[]; onChange: (value: string) => void }) {
  return (
    <div>
      <Label className="text-xs">{label}</Label>
      <Select value={value} onValueChange={onChange}>
        <SelectTrigger className="h-9 mt-1"><SelectValue /></SelectTrigger>
        <SelectContent>
          <SelectItem value={ALL}>All</SelectItem>
          {options.map((option) => <SelectItem key={option} value={option}>{option}</SelectItem>)}
        </SelectContent>
      </Select>
    </div>
  );
}

function Insight({ title, text, tone }: { title: string; text: string; tone: "success" | "warning" | "info" }) {
  const cls = tone === "success" ? "border-l-success bg-success/5" : tone === "warning" ? "border-l-warning bg-warning/10" : "border-l-info bg-info/5";
  return (
    <div className={`rounded-md border-l-4 p-3 ${cls}`}>
      <div className="text-sm font-semibold">{title}</div>
      <div className="mt-1 text-xs text-muted-foreground">{text}</div>
    </div>
  );
}

function ReportLine({ label, value, tone }: { label: string; value: number; tone: "success" | "warning" | "info" }) {
  return (
    <div className="flex items-center justify-between border-b pb-2 last:border-0">
      <span className="text-muted-foreground">{label}</span>
      <StatusBadge status={tone === "success" ? "Completed" : tone === "warning" ? "Pending" : "Active"} />
      <span className="font-bold">{value}</span>
    </div>
  );
}

function SimpleTable({ headers, rows, statusColumn }: { headers: string[]; rows: Array<Array<string | number>>; statusColumn?: number }) {
  return (
    <Card>
      <CardContent className="p-0 overflow-x-auto">
        <table className="w-full text-sm">
          <thead className="border-b bg-muted/40 text-xs text-muted-foreground">
            <tr>{headers.map((header) => <th key={header} className="p-2 text-left whitespace-nowrap">{header}</th>)}</tr>
          </thead>
          <tbody>
            {rows.length === 0 && (
              <tr>
                <td className="p-4 text-center text-sm text-muted-foreground" colSpan={headers.length}>
                  No records match the current filters. Try selecting All semester, course, or section.
                </td>
              </tr>
            )}
            {rows.map((row, index) => (
              <tr key={index} className="border-b last:border-0 hover:bg-muted/30">
                {row.map((cell, cellIndex) => (
                  <td key={`${index}-${cellIndex}`} className="p-2">
                    {statusColumn === cellIndex ? <StatusBadge status={String(cell)} /> : cell}
                  </td>
                ))}
              </tr>
            ))}
          </tbody>
        </table>
      </CardContent>
    </Card>
  );
}
