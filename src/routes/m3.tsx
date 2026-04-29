import * as React from "react";
import { createFileRoute } from "@tanstack/react-router";
import { toast } from "sonner";
import { Download, Printer, Mail, FileText } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Tabs, TabsList, TabsTrigger, TabsContent } from "@/components/ui/tabs";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Dialog, DialogContent, DialogFooter, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Textarea } from "@/components/ui/textarea";
import { PageHeader } from "@/components/page-header";
import { StatCard } from "@/components/stat-card";
import { StatusBadge } from "@/components/status-badge";
import { useApp } from "@/lib/store";
import { Bar, BarChart, CartesianGrid, Cell, Legend, Line, LineChart, Pie, PieChart, ResponsiveContainer, Tooltip, XAxis, YAxis } from "recharts";

export const Route = createFileRoute("/m3")({ component: M3 });

function M3() {
  const { students, timetable, disciplineReports, settings } = useApp();
  const [emailOpen, setEmailOpen] = React.useState<{ name: string; email: string; subject: string } | null>(null);

  const totalClasses = timetable.length;
  const avgAtt = Math.round(students.reduce((a, s) => a + s.attendance, 0) / students.length);
  const below = students.filter((s) => s.attendance < settings.threshold);

  const trendData = Array.from({ length: 12 }, (_, i) => ({ week: `W${i + 1}`, attendance: 75 + ((i * 11) % 22), absent: 5 + ((i * 3) % 8), late: 2 + (i % 5) }));
  const dist = [
    { name: "Present", value: 72, color: "var(--success)" },
    { name: "Absent", value: 12, color: "var(--destructive)" },
    { name: "Late", value: 8, color: "var(--warning)" },
    { name: "MC", value: 5, color: "var(--info)" },
    { name: "CK", value: 3, color: "var(--replacement)" },
  ];
  const sectionData = ["ELI-1A", "ELI-1B", "AUTO-2A", "WELD-1A", "MECH-2B", "AC-1C"].map((sec) => {
    const ss = students.filter((s) => s.section === sec);
    return { section: sec, attendance: ss.length ? Math.round(ss.reduce((a, s) => a + s.attendance, 0) / ss.length) : 0 };
  });
  const discData = ["Frequent Absence", "Late to Class", "Misconduct", "Skipping Class", "Other"].map((t) => ({ type: t, count: disciplineReports.filter((d) => d.issueType === t).length + ((t.length) % 4) }));

  return (
    <div className="space-y-5">
      <PageHeader
        title="M3: Reporting Module / Modul Laporan"
        subtitle="Attendance statistics, summaries, trends and official reports."
        actions={
          <>
            <Button variant="outline" size="sm" onClick={() => toast.success("PDF exported")}><FileText className="h-4 w-4 mr-1.5" /> PDF</Button>
            <Button variant="outline" size="sm" onClick={() => toast.success("Excel exported")}><Download className="h-4 w-4 mr-1.5" /> Excel</Button>
            <Button variant="outline" size="sm" onClick={() => toast.success("Print prepared")}><Printer className="h-4 w-4 mr-1.5" /> Print</Button>
            <Button variant="outline" size="sm" onClick={() => toast.success("Report emailed")}><Mail className="h-4 w-4 mr-1.5" /> Email</Button>
          </>
        }
      />

      <Card>
        <CardHeader className="pb-3"><CardTitle className="text-sm">Filters</CardTitle></CardHeader>
        <CardContent className="grid grid-cols-2 md:grid-cols-4 lg:grid-cols-6 gap-3">
          {["Program", "Course", "Subject", "Lecturer", "Section", "Semester", "Week", "Status"].map((f) => (
            <div key={f}><Label className="text-xs">{f}</Label><Select><SelectTrigger className="h-9 mt-1"><SelectValue placeholder="All" /></SelectTrigger><SelectContent><SelectItem value="all">All</SelectItem></SelectContent></Select></div>
          ))}
          <div><Label className="text-xs">From</Label><Input className="h-9 mt-1" type="date" defaultValue="2026-01-01" /></div>
          <div><Label className="text-xs">To</Label><Input className="h-9 mt-1" type="date" defaultValue="2026-04-29" /></div>
        </CardContent>
      </Card>

      <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-5 gap-3">
        <StatCard label="Total Students" value={students.length} />
        <StatCard label="Total Classes" value={totalClasses} tone="info" />
        <StatCard label="Avg Attendance" value={`${avgAtt}%`} tone="success" />
        <StatCard label="Total Present" value="1,248" tone="success" />
        <StatCard label="Total Absent" value="186" tone="destructive" />
        <StatCard label="Total MC" value="64" tone="info" />
        <StatCard label="Total CK" value="32" tone="info" />
        <StatCard label="Total Late" value="92" tone="warning" />
        <StatCard label="Below 80%" value={below.length} tone="destructive" />
        <StatCard label="Not Submitted" value={timetable.filter((t) => t.status === "Attendance Not Taken").length} tone="warning" />
      </div>

      <Tabs defaultValue="student">
        <TabsList className="flex flex-wrap h-auto">
          <TabsTrigger value="student">Student</TabsTrigger>
          <TabsTrigger value="class">Class</TabsTrigger>
          <TabsTrigger value="subject">Subject</TabsTrigger>
          <TabsTrigger value="trend">Weekly Trend</TabsTrigger>
          <TabsTrigger value="below">Below 80%</TabsTrigger>
          <TabsTrigger value="discipline">Discipline</TabsTrigger>
        </TabsList>

        <TabsContent value="student"><Card><CardContent className="p-0 overflow-x-auto">
          <table className="w-full text-sm">
            <thead className="text-xs text-muted-foreground border-b bg-muted/40"><tr>
              {["Student ID", "Name", "Program", "Section", "Subject", "Present", "Absent", "MC", "CK", "Late", "Att %", "Status"].map((h) => <th key={h} className="text-left p-2">{h}</th>)}
            </tr></thead>
            <tbody>
              {students.slice(0, 15).map((s, i) => {
                const pres = 30 - ((i * 3) % 10), abs = (i * 2) % 6, mc = i % 3, ck = i % 2, late = (i * 5) % 4;
                const status = s.attendance >= 90 ? "Good" : s.attendance >= 80 ? "Warning" : "Critical";
                return (
                  <tr key={s.id} className="border-b last:border-0">
                    <td className="p-2 font-mono text-xs">{s.id}</td><td className="p-2 font-medium">{s.name}</td><td className="p-2 text-xs">{s.program}</td><td className="p-2">{s.section}</td><td className="p-2 text-xs">EE101</td>
                    <td className="p-2">{pres}</td><td className="p-2">{abs}</td><td className="p-2">{mc}</td><td className="p-2">{ck}</td><td className="p-2">{late}</td>
                    <td className="p-2 font-bold">{s.attendance}%</td><td className="p-2"><StatusBadge status={status} /></td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </CardContent></Card></TabsContent>

        <TabsContent value="class"><Card><CardContent className="p-0 overflow-x-auto">
          <table className="w-full text-sm">
            <thead className="text-xs text-muted-foreground border-b bg-muted/40"><tr>{["Section", "Program", "Subject", "Lecturer", "Total Students", "Avg Att", "Below 80%", "Status"].map((h) => <th key={h} className="text-left p-2">{h}</th>)}</tr></thead>
            <tbody>
              {sectionData.map((sd) => {
                const ss = students.filter((s) => s.section === sd.section);
                return (
                  <tr key={sd.section} className="border-b">
                    <td className="p-2 font-medium">{sd.section}</td><td className="p-2 text-xs">{ss[0]?.program}</td><td className="p-2 text-xs">Various</td><td className="p-2 text-xs">Multiple</td>
                    <td className="p-2">{ss.length}</td><td className="p-2 font-bold">{sd.attendance}%</td><td className="p-2">{ss.filter((s) => s.attendance < 80).length}</td>
                    <td className="p-2"><StatusBadge status="Completed" /></td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </CardContent></Card></TabsContent>

        <TabsContent value="subject"><Card><CardContent className="p-0 overflow-x-auto">
          <table className="w-full text-sm">
            <thead className="text-xs text-muted-foreground border-b bg-muted/40"><tr>{["Code", "Subject", "Lecturer", "Section", "Sessions", "Avg Att", "Lowest Student", "Status"].map((h) => <th key={h} className="text-left p-2">{h}</th>)}</tr></thead>
            <tbody>
              {timetable.slice(0, 8).map((t, i) => (
                <tr key={t.id} className="border-b">
                  <td className="p-2 font-mono text-xs">{t.subjectCode}</td><td className="p-2">{t.subjectName}</td><td className="p-2 text-xs">{t.lecturerName}</td><td className="p-2">{t.section}</td>
                  <td className="p-2">{18 - i}</td><td className="p-2 font-bold">{82 + (i % 10)}%</td><td className="p-2 text-xs">{students[i]?.name}</td><td className="p-2"><StatusBadge status={i % 3 ? "Good" : "Warning"} /></td>
                </tr>
              ))}
            </tbody>
          </table>
        </CardContent></Card></TabsContent>

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
              <thead className="text-xs text-muted-foreground border-b bg-muted/40"><tr>{["Week", "Total Classes", "Avg Att", "Absent", "Late"].map((h) => <th key={h} className="text-left p-2">{h}</th>)}</tr></thead>
              <tbody>{trendData.map((t) => <tr key={t.week} className="border-b"><td className="p-2 font-medium">{t.week}</td><td className="p-2">{18 + (parseInt(t.week.slice(1)) % 5)}</td><td className="p-2 font-bold">{t.attendance}%</td><td className="p-2">{t.absent}</td><td className="p-2">{t.late}</td></tr>)}</tbody>
            </table>
          </CardContent></Card>
        </TabsContent>

        <TabsContent value="below"><Card><CardContent className="p-0 overflow-x-auto">
          <table className="w-full text-sm">
            <thead className="text-xs text-muted-foreground border-b bg-muted/40"><tr>{["Student ID", "Name", "Section", "Subject", "Att %", "Absent", "Last Absent", "Suggested Action", "Action"].map((h) => <th key={h} className="text-left p-2">{h}</th>)}</tr></thead>
            <tbody>
              {below.slice(0, 12).map((s) => (
                <tr key={s.id} className="border-b">
                  <td className="p-2 font-mono text-xs">{s.id}</td><td className="p-2 font-medium">{s.name}</td><td className="p-2">{s.section}</td><td className="p-2 text-xs">EE101</td>
                  <td className="p-2 font-bold text-destructive">{s.attendance}%</td><td className="p-2">{Math.floor((100 - s.attendance) / 4)}</td><td className="p-2 text-xs">2026-04-22</td>
                  <td className="p-2 text-xs">Send Warning</td>
                  <td className="p-2"><div className="flex gap-1">
                    <Button size="sm" variant="outline" className="h-7 text-xs" onClick={() => setEmailOpen({ name: s.name, email: s.email, subject: "EE101" })}>Send Warning</Button>
                    <Button size="sm" variant="ghost" className="h-7 text-xs" onClick={() => toast("Discipline form opened")}>Report</Button>
                  </div></td>
                </tr>
              ))}
            </tbody>
          </table>
        </CardContent></Card></TabsContent>

        <TabsContent value="discipline">
          <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-6 gap-3">
            <StatCard label="Total Reports" value={disciplineReports.length} />
            <StatCard label="New" value={disciplineReports.filter((d) => d.status === "New").length} tone="warning" />
            <StatCard label="Under Review" value={disciplineReports.filter((d) => d.status === "Under Review").length} tone="warning" />
            <StatCard label="Resolved" value={disciplineReports.filter((d) => d.status === "Resolved").length} tone="success" />
            <StatCard label="Frequent Absence" value={disciplineReports.filter((d) => d.issueType === "Frequent Absence").length} tone="destructive" />
            <StatCard label="Late Cases" value={disciplineReports.filter((d) => d.issueType === "Late to Class").length} tone="info" />
          </div>
          <Card className="mt-3"><CardContent className="p-4 h-64">
            <ResponsiveContainer><BarChart data={discData}><CartesianGrid strokeDasharray="3 3" opacity={0.3} /><XAxis dataKey="type" fontSize={10} /><YAxis fontSize={11} /><Tooltip /><Bar dataKey="count" fill="oklch(0.55 0.20 295)" radius={[4, 4, 0, 0]} /></BarChart></ResponsiveContainer>
          </CardContent></Card>
        </TabsContent>
      </Tabs>

      <div className="grid lg:grid-cols-2 gap-4">
        <Card><CardHeader><CardTitle className="text-base">Status Distribution</CardTitle></CardHeader><CardContent className="h-64">
          <ResponsiveContainer><PieChart><Pie data={dist} dataKey="value" nameKey="name" outerRadius={80} label>{dist.map((d, i) => <Cell key={i} fill={d.color} />)}</Pie><Tooltip /><Legend wrapperStyle={{ fontSize: 11 }} /></PieChart></ResponsiveContainer>
        </CardContent></Card>
        <Card><CardHeader><CardTitle className="text-base">Attendance by Section</CardTitle></CardHeader><CardContent className="h-64">
          <ResponsiveContainer><BarChart data={sectionData}><CartesianGrid strokeDasharray="3 3" opacity={0.3} /><XAxis dataKey="section" fontSize={11} /><YAxis fontSize={11} domain={[0, 100]} /><Tooltip /><Bar dataKey="attendance" fill="oklch(0.62 0.16 155)" radius={[4, 4, 0, 0]} /></BarChart></ResponsiveContainer>
        </CardContent></Card>
      </div>

      <Dialog open={!!emailOpen} onOpenChange={(o) => !o && setEmailOpen(null)}>
        <DialogContent>
          <DialogHeader><DialogTitle>Send Attendance Warning Email</DialogTitle></DialogHeader>
          {emailOpen && (
            <div className="space-y-3">
              <div><Label className="text-xs">To</Label><Input className="h-9 mt-1" value={emailOpen.email} readOnly /></div>
              <div><Label className="text-xs">Subject</Label><Input className="h-9 mt-1" defaultValue="Attendance Warning - TVETMARA Johor Bahru" /></div>
              <div><Label className="text-xs">Message</Label>
                <Textarea rows={6} defaultValue={`Dear ${emailOpen.name},\n\nOur records show that your attendance for ${emailOpen.subject} is currently below the required percentage. Please contact your lecturer or academic office for further action.\n\nThank you.`} />
              </div>
              <DialogFooter>
                <Button variant="outline" onClick={() => setEmailOpen(null)}>Cancel</Button>
                <Button onClick={() => { toast.success("Warning email sent"); setEmailOpen(null); }}>Send</Button>
              </DialogFooter>
            </div>
          )}
        </DialogContent>
      </Dialog>
    </div>
  );
}