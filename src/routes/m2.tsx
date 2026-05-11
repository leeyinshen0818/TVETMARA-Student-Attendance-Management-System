import * as React from "react";
import { createFileRoute } from "@tanstack/react-router";
import { toast } from "sonner";
import { AlertTriangle, Plus, Eye, Edit, Download } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Dialog, DialogContent, DialogFooter, DialogHeader, DialogTitle, DialogDescription } from "@/components/ui/dialog";
import { PageHeader } from "@/components/page-header";
import { StatusBadge } from "@/components/status-badge";
import { useApp } from "@/lib/store";
import type { DisciplineReport } from "@/lib/mock-data";

export const Route = createFileRoute("/m2")({ component: M2 });

const ISSUE_TYPES = ["Frequent Absence", "Late to Class", "Skipping Class", "Misconduct", "Disruptive Behavior", "No MC / No Reason", "Leaving Class Early", "Other"];

function M2() {
  const { students: allStudents, disciplineReports: allReports, timetable, addDiscipline, updateDiscipline, currentUser } = useApp();

  const isLecturer = currentUser?.role === "lecturer";
  const isStaff = false;
  const lecturerSections = isLecturer
    ? Array.from(new Set(timetable.filter((t) => t.lecturerId === currentUser?.id).map((t) => t.section)))
    : null;
  const students = lecturerSections ? allStudents.filter((s) => lecturerSections.includes(s.section)) : allStudents;
  const disciplineReports = isLecturer
    ? allReports.filter((r) => r.lecturer === currentUser?.name)
    : allReports;

  const [studentId, setStudentId] = React.useState("");
  const [subject, setSubject] = React.useState("");
  const [issueType, setIssueType] = React.useState(ISSUE_TYPES[0]);
  const [severity, setSeverity] = React.useState<"Low" | "Medium" | "High">("Medium");
  const [description, setDescription] = React.useState("");
  const [followUp, setFollowUp] = React.useState(false);
  const [viewing, setViewing] = React.useState<DisciplineReport | null>(null);
  const [updating, setUpdating] = React.useState<DisciplineReport | null>(null);

  const student = students.find((s) => s.id === studentId);

  const submit = () => {
    if (!student) { toast.error("Please select a student"); return; }
    addDiscipline({
      id: `D${Date.now().toString().slice(-4)}`,
      studentId: student.id,
      studentName: student.name,
      section: student.section,
      subject: subject || "—",
      lecturer: currentUser?.name || "Lecturer",
      date: "2026-04-29",
      issueType,
      severity,
      description,
      followUp,
      status: "New",
    });
    toast.success("Discipline issue report submitted successfully.");
    setStudentId(""); setSubject(""); setDescription(""); setFollowUp(false);
  };

  const flagged = students.filter((s) => s.attendance < 80).slice(0, 8);

  return (
    <div className="space-y-5">
      <PageHeader title="M2: Report Discipline Issue / Laporan Disiplin" subtitle="Record student behaviour & attendance-related issues." />

      <div className="grid lg:grid-cols-3 gap-4">
        <Card className="lg:col-span-1">
          <CardHeader><CardTitle className="text-base">Discipline Report Form</CardTitle></CardHeader>
          <CardContent className="space-y-3">
            <Field label="Student">
              <Select value={studentId} onValueChange={setStudentId}>
                <SelectTrigger className="h-9"><SelectValue placeholder="Search & select student" /></SelectTrigger>
                <SelectContent>{students.map((s) => <SelectItem key={s.id} value={s.id}>{s.name} · {s.id}</SelectItem>)}</SelectContent>
              </Select>
            </Field>
            <div className="grid grid-cols-2 gap-3">
              <Field label="Student ID"><Input className="h-9" value={student?.id || ""} readOnly /></Field>
              <Field label="Section"><Input className="h-9" value={student?.section || ""} readOnly /></Field>
            </div>
            <Field label="Program"><Input className="h-9" value={student?.program || ""} readOnly /></Field>
            <Field label="Subject"><Input className="h-9" value={subject} onChange={(e) => setSubject(e.target.value)} placeholder="Subject" /></Field>
            <div className="grid grid-cols-2 gap-3">
              <Field label="Issue Date"><Input className="h-9" type="date" defaultValue="2026-04-29" /></Field>
              <Field label="Severity">
                <Select value={severity} onValueChange={(v) => setSeverity(v as any)}>
                  <SelectTrigger className="h-9"><SelectValue /></SelectTrigger>
                  <SelectContent>{["Low", "Medium", "High"].map((x) => <SelectItem key={x} value={x}>{x}</SelectItem>)}</SelectContent>
                </Select>
              </Field>
            </div>
            <Field label="Issue Type">
              <Select value={issueType} onValueChange={setIssueType}>
                <SelectTrigger className="h-9"><SelectValue /></SelectTrigger>
                <SelectContent>{ISSUE_TYPES.map((x) => <SelectItem key={x} value={x}>{x}</SelectItem>)}</SelectContent>
              </Select>
            </Field>
            <Field label="Description"><Textarea rows={3} value={description} onChange={(e) => setDescription(e.target.value)} placeholder="Describe the issue..." /></Field>
            <Field label="Evidence"><Button type="button" variant="outline" size="sm" className="w-full">Upload Evidence (mock)</Button></Field>
            <label className="flex items-center gap-2 text-sm">
              <input type="checkbox" checked={followUp} onChange={(e) => setFollowUp(e.target.checked)} />
              Follow-up required
            </label>
            <Button className="w-full" onClick={submit}>Submit Report</Button>
          </CardContent>
        </Card>

        <Card className="lg:col-span-2">
          <CardHeader><CardTitle className="text-base flex items-center gap-2"><AlertTriangle className="h-4 w-4 text-warning" /> Attendance-Based Warnings</CardTitle></CardHeader>
          <CardContent className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead className="text-xs text-muted-foreground border-b">
                <tr><th className="text-left py-2 px-2">Student ID</th><th className="text-left">Name</th><th className="text-left">Section</th><th className="text-left">Att %</th><th className="text-left">Absent</th><th className="text-left">Late</th><th className="text-left">Suggested</th><th className="text-left">Action</th></tr>
              </thead>
              <tbody>
                {flagged.map((s) => (
                  <tr key={s.id} className="border-b last:border-0">
                    <td className="py-2 px-2 font-mono text-xs">{s.id}</td>
                    <td className="py-2 px-2 font-medium">{s.name}</td>
                    <td className="py-2 px-2">{s.section}</td>
                    <td className="py-2 px-2 text-destructive font-bold">{s.attendance}%</td>
                    <td className="py-2 px-2">{Math.floor((100 - s.attendance) / 5)}</td>
                    <td className="py-2 px-2">{(s.id.charCodeAt(5) % 4)}</td>
                    <td className="py-2 px-2 text-xs text-muted-foreground">Frequent Absence</td>
                    <td className="py-2 px-2">
                      <Button size="sm" variant="outline" className="h-7" onClick={() => { setStudentId(s.id); setIssueType("Frequent Absence"); toast("Form pre-filled"); }}>
                        <Plus className="h-3.5 w-3.5 mr-1" /> Create Report
                      </Button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </CardContent>
        </Card>
      </div>

      <Card>
        <CardHeader><CardTitle className="text-base">Discipline Report List</CardTitle></CardHeader>
        <CardContent className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead className="text-xs text-muted-foreground border-b">
              <tr><th className="text-left py-2 px-2">Report ID</th><th className="text-left">Student</th><th className="text-left">Section</th><th className="text-left">Subject</th><th className="text-left">Issue</th><th className="text-left">Severity</th><th className="text-left">Reported By</th><th className="text-left">Date</th><th className="text-left">Status</th><th className="text-left">Action</th></tr>
            </thead>
            <tbody>
              {disciplineReports.map((d) => (
                <tr key={d.id} className="border-b last:border-0 hover:bg-muted/30">
                  <td className="py-2 px-2 font-mono text-xs">{d.id}</td>
                  <td className="py-2 px-2 font-medium">{d.studentName}</td>
                  <td className="py-2 px-2">{d.section}</td>
                  <td className="py-2 px-2">{d.subject}</td>
                  <td className="py-2 px-2 text-xs">{d.issueType}</td>
                  <td className="py-2 px-2"><StatusBadge status={d.severity} /></td>
                  <td className="py-2 px-2 text-xs text-muted-foreground">{d.lecturer}</td>
                  <td className="py-2 px-2">{d.date}</td>
                  <td className="py-2 px-2"><StatusBadge status={d.status} /></td>
                  <td className="py-2 px-2">
                    <div className="flex gap-1">
                      <Button size="sm" variant="ghost" className="h-7 px-2" onClick={() => setViewing(d)}><Eye className="h-3.5 w-3.5" /></Button>
                      <Button size="sm" variant="ghost" className="h-7 px-2" onClick={() => setUpdating(d)}><Edit className="h-3.5 w-3.5" /></Button>
                      <Button size="sm" variant="ghost" className="h-7 px-2" onClick={() => toast.success("Exported")}><Download className="h-3.5 w-3.5" /></Button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </CardContent>
      </Card>

      <Dialog open={!!viewing} onOpenChange={(o) => !o && setViewing(null)}>
        <DialogContent className="max-w-xl">
          <DialogHeader><DialogTitle>Discipline Report Details</DialogTitle><DialogDescription>{viewing?.id}</DialogDescription></DialogHeader>
          {viewing && (
            <div className="space-y-3 text-sm">
              <div className="grid grid-cols-2 gap-3">
                <Info label="Student" value={viewing.studentName} />
                <Info label="Section" value={viewing.section} />
                <Info label="Subject" value={viewing.subject} />
                <Info label="Lecturer" value={viewing.lecturer} />
                <Info label="Issue Type" value={viewing.issueType} />
                <Info label="Severity" value={viewing.severity} />
              </div>
              <div><div className="text-xs text-muted-foreground">Description</div><div className="mt-1">{viewing.description}</div></div>
              <div className="border-t pt-3">
                <div className="text-xs font-semibold mb-2">Follow-up history</div>
                <ul className="text-xs text-muted-foreground space-y-1">
                  <li>• {viewing.date} – Report submitted</li>
                  <li>• Status: {viewing.status}</li>
                </ul>
              </div>
            </div>
          )}
        </DialogContent>
      </Dialog>

      <Dialog open={!!updating} onOpenChange={(o) => !o && setUpdating(null)}>
        <DialogContent>
          <DialogHeader><DialogTitle>Update Status</DialogTitle></DialogHeader>
          {updating && (
            <div className="space-y-3">
              <Field label="Status">
                <Select value={updating.status} onValueChange={(v) => setUpdating({ ...updating, status: v as DisciplineReport["status"] })}>
                  <SelectTrigger className="h-9"><SelectValue /></SelectTrigger>
                  <SelectContent>{["New", "Under Review", "Action Taken", "Resolved", "Escalated"].map((x) => <SelectItem key={x} value={x}>{x}</SelectItem>)}</SelectContent>
                </Select>
              </Field>
              <Field label="Remarks"><Textarea rows={3} placeholder="Add follow-up note..." /></Field>
              <DialogFooter>
                <Button variant="outline" onClick={() => setUpdating(null)}>Cancel</Button>
                <Button onClick={() => { updateDiscipline(updating.id, { status: updating.status }); toast.success("Status updated"); setUpdating(null); }}>Save</Button>
              </DialogFooter>
            </div>
          )}
        </DialogContent>
      </Dialog>
    </div>
  );
}

function Field({ label, children }: { label: string; children: React.ReactNode }) {
  return <div><Label className="text-xs">{label}</Label><div className="mt-1">{children}</div></div>;
}
function Info({ label, value }: { label: string; value: string }) {
  return <div><div className="text-xs text-muted-foreground">{label}</div><div className="font-medium mt-0.5">{value}</div></div>;
}