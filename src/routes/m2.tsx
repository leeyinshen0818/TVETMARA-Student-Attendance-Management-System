import * as React from "react";
import { createFileRoute } from "@tanstack/react-router";
import { toast } from "sonner";
import { AlertTriangle, Check, Download, Eye, Plus, X } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Textarea } from "@/components/ui/textarea";
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { PageHeader } from "@/components/page-header";
import { StatusBadge } from "@/components/status-badge";
import { useApp } from "@/lib/store";
import type { DisciplineReport } from "@/lib/mock-data";

export const Route = createFileRoute("/m2")({ component: M2 });

const ISSUE_TYPES = ["Frequent Absence", "Late to Class", "Skipping Class", "Misconduct", "Disruptive Behavior", "No MC / No Reason", "Leaving Class Early", "Other"];

function M2() {
  const { students: allStudents, disciplineReports: allReports, timetable, addDiscipline, updateDiscipline, currentUser } = useApp();
  const isAdmin = currentUser?.role === "admin";
  const isLecturer = currentUser?.role === "lecturer";

  const lecturerSections = isLecturer
    ? Array.from(new Set(timetable.filter((t) => t.lecturerId === currentUser?.id).map((t) => t.section)))
    : null;
  const lecturerSlots = React.useMemo(
    () => (isLecturer ? timetable.filter((t) => t.lecturerId === currentUser?.id) : []),
    [currentUser?.id, isLecturer, timetable],
  );
  const students = lecturerSections ? allStudents.filter((s) => lecturerSections.includes(s.section)) : allStudents;
  const reports = isLecturer ? allReports.filter((report) => report.lecturer === currentUser?.name) : allReports;
  const flagged = students.filter((student) => student.attendance < 80).slice(0, 8);

  const [studentId, setStudentId] = React.useState("");
  const [subject, setSubject] = React.useState("");
  const [issueType, setIssueType] = React.useState(ISSUE_TYPES[0]);
  const [severity, setSeverity] = React.useState<"Low" | "Medium" | "High">("Medium");
  const [description, setDescription] = React.useState("");
  const [followUp, setFollowUp] = React.useState(false);
  const [viewing, setViewing] = React.useState<DisciplineReport | null>(null);

  const student = students.find((item) => item.id === studentId);
  const subjectOptions = React.useMemo(
    () =>
      Array.from(
        new Map(
          lecturerSlots
            .filter((slot) => !student || slot.section === student.section)
            .map((slot) => [slot.subjectName, slot]),
        ).values(),
      ),
    [lecturerSlots, student],
  );

  React.useEffect(() => {
    if (!subjectOptions.length) {
      setSubject("");
      return;
    }
    if (!subjectOptions.some((slot) => slot.subjectName === subject)) {
      setSubject(subjectOptions[0].subjectName);
    }
  }, [studentId, subject, subjectOptions]);

  const submit = () => {
    if (!student) {
      toast.error("Sila pilih pelajar.");
      return;
    }
    if (!subject) {
      toast.error("Sila pilih subjek daripada jadual yang ditugaskan.");
      return;
    }
    addDiscipline({
      id: `D${Date.now().toString().slice(-4)}`,
      studentId: student.id,
      studentName: student.name,
      section: student.section,
      subject,
      lecturer: currentUser?.name || "Lecturer",
      date: "2026-05-11",
      issueType,
      severity,
      description,
      followUp,
      status: "New",
    });
    toast.success("Report submitted to admin for review.");
    setStudentId("");
    setSubject("");
    setDescription("");
    setFollowUp(false);
  };

  const review = (report: DisciplineReport, status: "Approved" | "Rejected") => {
    updateDiscipline(report.id, { status });
    toast.success(status === "Approved" ? "Report approved." : "Report rejected.");
  };

  const downloadCsv = () => {
    const rows = [["Report ID", "Student", "Section", "Subject", "Issue", "Severity", "Lecturer", "Date", "Status"], ...reports.map((report) => [report.id, report.studentName, report.section, report.subject, report.issueType, report.severity, report.lecturer, report.date, report.status])];
    const csv = rows.map((row) => row.map((cell) => `"${String(cell).replace(/"/g, '""')}"`).join(",")).join("\n");
    const blob = new Blob([csv], { type: "text/csv;charset=utf-8" });
    const url = URL.createObjectURL(blob);
    const link = document.createElement("a");
    link.href = url;
    link.download = "discipline-reports.csv";
    link.click();
    URL.revokeObjectURL(url);
  };

  return (
    <div className="space-y-5">
      <PageHeader
        title={isAdmin ? "Discipline Report Review" : "M2: Report Discipline Issue"}
        subtitle={isAdmin ? "Admin menyemak laporan yang dihantar oleh pensyarah." : "Lecturers create attendance-related discipline reports for admin review."}
        actions={
          <Button variant="outline" size="sm" onClick={downloadCsv}>
            <Download className="h-4 w-4 mr-1.5" /> Download CSV
          </Button>
        }
      />

      {isLecturer && (
        <div className="grid lg:grid-cols-3 gap-4">
          <Card>
            <CardHeader><CardTitle className="text-base">Create Report</CardTitle></CardHeader>
            <CardContent className="space-y-3">
              <Field label="Student">
                <Select value={studentId} onValueChange={setStudentId}>
                  <SelectTrigger className="h-9"><SelectValue placeholder="Select student" /></SelectTrigger>
                  <SelectContent>{students.map((item) => <SelectItem key={item.id} value={item.id}>{item.name} - {item.id}</SelectItem>)}</SelectContent>
                </Select>
              </Field>
              <div className="grid grid-cols-2 gap-3">
                <Field label="Student ID"><Input className="h-9" value={student?.id || ""} readOnly /></Field>
                <Field label="Section"><Input className="h-9" value={student?.section || ""} readOnly /></Field>
              </div>
              <Field label="Course"><Input className="h-9" value={student?.program || ""} readOnly /></Field>
              <Field label="Subject">
                <Select value={subject} onValueChange={setSubject} disabled={!subjectOptions.length}>
                  <SelectTrigger className="h-9"><SelectValue placeholder="Select assigned subject" /></SelectTrigger>
                  <SelectContent>
                    {subjectOptions.map((slot) => (
                      <SelectItem key={`${slot.id}-${slot.subjectName}`} value={slot.subjectName}>
                        {slot.subjectCode} - {slot.subjectName}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </Field>
              <div className="grid grid-cols-2 gap-3">
                <Field label="Issue Type">
                  <Select value={issueType} onValueChange={setIssueType}>
                    <SelectTrigger className="h-9"><SelectValue /></SelectTrigger>
                    <SelectContent>{ISSUE_TYPES.map((item) => <SelectItem key={item} value={item}>{item}</SelectItem>)}</SelectContent>
                  </Select>
                </Field>
                <Field label="Severity">
                  <Select value={severity} onValueChange={(value) => setSeverity(value as "Low" | "Medium" | "High")}>
                    <SelectTrigger className="h-9"><SelectValue /></SelectTrigger>
                  <SelectContent>{[{ value: "Low", label: "Low" }, { value: "Medium", label: "Medium" }, { value: "High", label: "High" }].map((item) => <SelectItem key={item.value} value={item.value}>{item.label}</SelectItem>)}</SelectContent>
                  </Select>
                </Field>
              </div>
              <Field label="Description"><Textarea rows={4} value={description} onChange={(event) => setDescription(event.target.value)} placeholder="Terangkan isu yang berlaku." /></Field>
              <label className="flex items-center gap-2 text-sm">
                <input type="checkbox" checked={followUp} onChange={(event) => setFollowUp(event.target.checked)} />
                Follow-up required
              </label>
              <Button className="w-full" onClick={submit}>Submit Report</Button>
            </CardContent>
          </Card>

          <Card className="lg:col-span-2">
            <CardHeader><CardTitle className="text-base flex items-center gap-2"><AlertTriangle className="h-4 w-4 text-warning" /> Attendance Warnings</CardTitle></CardHeader>
            <CardContent className="overflow-x-auto">
              <table className="w-full text-sm">
                <thead className="border-b text-xs text-muted-foreground">
                  <tr>{["Student ID", "Name", "Section", "Attendance", "Suggested", "Action"].map((header) => <th key={header} className="text-left p-2">{header}</th>)}</tr>
                </thead>
                <tbody>
                  {flagged.map((item) => (
                    <tr key={item.id} className="border-b last:border-0">
                      <td className="p-2 font-mono text-xs">{item.id}</td>
                      <td className="p-2 font-medium">{item.name}</td>
                      <td className="p-2">{item.section}</td>
                      <td className="p-2 font-bold text-destructive">{item.attendance}%</td>
                      <td className="p-2 text-xs text-muted-foreground">Frequent Absence</td>
                      <td className="p-2">
                        <Button size="sm" variant="outline" className="h-7 text-xs" onClick={() => { setStudentId(item.id); setIssueType("Frequent Absence"); }}>
                          <Plus className="h-3 w-3 mr-1" /> Create
                        </Button>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </CardContent>
          </Card>
        </div>
      )}

      <Card>
        <CardHeader><CardTitle className="text-base">Discipline Report List</CardTitle></CardHeader>
        <CardContent className="p-0 overflow-x-auto">
          <table className="w-full text-sm">
            <thead className="border-b bg-muted/40 text-xs text-muted-foreground">
              <tr>{["Report ID", "Student", "Section", "Subject", "Issue", "Severity", "Reported By", "Date", "Status", "Action"].map((header) => <th key={header} className="text-left p-2 whitespace-nowrap">{header}</th>)}</tr>
            </thead>
            <tbody>
              {reports.length === 0 && (
                <tr>
                  <td className="p-4 text-center text-sm text-muted-foreground" colSpan={10}>
                    No discipline reports match this account.
                  </td>
                </tr>
              )}
              {reports.map((report) => (
                <tr key={report.id} className="border-b last:border-0 hover:bg-muted/30">
                  <td className="p-2 font-mono text-xs">{report.id}</td>
                  <td className="p-2 font-medium">{report.studentName}</td>
                  <td className="p-2">{report.section}</td>
                  <td className="p-2">{report.subject}</td>
                  <td className="p-2 text-xs">{report.issueType}</td>
                  <td className="p-2"><StatusBadge status={report.severity} /></td>
                  <td className="p-2 text-xs">{report.lecturer}</td>
                  <td className="p-2">{report.date}</td>
                  <td className="p-2"><StatusBadge status={report.status} /></td>
                  <td className="p-2">
                    <div className="flex gap-1">
                      <Button size="sm" variant="ghost" className="h-7 px-2" onClick={() => setViewing(report)}><Eye className="h-3.5 w-3.5" /></Button>
                      {isAdmin && (report.status === "New" || report.status === "Under Review") && (
                        <>
                          <Button size="sm" variant="ghost" className="h-7 px-2 text-success" onClick={() => review(report, "Approved")}><Check className="h-3.5 w-3.5" /></Button>
                          <Button size="sm" variant="ghost" className="h-7 px-2 text-destructive" onClick={() => review(report, "Rejected")}><X className="h-3.5 w-3.5" /></Button>
                        </>
                      )}
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </CardContent>
      </Card>

      <Dialog open={!!viewing} onOpenChange={(open) => !open && setViewing(null)}>
        <DialogContent>
          <DialogHeader><DialogTitle>Report Details</DialogTitle></DialogHeader>
          {viewing && (
            <div className="space-y-3 text-sm">
              <div className="grid grid-cols-2 gap-3">
                <Info label="Student" value={viewing.studentName} />
                <Info label="Section" value={viewing.section} />
                <Info label="Subject" value={viewing.subject} />
                <Info label="Lecturer" value={viewing.lecturer} />
                <Info label="Issue" value={viewing.issueType} />
                <Info label="Status" value={viewing.status} />
              </div>
              <div>
                <div className="text-xs text-muted-foreground">Description</div>
                <div className="mt-1">{viewing.description || "-"}</div>
              </div>
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
  return <div><div className="text-xs text-muted-foreground">{label}</div><div className="font-medium">{value}</div></div>;
}
