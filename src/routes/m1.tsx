import * as React from "react";
import { createFileRoute } from "@tanstack/react-router";
import { toast } from "sonner";
import { AlertTriangle, CheckCheck, ClipboardCheck, History, QrCode, Save, Send, Upload } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { PageHeader } from "@/components/page-header";
import { RoleGate } from "@/components/role-gate";
import { StatCard } from "@/components/stat-card";
import { StatusBadge } from "@/components/status-badge";
import { useApp } from "@/lib/store";
import { generateAttendanceForSlot, type AttendanceRecord, type AttendanceStatus } from "@/lib/mock-data";

export const Route = createFileRoute("/m1")({
  validateSearch: (s: Record<string, unknown>) => ({ slot: (s.slot as string) || "" }),
  component: M1Page,
});

function M1Page() {
  return (
    <RoleGate
      allow={["lecturer"]}
      message="Attendance taking is only available for lecturers. Admin can monitor attendance through the Reporting Module."
    >
      <M1 />
    </RoleGate>
  );
}

function M1() {
  const { slot: initSlot } = Route.useSearch();
  const { timetable: allTimetable, students, attendance, saveAttendance, settings, currentUser } = useApp();
  const timetable = allTimetable.filter((slot) => slot.lecturerId === currentUser?.id);
  const [slotId, setSlotId] = React.useState(initSlot || timetable[0]?.id);
  const slot = timetable.find((item) => item.id === slotId) || timetable[0];

  const [records, setRecords] = React.useState<AttendanceRecord[]>([]);
  const [qrOpen, setQrOpen] = React.useState(false);
  const [importOpen, setImportOpen] = React.useState(false);
  const [submitOpen, setSubmitOpen] = React.useState(false);
  const [historyStudent, setHistoryStudent] = React.useState<string | null>(null);

  const sectionStudents = students.filter((student) => slot && student.section === slot.section);

  React.useEffect(() => {
    if (!slot) return;
    const existing = attendance[slot.id];
    const defaults = generateAttendanceForSlot(slot.id).map((record) => ({
      ...record,
      status: "Present" as AttendanceStatus,
      checkIn: slot.startTime,
      remarks: "",
    }));
    setRecords(existing ?? defaults);
  }, [attendance, slot]);

  const summary = React.useMemo(() => {
    const counts = { Present: 0, Absent: 0, MC: 0, CK: 0, Late: 0 };
    records.forEach((record) => counts[record.status]++);
    const counted = counts.Present + counts.Late + (settings.mcAsPresent ? counts.MC : 0) + (settings.ckAsPresent ? counts.CK : 0);
    const average = records.length ? Math.round((counted / records.length) * 100) : 0;
    return { ...counts, average };
  }, [records, settings]);

  const attentionCount = summary.Absent + summary.Late + summary.MC + summary.CK;

  const setStudentStatus = (studentId: string, status: AttendanceStatus) => {
    setRecords((prev) =>
      prev.map((record) =>
        record.studentId === studentId
          ? {
              ...record,
              status,
              checkIn: status === "Absent" || status === "MC" || status === "CK" ? "-" : slot.startTime,
              remarks: status === "Absent" ? record.remarks || "No reason" : record.remarks,
            }
          : record,
      ),
    );
  };

  const updateRemarks = (studentId: string, remarks: string) => {
    setRecords((prev) => prev.map((record) => (record.studentId === studentId ? { ...record, remarks } : record)));
  };

  const markAll = (status: AttendanceStatus) => {
    setRecords(
      sectionStudents.map((student) => ({
        slotId: slot.id,
        studentId: student.id,
        status,
        checkIn: status === "Absent" || status === "MC" || status === "CK" ? "-" : slot.startTime,
        remarks: status === "Absent" ? "No reason" : "",
      })),
    );
    toast.success(status === "Present" ? "All students marked as Present." : `All students marked as ${status}.`);
  };

  const submit = () => {
    saveAttendance(slot.id, records);
    toast.success("Attendance submitted successfully.");
    setSubmitOpen(false);
  };

  if (!slot) return <div>No assigned timetable slot found.</div>;

  return (
    <div className="space-y-5">
      <PageHeader title="M1: Taking Attendance" subtitle="Mark attendance quickly for your assigned section." />

      <Card className="border-primary/40 bg-primary/5">
        <CardHeader className="pb-3">
          <div className="flex flex-col gap-3 lg:flex-row lg:items-start lg:justify-between">
            <div>
              <CardTitle className="text-xl">{slot.subjectName}</CardTitle>
              <CardDescription>{slot.subjectCode} - Section {slot.section}</CardDescription>
            </div>
            <div className="flex flex-wrap gap-2">
              <StatusBadge status={slot.classType} />
              <StatusBadge status={slot.status} />
            </div>
          </div>
        </CardHeader>
        <CardContent className="grid grid-cols-2 gap-3 md:grid-cols-4 lg:grid-cols-6">
          <InfoBox label="Date" value={slot.date} />
          <InfoBox label="Time" value={`${slot.startTime}-${slot.endTime}`} />
          <InfoBox label="Venue" value={slot.room} />
          <InfoBox label="Students" value={String(sectionStudents.length)} />
          <InfoBox label="Need Attention" value={String(attentionCount)} tone={attentionCount ? "warning" : "success"} />
          <div>
            <Label className="text-xs">Switch Class</Label>
            <Select value={slot.id} onValueChange={setSlotId}>
              <SelectTrigger className="h-9 mt-1 bg-background"><SelectValue /></SelectTrigger>
              <SelectContent>
                {timetable.map((item) => (
                  <SelectItem key={item.id} value={item.id}>{item.date} - {item.startTime} - {item.subjectCode} - {item.section}</SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>
        </CardContent>
      </Card>

      <Card>
        <CardContent className="flex flex-col gap-3 p-4 lg:flex-row lg:items-center">
          <div className="flex flex-wrap gap-2">
            <Button onClick={() => markAll("Present")} className="bg-success text-success-foreground hover:bg-success/90">
              <CheckCheck className="h-4 w-4 mr-1.5" /> Mark All Present
            </Button>
            <Button variant="outline" onClick={() => markAll("Absent")}>
              <AlertTriangle className="h-4 w-4 mr-1.5" /> Mark All Absent
            </Button>
            <Button variant="outline" onClick={() => setQrOpen(true)}>
              <QrCode className="h-4 w-4 mr-1.5" /> QR Attendance
            </Button>
            <Button variant="outline" onClick={() => setImportOpen(true)}>
              <Upload className="h-4 w-4 mr-1.5" /> Import
            </Button>
          </div>
          <div className="flex gap-2 lg:ml-auto">
            <Button variant="ghost" onClick={() => toast("Draft saved")}>
              <Save className="h-4 w-4 mr-1.5" /> Save Draft
            </Button>
            <Button size="lg" onClick={() => setSubmitOpen(true)}>
              <Send className="h-4 w-4 mr-1.5" /> Submit Attendance
            </Button>
          </div>
        </CardContent>
      </Card>

      <div className="grid grid-cols-2 gap-3 md:grid-cols-4 lg:grid-cols-7">
        <StatCard label="Total" value={sectionStudents.length} />
        <StatCard label="Present" value={summary.Present} tone="success" />
        <StatCard label="Absent" value={summary.Absent} tone="destructive" />
        <StatCard label="Late" value={summary.Late} tone="warning" />
        <StatCard label="MC / CK" value={summary.MC + summary.CK} tone="info" />
        <StatCard label="Average" value={`${summary.average}%`} tone="success" />
        <StatCard label="Below 80%" value={sectionStudents.filter((student) => student.attendance < 80).length} tone="destructive" />
      </div>

      <Card>
        <CardHeader className="flex flex-row items-center justify-between">
          <CardTitle className="text-base flex items-center gap-2">
            <ClipboardCheck className="h-4 w-4" /> Student Attendance
          </CardTitle>
          <div className="text-xs text-muted-foreground">Tap one status per student, then submit.</div>
        </CardHeader>
        <CardContent className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead className="border-b text-xs text-muted-foreground">
              <tr>
                {["No.", "Student ID", "Name", "Status", "Check-in", "Remarks", "Att %", "History"].map((header) => (
                  <th key={header} className="text-left p-2 whitespace-nowrap">{header}</th>
                ))}
              </tr>
            </thead>
            <tbody>
              {sectionStudents.map((student, index) => {
                const record = records.find((item) => item.studentId === student.id);
                if (!record) return null;
                return (
                  <tr key={student.id} className="border-b last:border-0 hover:bg-muted/30">
                    <td className="p-2">{index + 1}</td>
                    <td className="p-2 font-mono text-xs">{student.id}</td>
                    <td className="p-2 font-medium min-w-48">{student.name}</td>
                    <td className="p-2">
                      <div className="flex min-w-[270px] flex-wrap gap-1">
                        {(["Present", "Absent", "Late", "MC", "CK"] as AttendanceStatus[]).map((status) => (
                          <Button
                            key={status}
                            size="sm"
                            variant={record.status === status ? "default" : "outline"}
                            className={`h-7 px-2 text-xs ${
                              record.status === status && status === "Present" ? "bg-success text-success-foreground hover:bg-success/90" : ""
                            } ${record.status === status && status === "Absent" ? "bg-destructive text-destructive-foreground hover:bg-destructive/90" : ""}`}
                            onClick={() => setStudentStatus(student.id, status)}
                          >
                            {status}
                          </Button>
                        ))}
                      </div>
                    </td>
                    <td className="p-2 text-xs text-muted-foreground">{record.checkIn}</td>
                    <td className="p-2">
                      <Input className="h-8 w-44" placeholder="Optional note" value={record.remarks} onChange={(event) => updateRemarks(student.id, event.target.value)} />
                    </td>
                    <td className="p-2 font-semibold">
                      <span className={student.attendance < 80 ? "text-destructive" : ""}>{student.attendance}%</span>
                    </td>
                    <td className="p-2">
                      <Button size="sm" variant="ghost" className="h-7" onClick={() => setHistoryStudent(student.id)}>
                        <History className="h-3.5 w-3.5 mr-1" /> History
                      </Button>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </CardContent>
      </Card>

      <Dialog open={qrOpen} onOpenChange={setQrOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>QR Attendance</DialogTitle>
            <DialogDescription>Students can scan to check in within the attendance window.</DialogDescription>
          </DialogHeader>
          <div className="grid place-items-center py-2">
            <div className="h-48 w-48 grid grid-cols-8 grid-rows-8 gap-0.5 bg-white p-2 rounded border-4 border-foreground/10">
              {Array.from({ length: 64 }).map((_, index) => (
                <div key={index} className={(index * 7) % 3 === 0 ? "bg-foreground" : "bg-transparent"} />
              ))}
            </div>
          </div>
          <div className="text-sm space-y-1">
            <div><span className="text-muted-foreground">Subject:</span> {slot.subjectName}</div>
            <div><span className="text-muted-foreground">Section:</span> {slot.section}</div>
            <div><span className="text-muted-foreground">Date / Time:</span> {slot.date} - {slot.startTime}-{slot.endTime}</div>
            <div><span className="text-muted-foreground">Link:</span> <code className="text-xs">https://forms.tvetmara.edu.my/att/{slot.id}</code></div>
          </div>
          <DialogFooter className="gap-2">
            <Button variant="outline" onClick={() => { navigator.clipboard?.writeText("https://forms.tvetmara.edu.my/att/" + slot.id); toast.success("Link copied"); }}>Copy Link</Button>
            <Button variant="outline" onClick={() => toast.success("QR downloaded")}>Download QR</Button>
            <Button onClick={() => setQrOpen(false)}>Close</Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      <Dialog open={importOpen} onOpenChange={setImportOpen}>
        <DialogContent>
          <DialogHeader><DialogTitle>Import Attendance Data</DialogTitle></DialogHeader>
          <div className="border-2 border-dashed rounded-lg p-8 text-center">
            <Upload className="h-8 w-8 mx-auto text-muted-foreground mb-2" />
            <p className="text-sm">Drop CSV / Excel file here</p>
            <Button size="sm" variant="outline" className="mt-3" onClick={() => toast.success("File uploaded")}>Upload File</Button>
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setImportOpen(false)}>Cancel</Button>
            <Button onClick={() => { setImportOpen(false); toast.success("Imported attendance applied"); }}>Apply Imported Attendance</Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      <Dialog open={submitOpen} onOpenChange={setSubmitOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Submit Attendance?</DialogTitle>
            <DialogDescription>Submit attendance for {slot.subjectCode} - {slot.section}. This will mark the timetable slot as completed.</DialogDescription>
          </DialogHeader>
          <DialogFooter>
            <Button variant="outline" onClick={() => setSubmitOpen(false)}>Cancel</Button>
            <Button onClick={submit}><Send className="h-4 w-4 mr-1.5" /> Submit Attendance</Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      <Dialog open={!!historyStudent} onOpenChange={(open) => !open && setHistoryStudent(null)}>
        <DialogContent className="max-w-2xl">
          <DialogHeader><DialogTitle>Absence History</DialogTitle></DialogHeader>
          <table className="w-full text-sm">
            <thead className="border-b">
              <tr>{["Week", "Date", "Subject", "Section", "Status", "Remarks"].map((header) => <th key={header} className="text-left py-2">{header}</th>)}</tr>
            </thead>
            <tbody>
              {[
                { w: 8, d: "2026-03-10", sub: "EE101", st: "Absent", r: "No reason" },
                { w: 9, d: "2026-03-17", sub: "EE102", st: "MC", r: "Medical certificate" },
                { w: 10, d: "2026-03-24", sub: "EE103", st: "Late", r: "Late 20 min" },
              ].map((item) => (
                <tr key={`${item.w}-${item.sub}`} className="border-b last:border-0">
                  <td className="py-2">W{item.w}</td>
                  <td>{item.d}</td>
                  <td>{item.sub}</td>
                  <td>{slot.section}</td>
                  <td><StatusBadge status={item.st} /></td>
                  <td className="text-muted-foreground">{item.r}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </DialogContent>
      </Dialog>
    </div>
  );
}

function InfoBox({ label, value, tone }: { label: string; value: string; tone?: "success" | "warning" }) {
  const toneClass = tone === "success" ? "text-success" : tone === "warning" ? "text-warning-foreground" : "";
  return (
    <div className="rounded-md border bg-background p-3">
      <div className="text-xs text-muted-foreground">{label}</div>
      <div className={`mt-1 font-semibold ${toneClass}`}>{value}</div>
    </div>
  );
}
