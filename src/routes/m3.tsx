import * as React from "react";
import { createFileRoute } from "@tanstack/react-router";
import { toast } from "sonner";
import { Download, Printer, Mail, FileText, Filter, RotateCcw, FileDown, Eye, History, Send, AlertTriangle, FilePlus, StickyNote } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Tabs, TabsList, TabsTrigger, TabsContent } from "@/components/ui/tabs";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Dialog, DialogContent, DialogFooter, DialogHeader, DialogTitle, DialogDescription } from "@/components/ui/dialog";
import { Textarea } from "@/components/ui/textarea";
import { PageHeader } from "@/components/page-header";
import { StatCard } from "@/components/stat-card";
import { StatusBadge } from "@/components/status-badge";
import { useApp } from "@/lib/store";
import { Bar, BarChart, CartesianGrid, Cell, Legend, Line, LineChart, Pie, PieChart, ResponsiveContainer, Tooltip, XAxis, YAxis } from "recharts";

export const Route = createFileRoute("/m3")({ component: M3 });

const FILTER_OPTIONS = {
  session: ["All Sessions", "Jan-Jun 2026", "Jul-Dec 2026", "Jan-Jun 2025"],
  semester: ["All Semesters", "Semester 1", "Semester 2", "Semester 3", "Semester 4"],
  program: ["All Programs", "Electrical Installation", "Automotive Technology", "Welding Technology", "Mechanical Maintenance", "Air Conditioning Technology", "Computer System Technology"],
  section: ["All Classes", "ELI-1A", "ELI-1B", "AUTO-2A", "WELD-1A", "MECH-2B", "AC-1C"],
  subject: ["All Subjects", "Electrical Installation Theory", "Electrical Installation Practice", "Electrical Supply Act and Regulations", "Electrical Motor Control", "Automotive Service Practice", "Welding Practical", "Mechanical Maintenance", "Air Conditioning System"],
  lecturer: ["All Lecturers", "Encik Ahmad bin Ismail", "Encik Razak bin Hamid", "Puan Aminah binti Yahya", "Puan Siti Nurhaliza", "Encik Firdaus bin Rahman", "Puan Noraini binti Salleh"],
  week: ["All Weeks", ...Array.from({ length: 18 }, (_, i) => `Week ${i + 1}`)],
  status: ["All Statuses", "Present", "Absent", "MC", "CK", "Late"],
  submission: ["All Submission Status", "Submitted", "Pending", "Draft", "Not Submitted"],
  category: ["All Categories", "Below 80%", "80% and Above", "Critical Below 60%", "Perfect Attendance 100%"],
};

const DEFAULT_FILTERS = {
  session: "All Sessions", semester: "All Semesters", program: "All Programs",
  section: "All Classes", subject: "All Subjects", lecturer: "All Lecturers",
  week: "All Weeks", status: "All Statuses", submission: "All Submission Status",
  category: "All Categories", from: "2026-01-01", to: "2026-04-29",
};

type EmailDlg = { to: string; subject: string; body: string } | null;
type StatusDlg = { id: string; current: string } | null;
type NoteDlg = { id: string } | null;
type DiscDlg = { studentId: string; studentName: string } | null;
type DetailsDlg = { title: string; rows: Array<[string, string]> } | null;
type HistoryDlg = { name: string } | null;

function M3() {
  const { students, timetable, disciplineReports, settings, currentUser } = useApp();
  const isAdmin = currentUser?.role === "admin";

  const [filters, setFilters] = React.useState(DEFAULT_FILTERS);
  const [applied, setApplied] = React.useState(0); // bump to "refresh" mock data
  const [emailDlg, setEmailDlg] = React.useState<EmailDlg>(null);
  const [statusDlg, setStatusDlg] = React.useState<StatusDlg>(null);
  const [noteDlg, setNoteDlg] = React.useState<NoteDlg>(null);
  const [discDlg, setDiscDlg] = React.useState<DiscDlg>(null);
  const [detailsDlg, setDetailsDlg] = React.useState<DetailsDlg>(null);
  const [historyDlg, setHistoryDlg] = React.useState<HistoryDlg>(null);
  const [printOpen, setPrintOpen] = React.useState(false);
  const [reminderConfirm, setReminderConfirm] = React.useState<{ name: string; email: string } | null>(null);

  const setF = (k: keyof typeof DEFAULT_FILTERS) => (v: string) => setFilters((f) => ({ ...f, [k]: v }));

  const totalClasses = timetable.length;
  const avgAtt = Math.round(students.reduce((a, s) => a + s.attendance, 0) / students.length);
  const below = students.filter((s) => s.attendance < settings.threshold);
  const critical = students.filter((s) => s.attendance < 60);

  // Mock numbers shift slightly when filters applied
  const jitter = (n: number) => Math.max(0, n - (applied % 5));

  const trendData = Array.from({ length: 18 }, (_, i) => ({
    week: `W${i + 1}`,
    attendance: 78 + ((i * 7 + applied) % 18),
    absent: 4 + ((i * 3) % 7),
    late: 2 + (i % 5),
    sessions: 18 + (i % 4),
    below: Math.max(1, 5 + (i % 6) - applied % 3),
  }));
  const dist = [
    { name: "Present", value: jitter(72), color: "var(--success)" },
    { name: "Absent", value: 12, color: "var(--destructive)" },
    { name: "Late", value: 8, color: "var(--warning)" },
    { name: "MC", value: 5, color: "var(--info)" },
    { name: "CK", value: 3, color: "var(--replacement)" },
  ];
  const sectionData = ["ELI-1A", "ELI-1B", "AUTO-2A", "WELD-1A", "MECH-2B", "AC-1C"].map((sec) => {
    const ss = students.filter((s) => s.section === sec);
    return { section: sec, attendance: ss.length ? Math.round(ss.reduce((a, s) => a + s.attendance, 0) / ss.length) - (applied % 3) : 80 };
  });
  const programBelowData = FILTER_OPTIONS.program.slice(1).map((p, i) => ({ program: p.split(" ")[0], count: 4 + ((i * 3 + applied) % 8) }));
  const lecturerSubmission = [
    { id: "L001", name: "Encik Ahmad bin Ismail", department: "Electrical", assigned: 6, total: 96, submitted: 92, pending: 2, notSubmitted: 2, last: "2026-04-29", status: "Completed" },
    { id: "L002", name: "Encik Razak bin Hamid", department: "Automotive", assigned: 5, total: 80, submitted: 70, pending: 6, notSubmitted: 4, last: "2026-04-28", status: "Pending" },
    { id: "L003", name: "Puan Aminah binti Yahya", department: "Welding", assigned: 4, total: 64, submitted: 64, pending: 0, notSubmitted: 0, last: "2026-04-29", status: "Completed" },
    { id: "L004", name: "Puan Siti Nurhaliza", department: "Electrical", assigned: 5, total: 80, submitted: 60, pending: 8, notSubmitted: 12, last: "2026-04-25", status: "Late Submission" },
    { id: "L005", name: "Encik Firdaus bin Rahman", department: "Mechanical", assigned: 4, total: 64, submitted: 40, pending: 10, notSubmitted: 14, last: "2026-04-22", status: "Not Submitted" },
    { id: "L006", name: "Puan Noraini binti Salleh", department: "Air Conditioning", assigned: 3, total: 48, submitted: 46, pending: 1, notSubmitted: 1, last: "2026-04-29", status: "Completed" },
  ].map((l) => ({ ...l, rate: Math.round((l.submitted / l.total) * 100) }));

  const lecturerChart = lecturerSubmission.map((l) => ({ name: l.name.split(" ").slice(-2).join(" "), rate: l.rate }));

  const subjectData = [
    { code: "EE101", name: "Electrical Installation Theory", program: "Electrical", semester: "Sem 1", lecturer: "Encik Ahmad bin Ismail", classes: 18, avg: 88, hi: 98, lo: 62, below: 3 },
    { code: "EE102", name: "Electrical Installation Practice", program: "Electrical", semester: "Sem 1", lecturer: "Puan Siti Nurhaliza", classes: 16, avg: 82, hi: 96, lo: 58, below: 5 },
    { code: "EE103", name: "Electrical Supply Act and Regulations", program: "Electrical", semester: "Sem 2", lecturer: "Encik Ahmad bin Ismail", classes: 14, avg: 90, hi: 100, lo: 70, below: 1 },
    { code: "EE104", name: "Electrical Motor Control", program: "Electrical", semester: "Sem 2", lecturer: "Puan Siti Nurhaliza", classes: 15, avg: 79, hi: 94, lo: 55, below: 6 },
    { code: "AT201", name: "Automotive Service Practice", program: "Automotive", semester: "Sem 2", lecturer: "Encik Razak bin Hamid", classes: 17, avg: 85, hi: 96, lo: 64, below: 3 },
    { code: "WT101", name: "Welding Practical", program: "Welding", semester: "Sem 1", lecturer: "Puan Aminah binti Yahya", classes: 15, avg: 87, hi: 98, lo: 66, below: 2 },
    { code: "MM201", name: "Mechanical Maintenance", program: "Mechanical", semester: "Sem 2", lecturer: "Encik Firdaus bin Rahman", classes: 14, avg: 76, hi: 92, lo: 50, below: 7 },
    { code: "AC101", name: "Air Conditioning System", program: "Air Cond", semester: "Sem 1", lecturer: "Puan Noraini binti Salleh", classes: 16, avg: 89, hi: 99, lo: 70, below: 2 },
  ];

  const classData = [
    { section: "ELI-1A", program: "Electrical Installation", semester: "Sem 1", subject: "EE101", lecturer: "Encik Ahmad bin Ismail", students: 28, avg: 88, below: 3, sessions: 18, sub: "Submitted" },
    { section: "ELI-1B", program: "Electrical Installation", semester: "Sem 1", subject: "EE102", lecturer: "Puan Siti Nurhaliza", students: 26, avg: 82, below: 5, sessions: 16, sub: "Pending" },
    { section: "AUTO-2A", program: "Automotive Technology", semester: "Sem 2", subject: "AT201", lecturer: "Encik Razak bin Hamid", students: 24, avg: 85, below: 3, sessions: 17, sub: "Submitted" },
    { section: "WELD-1A", program: "Welding Technology", semester: "Sem 1", subject: "WT101", lecturer: "Puan Aminah binti Yahya", students: 22, avg: 87, below: 2, sessions: 15, sub: "Submitted" },
    { section: "MECH-2B", program: "Mechanical Maintenance", semester: "Sem 2", subject: "MM201", lecturer: "Encik Firdaus bin Rahman", students: 25, avg: 76, below: 7, sessions: 14, sub: "Not Submitted" },
    { section: "AC-1C", program: "Air Conditioning Technology", semester: "Sem 1", subject: "AC101", lecturer: "Puan Noraini binti Salleh", students: 23, avg: 89, below: 2, sessions: 16, sub: "Submitted" },
  ];

  const applyFilters = () => { setApplied((n) => n + 1); toast.success("Filters applied successfully."); };
  const resetFilters = () => { setFilters(DEFAULT_FILTERS); setApplied(0); toast("Filters reset."); };

  const openContact = (name: string, email: string, kind: "student" | "lecturer" | "warning" = "student") => {
    if (kind === "warning") {
      setEmailDlg({
        to: email, subject: "Attendance Warning - TVETMARA Johor Bahru",
        body: `Dear ${name},\n\nOur records show your attendance is currently below the required 80% threshold. Please contact your lecturer or the academic office immediately to address this matter.\n\nThank you,\nTVETMARA Johor Bahru`,
      });
    } else if (kind === "lecturer") {
      setEmailDlg({
        to: email, subject: "Attendance Submission Reminder",
        body: `Dear ${name},\n\nPlease update or submit the pending attendance records for your assigned classes.\n\nThank you.`,
      });
    } else {
      setEmailDlg({ to: email, subject: "TVETMARA Johor Bahru - Attendance Notice", body: `Dear ${name},\n\nWe would like to discuss your recent attendance record.\n\nThank you.` });
    }
  };

  return (
    <div className="space-y-5">
      <PageHeader
        title="Reporting Module / Modul Laporan"
        subtitle={isAdmin
          ? "Monitor attendance records, attendance trends, students below requirement, and class submission status."
          : "Attendance statistics, summaries, trends and official reports."}
        actions={
          <>
            <Button variant="outline" size="sm" onClick={() => toast.success("PDF report generated successfully.")}><FileText className="h-4 w-4 mr-1.5" /> PDF</Button>
            <Button variant="outline" size="sm" onClick={() => toast.success("Excel report generated successfully.")}><Download className="h-4 w-4 mr-1.5" /> Excel</Button>
            <Button variant="outline" size="sm" onClick={() => setPrintOpen(true)}><Printer className="h-4 w-4 mr-1.5" /> Print</Button>
            <Button variant="outline" size="sm" onClick={() => setEmailDlg({ to: "principal@tvetmara.edu.my", subject: "TVETMARA Attendance Report", body: "Please find attached the attendance report.\n\nRegards,\nAcademic Office" })}><Mail className="h-4 w-4 mr-1.5" /> Email</Button>
          </>
        }
      />

      <Card>
        <CardHeader className="pb-3 flex flex-row items-center justify-between">
          <CardTitle className="text-sm flex items-center gap-2"><Filter className="h-4 w-4" /> Filters</CardTitle>
          <div className="flex flex-wrap gap-2">
            <Button size="sm" onClick={applyFilters}><Filter className="h-4 w-4 mr-1.5" /> Apply Filters</Button>
            <Button size="sm" variant="outline" onClick={resetFilters}><RotateCcw className="h-4 w-4 mr-1.5" /> Reset Filters</Button>
            <Button size="sm" variant="outline" onClick={() => toast.success("Filtered attendance report exported successfully.")}><FileDown className="h-4 w-4 mr-1.5" /> Export Filtered Report</Button>
          </div>
        </CardHeader>
        <CardContent className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-3">
          {([
            ["Academic Session", "session"], ["Semester", "semester"], ["Program", "program"], ["Class / Section", "section"],
            ["Subject", "subject"], ["Lecturer", "lecturer"], ["Week", "week"], ["Attendance Status", "status"],
            ["Submission Status", "submission"], ["Attendance Category", "category"],
          ] as const).map(([label, key]) => (
            <div key={key}>
              <Label className="text-xs">{label}</Label>
              <Select value={filters[key]} onValueChange={setF(key)}>
                <SelectTrigger className="h-9 mt-1"><SelectValue /></SelectTrigger>
                <SelectContent>
                  {(FILTER_OPTIONS as any)[key].map((o: string) => <SelectItem key={o} value={o}>{o}</SelectItem>)}
                </SelectContent>
              </Select>
            </div>
          ))}
          <div><Label className="text-xs">Start Date</Label><Input className="h-9 mt-1" type="date" value={filters.from} onChange={(e) => setF("from")(e.target.value)} /></div>
          <div><Label className="text-xs">End Date</Label><Input className="h-9 mt-1" type="date" value={filters.to} onChange={(e) => setF("to")(e.target.value)} /></div>
        </CardContent>
      </Card>

      <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-5 gap-3">
        <StatCard label="Total Students" value={students.length} />
        <StatCard label="Total Classes" value={totalClasses} tone="info" />
        <StatCard label="Total Sessions" value={1432 - applied * 4} tone="info" />
        <StatCard label="Avg Attendance" value={`${avgAtt - (applied % 3)}%`} tone="success" />
        <StatCard label="Total Present" value={1248 - applied * 3} tone="success" />
        <StatCard label="Total Absent" value={186 + applied} tone="destructive" />
        <StatCard label="Total MC" value={64} tone="info" />
        <StatCard label="Total CK" value={32} tone="info" />
        <StatCard label="Total Late" value={92 + applied} tone="warning" />
        <StatCard label="Below 80%" value={below.length} tone="destructive" />
        <StatCard label="Critical Below 60%" value={critical.length} tone="destructive" />
        <StatCard label="Attendance Not Submitted" value={timetable.filter((t) => t.status === "Attendance Not Taken").length} tone="warning" />
        <StatCard label="Pending Lecturer Submission" value={lecturerSubmission.reduce((a, l) => a + l.pending, 0)} tone="warning" />
      </div>

      <Tabs defaultValue="student">
        <TabsList className="flex flex-wrap h-auto">
          <TabsTrigger value="student">Student</TabsTrigger>
          <TabsTrigger value="class">Class</TabsTrigger>
          <TabsTrigger value="subject">Subject</TabsTrigger>
          {isAdmin && <TabsTrigger value="lecturer">Lecturer Submission</TabsTrigger>}
          <TabsTrigger value="trend">Weekly Trend</TabsTrigger>
          <TabsTrigger value="below">Below 80%</TabsTrigger>
          <TabsTrigger value="discipline">Discipline</TabsTrigger>
        </TabsList>

        <TabsContent value="student"><Card><CardContent className="p-0 overflow-x-auto">
          <table className="w-full text-sm">
            <thead className="text-xs text-muted-foreground border-b bg-muted/40"><tr>
              {["Student ID", "Name", "Program", "Section", "Semester", "Subject", "Present", "Absent", "MC", "CK", "Late", "Att %", "Status", "Action"].map((h) => <th key={h} className="text-left p-2 whitespace-nowrap">{h}</th>)}
            </tr></thead>
            <tbody>
              {students.slice(0, 15).map((s, i) => {
                const pres = 30 - ((i * 3) % 10), abs = (i * 2) % 6, mc = i % 3, ck = i % 2, late = (i * 5) % 4;
                const status = s.attendance >= 90 ? "Good" : s.attendance >= 80 ? "Warning" : "Critical";
                return (
                  <tr key={s.id} className="border-b last:border-0">
                    <td className="p-2 font-mono text-xs">{s.id}</td><td className="p-2 font-medium whitespace-nowrap">{s.name}</td><td className="p-2 text-xs">{s.program}</td><td className="p-2">{s.section}</td><td className="p-2 text-xs">Sem 1</td><td className="p-2 text-xs">EE101</td>
                    <td className="p-2">{pres}</td><td className="p-2">{abs}</td><td className="p-2">{mc}</td><td className="p-2">{ck}</td><td className="p-2">{late}</td>
                    <td className="p-2 font-bold">{s.attendance}%</td><td className="p-2"><StatusBadge status={status} /></td>
                    <td className="p-2"><div className="flex gap-1">
                      <Button size="sm" variant="ghost" className="h-7 w-7 p-0" title="View Details" onClick={() => setDetailsDlg({ title: `Student Profile - ${s.name}`, rows: [["Student ID", s.id], ["Name", s.name], ["Program", s.program], ["Section", s.section], ["Email", s.email], ["Attendance", `${s.attendance}%`], ["Present", String(pres)], ["Absent", String(abs)], ["MC", String(mc)], ["CK", String(ck)], ["Late", String(late)]] })}><Eye className="h-3.5 w-3.5" /></Button>
                      <Button size="sm" variant="ghost" className="h-7 w-7 p-0" title="View Absence History" onClick={() => setHistoryDlg({ name: s.name })}><History className="h-3.5 w-3.5" /></Button>
                      <Button size="sm" variant="ghost" className="h-7 w-7 p-0" title="Contact Student" onClick={() => openContact(s.name, s.email, "student")}><Mail className="h-3.5 w-3.5" /></Button>
                    </div></td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </CardContent></Card></TabsContent>

        <TabsContent value="class"><Card><CardContent className="p-0 overflow-x-auto">
          <table className="w-full text-sm">
            <thead className="text-xs text-muted-foreground border-b bg-muted/40"><tr>{["Section", "Program", "Semester", "Subject", "Lecturer", "Students", "Avg Att %", "Below 80%", "Sessions", "Submission", "Action"].map((h) => <th key={h} className="text-left p-2 whitespace-nowrap">{h}</th>)}</tr></thead>
            <tbody>
              {classData.map((c) => (
                <tr key={c.section} className="border-b">
                  <td className="p-2 font-medium">{c.section}</td><td className="p-2 text-xs">{c.program}</td><td className="p-2 text-xs">{c.semester}</td><td className="p-2 text-xs">{c.subject}</td><td className="p-2 text-xs">{c.lecturer}</td>
                  <td className="p-2">{c.students}</td><td className="p-2 font-bold">{c.avg}%</td><td className="p-2">{c.below}</td><td className="p-2">{c.sessions}</td>
                  <td className="p-2"><StatusBadge status={c.sub === "Submitted" ? "Completed" : c.sub === "Pending" ? "Pending" : "Not Submitted"} /></td>
                  <td className="p-2"><div className="flex gap-1">
                    <Button size="sm" variant="outline" className="h-7 text-xs" onClick={() => setDetailsDlg({ title: `Class ${c.section}`, rows: [["Section", c.section], ["Program", c.program], ["Subject", c.subject], ["Lecturer", c.lecturer], ["Students", String(c.students)], ["Average", `${c.avg}%`], ["Below 80%", String(c.below)], ["Sessions", String(c.sessions)], ["Submission", c.sub]] })}>Details</Button>
                    <Button size="sm" variant="ghost" className="h-7 text-xs" onClick={() => toast(`Showing ${c.students} students in ${c.section}`)}>Students</Button>
                    <Button size="sm" variant="ghost" className="h-7 text-xs" onClick={() => toast.success(`${c.section} class report exported.`)}>Export</Button>
                  </div></td>
                </tr>
              ))}
            </tbody>
          </table>
        </CardContent></Card></TabsContent>

        <TabsContent value="subject"><Card><CardContent className="p-0 overflow-x-auto">
          <table className="w-full text-sm">
            <thead className="text-xs text-muted-foreground border-b bg-muted/40"><tr>{["Code", "Subject", "Program", "Semester", "Lecturer", "Classes", "Avg %", "Highest %", "Lowest %", "Below 80%", "Action"].map((h) => <th key={h} className="text-left p-2 whitespace-nowrap">{h}</th>)}</tr></thead>
            <tbody>
              {subjectData.map((s) => (
                <tr key={s.code} className="border-b">
                  <td className="p-2 font-mono text-xs">{s.code}</td><td className="p-2">{s.name}</td><td className="p-2 text-xs">{s.program}</td><td className="p-2 text-xs">{s.semester}</td><td className="p-2 text-xs">{s.lecturer}</td>
                  <td className="p-2">{s.classes}</td><td className="p-2 font-bold">{s.avg}%</td><td className="p-2 text-success">{s.hi}%</td><td className="p-2 text-destructive">{s.lo}%</td><td className="p-2">{s.below}</td>
                  <td className="p-2"><div className="flex gap-1">
                    <Button size="sm" variant="outline" className="h-7 text-xs" onClick={() => setDetailsDlg({ title: `${s.code} - ${s.name}`, rows: [["Code", s.code], ["Subject", s.name], ["Program", s.program], ["Semester", s.semester], ["Lecturer", s.lecturer], ["Classes", String(s.classes)], ["Average", `${s.avg}%`], ["Highest", `${s.hi}%`], ["Lowest", `${s.lo}%`], ["Below 80%", String(s.below)]] })}>Details</Button>
                    <Button size="sm" variant="ghost" className="h-7 text-xs" onClick={() => toast.success(`${s.code} subject report exported.`)}>Export</Button>
                  </div></td>
                </tr>
              ))}
            </tbody>
          </table>
        </CardContent></Card></TabsContent>

        {isAdmin && (
          <TabsContent value="lecturer">
            <Card className="mb-3"><CardContent className="p-4 h-64">
              <ResponsiveContainer><BarChart data={lecturerChart}><CartesianGrid strokeDasharray="3 3" opacity={0.3} /><XAxis dataKey="name" fontSize={10} /><YAxis fontSize={11} domain={[0, 100]} /><Tooltip /><Bar dataKey="rate" fill="oklch(0.50 0.18 255)" radius={[4, 4, 0, 0]} /></BarChart></ResponsiveContainer>
            </CardContent></Card>
            <Card><CardContent className="p-0 overflow-x-auto">
              <table className="w-full text-sm">
                <thead className="text-xs text-muted-foreground border-b bg-muted/40"><tr>{["Lecturer ID", "Name", "Department", "Classes", "Total", "Submitted", "Pending", "Not Submitted", "Rate %", "Last Submission", "Status", "Action"].map((h) => <th key={h} className="text-left p-2 whitespace-nowrap">{h}</th>)}</tr></thead>
                <tbody>
                  {lecturerSubmission.map((l) => (
                    <tr key={l.id} className="border-b">
                      <td className="p-2 font-mono text-xs">{l.id}</td><td className="p-2 font-medium whitespace-nowrap">{l.name}</td><td className="p-2 text-xs">{l.department}</td>
                      <td className="p-2">{l.assigned}</td><td className="p-2">{l.total}</td><td className="p-2 text-success font-medium">{l.submitted}</td><td className="p-2 text-warning-foreground">{l.pending}</td><td className="p-2 text-destructive">{l.notSubmitted}</td>
                      <td className="p-2 font-bold">{l.rate}%</td><td className="p-2 text-xs">{l.last}</td>
                      <td className="p-2"><StatusBadge status={l.status as any} /></td>
                      <td className="p-2"><div className="flex gap-1">
                        <Button size="sm" variant="outline" className="h-7 text-xs" onClick={() => setDetailsDlg({ title: `Sessions - ${l.name}`, rows: [["Lecturer", l.name], ["Department", l.department], ["Assigned Classes", String(l.assigned)], ["Total Sessions", String(l.total)], ["Submitted", String(l.submitted)], ["Pending", String(l.pending)], ["Not Submitted", String(l.notSubmitted)], ["Submission Rate", `${l.rate}%`], ["Last Submission", l.last]] })}>Sessions</Button>
                        <Button size="sm" variant="ghost" className="h-7 w-7 p-0" title="Contact" onClick={() => openContact(l.name, `${l.id.toLowerCase()}@tvetmara.edu.my`, "lecturer")}><Mail className="h-3.5 w-3.5" /></Button>
                        <Button size="sm" variant="ghost" className="h-7 w-7 p-0" title="Send Reminder" onClick={() => setReminderConfirm({ name: l.name, email: `${l.id.toLowerCase()}@tvetmara.edu.my` })}><Send className="h-3.5 w-3.5" /></Button>
                      </div></td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </CardContent></Card>
          </TabsContent>
        )}

        <TabsContent value="trend">
          <Card><CardContent className="p-4 h-72">
            <ResponsiveContainer><LineChart data={trendData}>
              <CartesianGrid strokeDasharray="3 3" opacity={0.3} /><XAxis dataKey="week" fontSize={11} /><YAxis fontSize={11} /><Tooltip /><Legend />
              <Line type="monotone" dataKey="attendance" stroke="oklch(0.50 0.18 255)" strokeWidth={2.5} />
              <Line type="monotone" dataKey="absent" stroke="oklch(0.60 0.22 25)" strokeWidth={2} />
              <Line type="monotone" dataKey="late" stroke="oklch(0.78 0.16 85)" strokeWidth={2} />
            </LineChart></ResponsiveContainer>
          </CardContent></Card>
          <Card className="mt-3"><CardContent className="p-0 overflow-x-auto">
            <table className="w-full text-sm">
              <thead className="text-xs text-muted-foreground border-b bg-muted/40"><tr>{["Week", "Total Sessions", "Avg Att %", "Total Absent", "Total Late", "Below 80%"].map((h) => <th key={h} className="text-left p-2">{h}</th>)}</tr></thead>
              <tbody>{trendData.map((t) => <tr key={t.week} className="border-b"><td className="p-2 font-medium">{t.week}</td><td className="p-2">{t.sessions}</td><td className="p-2 font-bold">{t.attendance}%</td><td className="p-2">{t.absent}</td><td className="p-2">{t.late}</td><td className="p-2">{t.below}</td></tr>)}</tbody>
            </table>
          </CardContent></Card>
        </TabsContent>

        <TabsContent value="below"><Card><CardContent className="p-0 overflow-x-auto">
          <table className="w-full text-sm">
            <thead className="text-xs text-muted-foreground border-b bg-muted/40"><tr>{["Student ID", "Name", "Program", "Section", "Subject", "Lecturer", "Att %", "Absent", "Last Absent", "Risk", "Suggested Action", "Action"].map((h) => <th key={h} className="text-left p-2 whitespace-nowrap">{h}</th>)}</tr></thead>
            <tbody>
              {below.slice(0, 15).map((s, i) => {
                const risk = s.attendance < 60 ? "Critical" : "Warning";
                const suggested = s.attendance < 60 ? "Create Discipline Report" : "Send Warning";
                return (
                  <tr key={s.id} className="border-b">
                    <td className="p-2 font-mono text-xs">{s.id}</td><td className="p-2 font-medium whitespace-nowrap">{s.name}</td><td className="p-2 text-xs">{s.program}</td><td className="p-2">{s.section}</td><td className="p-2 text-xs">EE101</td><td className="p-2 text-xs">Encik Ahmad bin Ismail</td>
                    <td className="p-2 font-bold text-destructive">{s.attendance}%</td><td className="p-2">{Math.floor((100 - s.attendance) / 4)}</td><td className="p-2 text-xs">2026-04-{20 + (i % 9)}</td>
                    <td className="p-2"><StatusBadge status={risk as any} /></td>
                    <td className="p-2 text-xs">{suggested}</td>
                    <td className="p-2"><div className="flex gap-1">
                      <Button size="sm" variant="outline" className="h-7 text-xs" onClick={() => openContact(s.name, s.email, "warning")}><AlertTriangle className="h-3 w-3 mr-1" />Warn</Button>
                      <Button size="sm" variant="ghost" className="h-7 text-xs" onClick={() => setDiscDlg({ studentId: s.id, studentName: s.name })}><FilePlus className="h-3 w-3 mr-1" />Report</Button>
                      <Button size="sm" variant="ghost" className="h-7 w-7 p-0" title="History" onClick={() => setHistoryDlg({ name: s.name })}><History className="h-3.5 w-3.5" /></Button>
                    </div></td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </CardContent></Card></TabsContent>

        <TabsContent value="discipline">
          <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-6 gap-3 mb-3">
            <StatCard label="Total Reports" value={disciplineReports.length} />
            <StatCard label="Frequent Absence" value={disciplineReports.filter((d) => d.issueType === "Frequent Absence").length} tone="destructive" />
            <StatCard label="Late Cases" value={disciplineReports.filter((d) => d.issueType === "Late to Class").length} tone="warning" />
            <StatCard label="Misconduct" value={disciplineReports.filter((d) => d.issueType === "Misconduct").length} tone="warning" />
            <StatCard label="Under Review" value={disciplineReports.filter((d) => d.status === "Under Review").length} tone="info" />
            <StatCard label="Resolved" value={disciplineReports.filter((d) => d.status === "Resolved").length} tone="success" />
          </div>
          <Card><CardContent className="p-0 overflow-x-auto">
            <table className="w-full text-sm">
              <thead className="text-xs text-muted-foreground border-b bg-muted/40"><tr>{["Report ID", "Student", "Section", "Subject", "Lecturer", "Issue", "Severity", "Status", "Action"].map((h) => <th key={h} className="text-left p-2 whitespace-nowrap">{h}</th>)}</tr></thead>
              <tbody>
                {disciplineReports.map((d) => (
                  <tr key={d.id} className="border-b">
                    <td className="p-2 font-mono text-xs">{d.id}</td><td className="p-2 font-medium">{d.studentName}</td><td className="p-2">{d.section}</td><td className="p-2 text-xs">{d.subjectCode}</td><td className="p-2 text-xs">{d.lecturerName}</td>
                    <td className="p-2 text-xs">{d.issueType}</td><td className="p-2"><StatusBadge status={d.severity as any} /></td><td className="p-2"><StatusBadge status={d.status as any} /></td>
                    <td className="p-2"><div className="flex gap-1">
                      <Button size="sm" variant="ghost" className="h-7 w-7 p-0" title="View Report" onClick={() => setDetailsDlg({ title: `Report ${d.id}`, rows: [["Report ID", d.id], ["Student", d.studentName], ["Section", d.section], ["Subject", d.subjectCode], ["Lecturer", d.lecturerName], ["Issue Type", d.issueType], ["Severity", d.severity], ["Status", d.status], ["Description", d.description || "-"]] })}><Eye className="h-3.5 w-3.5" /></Button>
                      <Button size="sm" variant="ghost" className="h-7 w-7 p-0" title="Update Status" onClick={() => setStatusDlg({ id: d.id, current: d.status })}><AlertTriangle className="h-3.5 w-3.5" /></Button>
                      <Button size="sm" variant="ghost" className="h-7 w-7 p-0" title="Add Follow-Up Note" onClick={() => setNoteDlg({ id: d.id })}><StickyNote className="h-3.5 w-3.5" /></Button>
                    </div></td>
                  </tr>
                ))}
              </tbody>
            </table>
          </CardContent></Card>
        </TabsContent>
      </Tabs>

      <div className="grid lg:grid-cols-2 gap-4">
        <Card><CardHeader><CardTitle className="text-base">Status Distribution</CardTitle></CardHeader><CardContent className="h-64">
          <ResponsiveContainer><PieChart><Pie data={dist} dataKey="value" nameKey="name" outerRadius={80} label>{dist.map((d, i) => <Cell key={i} fill={d.color} />)}</Pie><Tooltip /><Legend wrapperStyle={{ fontSize: 11 }} /></PieChart></ResponsiveContainer>
        </CardContent></Card>
        <Card><CardHeader><CardTitle className="text-base">Average Attendance by Class</CardTitle></CardHeader><CardContent className="h-64">
          <ResponsiveContainer><BarChart data={sectionData}><CartesianGrid strokeDasharray="3 3" opacity={0.3} /><XAxis dataKey="section" fontSize={11} /><YAxis fontSize={11} domain={[0, 100]} /><Tooltip /><Bar dataKey="attendance" fill="oklch(0.62 0.16 155)" radius={[4, 4, 0, 0]} /></BarChart></ResponsiveContainer>
        </CardContent></Card>
        <Card><CardHeader><CardTitle className="text-base">Students Below 80% by Program</CardTitle></CardHeader><CardContent className="h-64">
          <ResponsiveContainer><BarChart data={programBelowData}><CartesianGrid strokeDasharray="3 3" opacity={0.3} /><XAxis dataKey="program" fontSize={10} /><YAxis fontSize={11} /><Tooltip /><Bar dataKey="count" fill="oklch(0.60 0.22 25)" radius={[4, 4, 0, 0]} /></BarChart></ResponsiveContainer>
        </CardContent></Card>
        <Card><CardHeader><CardTitle className="text-base">Lecturer Submission Rate</CardTitle></CardHeader><CardContent className="h-64">
          <ResponsiveContainer><BarChart data={lecturerChart}><CartesianGrid strokeDasharray="3 3" opacity={0.3} /><XAxis dataKey="name" fontSize={10} /><YAxis fontSize={11} domain={[0, 100]} /><Tooltip /><Bar dataKey="rate" fill="oklch(0.55 0.20 295)" radius={[4, 4, 0, 0]} /></BarChart></ResponsiveContainer>
        </CardContent></Card>
      </div>

      {/* Email composer */}
      <Dialog open={!!emailDlg} onOpenChange={(o) => !o && setEmailDlg(null)}>
        <DialogContent>
          <DialogHeader><DialogTitle>Compose Email</DialogTitle></DialogHeader>
          {emailDlg && (
            <div className="space-y-3">
              <div><Label className="text-xs">To</Label><Input className="h-9 mt-1" defaultValue={emailDlg.to} /></div>
              <div><Label className="text-xs">Subject</Label><Input className="h-9 mt-1" defaultValue={emailDlg.subject} /></div>
              <div><Label className="text-xs">Message</Label><Textarea rows={7} defaultValue={emailDlg.body} /></div>
              <DialogFooter>
                <Button variant="outline" onClick={() => setEmailDlg(null)}>Cancel</Button>
                <Button onClick={() => { toast.success("Email sent successfully."); setEmailDlg(null); }}>Send</Button>
              </DialogFooter>
            </div>
          )}
        </DialogContent>
      </Dialog>

      {/* Send reminder confirm */}
      <Dialog open={!!reminderConfirm} onOpenChange={(o) => !o && setReminderConfirm(null)}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Send Submission Reminder</DialogTitle>
            <DialogDescription>Send an attendance submission reminder email to {reminderConfirm?.name}?</DialogDescription>
          </DialogHeader>
          <DialogFooter>
            <Button variant="outline" onClick={() => setReminderConfirm(null)}>Cancel</Button>
            <Button onClick={() => { toast.success("Reminder email sent successfully."); setReminderConfirm(null); }}>Send Reminder</Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Update status */}
      <Dialog open={!!statusDlg} onOpenChange={(o) => !o && setStatusDlg(null)}>
        <DialogContent>
          <DialogHeader><DialogTitle>Update Discipline Status</DialogTitle></DialogHeader>
          {statusDlg && (
            <div className="space-y-3">
              <div><Label className="text-xs">Report ID</Label><Input className="h-9 mt-1" value={statusDlg.id} readOnly /></div>
              <div><Label className="text-xs">New Status</Label>
                <Select defaultValue={statusDlg.current}>
                  <SelectTrigger className="h-9 mt-1"><SelectValue /></SelectTrigger>
                  <SelectContent>
                    {["New", "Under Review", "Action Taken", "Resolved", "Closed"].map((s) => <SelectItem key={s} value={s}>{s}</SelectItem>)}
                  </SelectContent>
                </Select>
              </div>
              <DialogFooter>
                <Button variant="outline" onClick={() => setStatusDlg(null)}>Cancel</Button>
                <Button onClick={() => { toast.success("Status updated."); setStatusDlg(null); }}>Update</Button>
              </DialogFooter>
            </div>
          )}
        </DialogContent>
      </Dialog>

      {/* Follow-up note */}
      <Dialog open={!!noteDlg} onOpenChange={(o) => !o && setNoteDlg(null)}>
        <DialogContent>
          <DialogHeader><DialogTitle>Add Follow-Up Note</DialogTitle></DialogHeader>
          {noteDlg && (
            <div className="space-y-3">
              <div><Label className="text-xs">Report ID</Label><Input className="h-9 mt-1" value={noteDlg.id} readOnly /></div>
              <div><Label className="text-xs">Note</Label><Textarea rows={5} placeholder="Enter follow-up note..." /></div>
              <DialogFooter>
                <Button variant="outline" onClick={() => setNoteDlg(null)}>Cancel</Button>
                <Button onClick={() => { toast.success("Follow-up note saved."); setNoteDlg(null); }}>Save Note</Button>
              </DialogFooter>
            </div>
          )}
        </DialogContent>
      </Dialog>

      {/* Discipline report from below 80% */}
      <Dialog open={!!discDlg} onOpenChange={(o) => !o && setDiscDlg(null)}>
        <DialogContent>
          <DialogHeader><DialogTitle>Create Discipline Report</DialogTitle></DialogHeader>
          {discDlg && (
            <div className="space-y-3">
              <div className="grid grid-cols-2 gap-2">
                <div><Label className="text-xs">Student ID</Label><Input className="h-9 mt-1" value={discDlg.studentId} readOnly /></div>
                <div><Label className="text-xs">Student Name</Label><Input className="h-9 mt-1" value={discDlg.studentName} readOnly /></div>
              </div>
              <div><Label className="text-xs">Issue Type</Label>
                <Select defaultValue="Frequent Absence">
                  <SelectTrigger className="h-9 mt-1"><SelectValue /></SelectTrigger>
                  <SelectContent>
                    {["Frequent Absence", "Late to Class", "Misconduct", "Skipping Class", "Other"].map((s) => <SelectItem key={s} value={s}>{s}</SelectItem>)}
                  </SelectContent>
                </Select>
              </div>
              <div><Label className="text-xs">Severity</Label>
                <Select defaultValue="High">
                  <SelectTrigger className="h-9 mt-1"><SelectValue /></SelectTrigger>
                  <SelectContent>{["Low", "Medium", "High"].map((s) => <SelectItem key={s} value={s}>{s}</SelectItem>)}</SelectContent>
                </Select>
              </div>
              <div><Label className="text-xs">Description</Label><Textarea rows={4} defaultValue={`Student ${discDlg.studentName} has attendance below the required 80% threshold.`} /></div>
              <DialogFooter>
                <Button variant="outline" onClick={() => setDiscDlg(null)}>Cancel</Button>
                <Button onClick={() => { toast.success("Discipline report created."); setDiscDlg(null); }}>Submit Report</Button>
              </DialogFooter>
            </div>
          )}
        </DialogContent>
      </Dialog>

      {/* Generic details */}
      <Dialog open={!!detailsDlg} onOpenChange={(o) => !o && setDetailsDlg(null)}>
        <DialogContent>
          <DialogHeader><DialogTitle>{detailsDlg?.title}</DialogTitle></DialogHeader>
          {detailsDlg && (
            <div className="space-y-1.5 text-sm">
              {detailsDlg.rows.map(([k, v]) => (
                <div key={k} className="flex justify-between border-b py-1.5"><span className="text-muted-foreground">{k}</span><span className="font-medium text-right">{v}</span></div>
              ))}
            </div>
          )}
          <DialogFooter><Button variant="outline" onClick={() => setDetailsDlg(null)}>Close</Button></DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Absence history */}
      <Dialog open={!!historyDlg} onOpenChange={(o) => !o && setHistoryDlg(null)}>
        <DialogContent>
          <DialogHeader><DialogTitle>Absence History - {historyDlg?.name}</DialogTitle></DialogHeader>
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead className="text-xs text-muted-foreground border-b bg-muted/40"><tr>{["Date", "Subject", "Status", "Remark"].map((h) => <th key={h} className="text-left p-2">{h}</th>)}</tr></thead>
              <tbody>
                {[
                  ["2026-04-22", "EE101", "Absent", "No medical certificate"],
                  ["2026-04-15", "EE102", "MC", "Medical certificate received"],
                  ["2026-04-08", "EE101", "Late", "Arrived 20 min late"],
                  ["2026-03-30", "EE103", "Absent", "Unexcused"],
                  ["2026-03-22", "EE104", "CK", "Co-curriculum activity"],
                ].map(([d, s, st, r]) => (
                  <tr key={d} className="border-b"><td className="p-2 text-xs">{d}</td><td className="p-2 text-xs">{s}</td><td className="p-2"><StatusBadge status={st as any} /></td><td className="p-2 text-xs">{r}</td></tr>
                ))}
              </tbody>
            </table>
          </div>
          <DialogFooter><Button variant="outline" onClick={() => setHistoryDlg(null)}>Close</Button></DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Print preview */}
      <Dialog open={printOpen} onOpenChange={setPrintOpen}>
        <DialogContent>
          <DialogHeader><DialogTitle>Print Preview</DialogTitle><DialogDescription>TVETMARA Johor Bahru - Attendance Report</DialogDescription></DialogHeader>
          <div className="border rounded-md p-4 bg-muted/20 text-sm space-y-2 max-h-80 overflow-auto">
            <div className="font-bold text-center">TVETMARA JOHOR BAHRU</div>
            <div className="text-center text-xs text-muted-foreground">Student Attendance Report — {filters.from} to {filters.to}</div>
            <div className="border-t pt-2 grid grid-cols-2 gap-1 text-xs">
              <div>Total Students: {students.length}</div><div>Avg Attendance: {avgAtt}%</div>
              <div>Below 80%: {below.length}</div><div>Critical Cases: {critical.length}</div>
              <div>Total Sessions: {1432 - applied * 4}</div><div>Pending Submissions: {lecturerSubmission.reduce((a, l) => a + l.pending, 0)}</div>
            </div>
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setPrintOpen(false)}>Cancel</Button>
            <Button onClick={() => { window.print(); setPrintOpen(false); }}>Print</Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}
