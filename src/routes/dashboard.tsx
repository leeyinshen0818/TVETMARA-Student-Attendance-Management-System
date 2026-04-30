import { createFileRoute, Link } from "@tanstack/react-router";
import { Users, GraduationCap, ClipboardCheck, Clock, Percent, AlertTriangle, CalendarPlus, CheckCircle2, BookOpen, AlertCircle, FileSearch } from "lucide-react";
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { PageHeader } from "@/components/page-header";
import { StatCard } from "@/components/stat-card";
import { StatusBadge } from "@/components/status-badge";
import { useApp } from "@/lib/store";
import { Bar, BarChart, CartesianGrid, Cell, Legend, Line, LineChart, Pie, PieChart, ResponsiveContainer, Tooltip, XAxis, YAxis } from "recharts";

export const Route = createFileRoute("/dashboard")({
  component: Dashboard,
});

function Dashboard() {
  const { students, lecturers, timetable, attendance, disciplineReports, bookings, settings, currentUser } = useApp();

  const today = "2026-04-29";
  const role = currentUser?.role ?? "admin";

  // Scope data per role
  const scopedTimetable = role === "lecturer"
    ? timetable.filter((t) => t.lecturerId === currentUser?.id)
    : timetable;
  const scopedSections = role === "lecturer"
    ? Array.from(new Set(scopedTimetable.map((t) => t.section)))
    : null;
  const scopedStudents = scopedSections
    ? students.filter((s) => scopedSections.includes(s.section))
    : students;
  const scopedDiscipline = role === "lecturer"
    ? disciplineReports.filter((d) => d.lecturer === currentUser?.name)
    : disciplineReports;
  const scopedBookings = role === "lecturer"
    ? bookings.filter((b) => b.lecturerId === currentUser?.id)
    : bookings;

  const todays = scopedTimetable.filter((t) => t.date === today);
  const completedToday = todays.filter((t) => t.status === "Attendance Completed").length;
  const pendingToday = todays.length - completedToday;
  const avgAtt = scopedStudents.length
    ? Math.round(scopedStudents.reduce((a, s) => a + s.attendance, 0) / scopedStudents.length)
    : 0;
  const below80 = scopedStudents.filter((s) => s.attendance < settings.threshold).length;
  const pendingDisc = scopedDiscipline.filter((d) => d.status === "New" || d.status === "Under Review").length;
  const pendingBookings = scopedBookings.filter((b) => b.status === "Pending").length;
  const approvedBookings = scopedBookings.filter((b) => b.status === "Approved").length;
  const absentToday = role === "lecturer"
    ? todays.reduce((sum, t) => sum + (attendance[t.id]?.filter((r) => r.status === "Absent").length ?? 0), 0)
    : 0;

  const trendData = Array.from({ length: 8 }, (_, i) => ({ week: `W${i + 1}`, attendance: 78 + ((i * 13) % 18) }));
  const distData = [
    { name: "Present", value: 72, color: "var(--success)" },
    { name: "Absent", value: 12, color: "var(--destructive)" },
    { name: "Late", value: 8, color: "var(--warning)" },
    { name: "MC", value: 5, color: "var(--info)" },
    { name: "CK", value: 3, color: "var(--replacement)" },
  ];
  const sectionData = ["ELI-1A", "ELI-1B", "AUTO-2A", "WELD-1A", "MECH-2B", "AC-1C"].map((sec) => {
    const ss = students.filter((s) => s.section === sec);
    const avg = ss.length ? Math.round(ss.reduce((a, s) => a + s.attendance, 0) / ss.length) : 0;
    return { section: sec, attendance: avg };
  });
  const lowest5 = [...scopedStudents].sort((a, b) => a.attendance - b.attendance).slice(0, 5);

  const subtitle =
    role === "admin"
      ? "System-wide overview · Admin control panel"
      : "Your classes, attendance & discipline activity today";

  return (
    <div className="space-y-6">
      <PageHeader
        title={`Welcome back, ${currentUser?.name.split(" ")[0]}`}
        subtitle={subtitle}
      />

      <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-3 sm:gap-4">
        {role === "admin" && (
          <>
            <StatCard label="Total Students" value={students.length} icon={GraduationCap} />
            <StatCard label="Total Lecturers" value={lecturers.length} icon={Users} tone="info" />
            <StatCard label="Classes Today" value={todays.length} icon={BookOpen} tone="info" />
            <StatCard label="Pending Timetable Issues" value={2} icon={AlertTriangle} tone="warning" />
            <StatCard label="Pending Booking Approvals" value={pendingBookings} icon={CalendarPlus} tone="warning" />
            <StatCard label="Attendance Not Submitted" value={pendingToday} icon={Clock} tone="warning" />
            <StatCard label="Students Below 80%" value={below80} icon={AlertCircle} tone="destructive" />
            <StatCard label="Approved Replacement" value={approvedBookings} icon={CheckCircle2} tone="replacement" />
          </>
        )}
        {role === "lecturer" && (
          <>
            <StatCard label="Today's Classes" value={todays.length} icon={BookOpen} tone="info" />
            <StatCard label="Attendance Pending" value={pendingToday} icon={Clock} tone="warning" />
            <StatCard label="Attendance Completed" value={completedToday} icon={ClipboardCheck} tone="success" />
            <StatCard label="Students Absent Today" value={absentToday} icon={AlertCircle} tone="destructive" />
            <StatCard label="My Students" value={scopedStudents.length} icon={GraduationCap} />
            <StatCard label="Below 80% (My Classes)" value={below80} icon={AlertTriangle} tone="destructive" />
            <StatCard label="My Booking Requests" value={scopedBookings.length} hint={`${pendingBookings} pending`} icon={CalendarPlus} tone="warning" />
            <StatCard label="My Discipline Reports" value={scopedDiscipline.length} icon={AlertCircle} tone="info" />
          </>
        )}
      </div>

      <div className="grid lg:grid-cols-3 gap-4">
        <Card className="lg:col-span-2">
          <CardHeader>
            <CardTitle className="text-base">Today's Class Overview</CardTitle>
            <CardDescription>Wednesday, 29 April 2026</CardDescription>
          </CardHeader>
          <CardContent className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead className="text-xs text-muted-foreground border-b">
                <tr>
                  <th className="text-left py-2 px-2">Time</th>
                  <th className="text-left py-2 px-2">Subject</th>
                  <th className="text-left py-2 px-2">Lecturer</th>
                  <th className="text-left py-2 px-2">Section</th>
                  <th className="text-left py-2 px-2">Room</th>
                  <th className="text-left py-2 px-2">Status</th>
                  <th className="text-left py-2 px-2">Action</th>
                </tr>
              </thead>
              <tbody>
                {todays.slice(0, 6).map((t) => (
                  <tr key={t.id} className="border-b last:border-0">
                    <td className="py-2 px-2 font-medium">{t.startTime}</td>
                    <td className="py-2 px-2">{t.subjectName}</td>
                    <td className="py-2 px-2 text-muted-foreground">{t.lecturerName}</td>
                    <td className="py-2 px-2">{t.section}</td>
                    <td className="py-2 px-2 text-muted-foreground">{t.room}</td>
                    <td className="py-2 px-2"><StatusBadge status={t.status} /></td>
                    <td className="py-2 px-2">
                      <Button asChild size="sm" variant="outline" className="h-7 text-xs">
                        <Link to="/m1" search={{ slot: t.id }}>Open</Link>
                      </Button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle className="text-base">Attendance Alerts</CardTitle>
            <CardDescription>Items needing attention</CardDescription>
          </CardHeader>
          <CardContent className="space-y-2">
            <AlertRow tone="destructive" title={`${below80} students below 80%`} desc="Review attendance & follow up" />
            <AlertRow tone="warning" title={`${pendingToday} classes attendance not submitted`} desc="Lecturers to submit today" />
            <AlertRow tone="warning" title="6 frequent absence warnings" desc="Repeated absent without MC" />
            <AlertRow tone="info" title={`${pendingDisc} discipline cases pending`} desc="Awaiting follow-up action" />
          </CardContent>
        </Card>
      </div>

      <div className="grid lg:grid-cols-2 gap-4">
        <Card>
          <CardHeader><CardTitle className="text-base">Attendance Trend (Weekly)</CardTitle></CardHeader>
          <CardContent className="h-64">
            <ResponsiveContainer width="100%" height="100%">
              <LineChart data={trendData}>
                <CartesianGrid strokeDasharray="3 3" opacity={0.3} />
                <XAxis dataKey="week" fontSize={11} />
                <YAxis fontSize={11} domain={[60, 100]} />
                <Tooltip />
                <Line type="monotone" dataKey="attendance" stroke="oklch(0.50 0.18 255)" strokeWidth={2.5} />
              </LineChart>
            </ResponsiveContainer>
          </CardContent>
        </Card>

        <Card>
          <CardHeader><CardTitle className="text-base">Status Distribution</CardTitle></CardHeader>
          <CardContent className="h-64">
            <ResponsiveContainer width="100%" height="100%">
              <PieChart>
                <Pie data={distData} dataKey="value" nameKey="name" outerRadius={80} label>
                  {distData.map((d, i) => <Cell key={i} fill={d.color} />)}
                </Pie>
                <Tooltip />
                <Legend wrapperStyle={{ fontSize: 11 }} />
              </PieChart>
            </ResponsiveContainer>
          </CardContent>
        </Card>

        <Card>
          <CardHeader><CardTitle className="text-base">Attendance by Class</CardTitle></CardHeader>
          <CardContent className="h-64">
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={sectionData}>
                <CartesianGrid strokeDasharray="3 3" opacity={0.3} />
                <XAxis dataKey="section" fontSize={11} />
                <YAxis fontSize={11} domain={[0, 100]} />
                <Tooltip />
                <Bar dataKey="attendance" fill="oklch(0.62 0.16 155)" radius={[4, 4, 0, 0]} />
              </BarChart>
            </ResponsiveContainer>
          </CardContent>
        </Card>

        <Card>
          <CardHeader><CardTitle className="text-base">Top 5 Lowest Attendance</CardTitle></CardHeader>
          <CardContent>
            <div className="space-y-2">
              {lowest5.map((s) => (
                <div key={s.id} className="flex items-center justify-between text-sm border-b pb-2 last:border-0">
                  <div>
                    <div className="font-medium">{s.name}</div>
                    <div className="text-xs text-muted-foreground">{s.id} · {s.section}</div>
                  </div>
                  <StatusBadge status={s.attendance < 80 ? "Critical" : "Warning"} />
                  <div className="font-bold text-destructive">{s.attendance}%</div>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  );
}

function AlertRow({ tone, title, desc }: { tone: "destructive" | "warning" | "info"; title: string; desc: string }) {
  const cls = tone === "destructive" ? "border-l-destructive bg-destructive/5" : tone === "warning" ? "border-l-warning bg-warning/10" : "border-l-info bg-info/5";
  return (
    <div className={`border-l-4 ${cls} rounded p-2.5`}>
      <div className="text-sm font-semibold">{title}</div>
      <div className="text-xs text-muted-foreground">{desc}</div>
    </div>
  );
}