import * as React from "react";
import { createFileRoute, useNavigate } from "@tanstack/react-router";
import { toast } from "sonner";
import { QrCode, Upload, CheckCheck, Save, Send, History, Filter } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { PageHeader } from "@/components/page-header";
import { StatCard } from "@/components/stat-card";
import { StatusBadge } from "@/components/status-badge";
import { useApp } from "@/lib/store";
import { generateAttendanceForSlot, type AttendanceRecord, type AttendanceStatus } from "@/lib/mock-data";

export const Route = createFileRoute("/m1")({
  validateSearch: (s: Record<string, unknown>) => ({ slot: (s.slot as string) || "" }),
  component: M1,
});

function M1() {
  const { slot: initSlot } = Route.useSearch();
  const navigate = useNavigate();
  const { timetable: allTimetable, students, attendance, saveAttendance, settings, currentUser } = useApp();

  const isStaff = currentUser?.role === "staff";
  const isLecturer = currentUser?.role === "lecturer";
  const timetable = isLecturer
    ? allTimetable.filter((t) => t.lecturerId === currentUser?.id)
    : allTimetable;

  const [slotId, setSlotId] = React.useState(initSlot || timetable.find((t) => t.date === "2026-04-29")?.id || timetable[0]?.id);
  const slot = timetable.find((t) => t.id === slotId);

  const [records, setRecords] = React.useState<AttendanceRecord[]>([]);
  React.useEffect(() => {
    if (!slot) return;
    setRecords(attendance[slot.id] ?? generateAttendanceForSlot(slot.id).map((r) => ({ ...r, status: "Present" as AttendanceStatus, checkIn: slot.startTime, remarks: "" })));
  }, [slotId]);

  const [qrOpen, setQrOpen] = React.useState(false);
  const [importOpen, setImportOpen] = React.useState(false);
  const [submitOpen, setSubmitOpen] = React.useState(false);
  const [historyStudent, setHistoryStudent] = React.useState<string | null>(null);

  const sectionStudents = students.filter((s) => slot && s.section === slot.section);

  const summary = React.useMemo(() => {
    const c = { Present: 0, Absent: 0, MC: 0, CK: 0, Late: 0 };
    records.forEach((r) => c[r.status]++);
    const totalCounted = c.Present + c.Late + (settings.mcAsPresent ? c.MC : 0) + (settings.ckAsPresent ? c.CK : 0);
    const avg = records.length ? Math.round((totalCounted / records.length) * 100) : 0;
    return { ...c, avg };
  }, [records, settings]);

  const updateRecord = (sid: string, patch: Partial<AttendanceRecord>) =>
    setRecords((p) => p.map((r) => (r.studentId === sid ? { ...r, ...patch } : r)));

  const markAllPresent = () => {
    setRecords(sectionStudents.map((s) => ({ slotId: slot!.id, studentId: s.id, status: "Present", checkIn: slot!.startTime, remarks: "" })));
    toast.success("All students marked as Present");
  };

  const submit = () => {
    if (!slot) return;
    saveAttendance(slot.id, records);
    toast.success("Attendance submitted successfully.");
    setSubmitOpen(false);
  };

  if (!slot) return <div>No timetable slot selected.</div>;

  return (
    <div className="space-y-5">
      <PageHeader
        title={isStaff ? "Attendance Records (View Only)" : "M1: Taking Attendance / Ambil Kehadiran"}
        subtitle={isStaff ? "Read-only view of attendance for monitoring." : "Mark attendance for a scheduled class session linked to the timetable."}
      />

      <Card>
        <CardHeader className="pb-3"><CardTitle className="text-sm flex items-center gap-2"><Filter className="h-4 w-4" /> Filters</CardTitle></CardHeader>
        <CardContent className="grid grid-cols-2 md:grid-cols-4 lg:grid-cols-6 gap-3">
          <FilterField label="Class / Section" value={slot.section} />
          <FilterField label="Subject" value={slot.subjectName} />
          <FilterField label="Lecturer" value={slot.lecturerName} />
          <FilterField label="Semester" value={`Sem ${slot.semester}`} />
          <FilterField label="Week" value="Week 12" />
          <div>
            <Label className="text-xs">Time Slot</Label>
            <Select value={slotId} onValueChange={setSlotId}>
              <SelectTrigger className="h-9 mt-1"><SelectValue /></SelectTrigger>
              <SelectContent>
                {timetable.slice(0, 30).map((t) => (
                  <SelectItem key={t.id} value={t.id}>{t.date} · {t.startTime} · {t.subjectCode} · {t.section}</SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>
        </CardContent>
      </Card>

      <Card>
        <CardContent className="p-4">
          <div className="grid md:grid-cols-2 lg:grid-cols-4 gap-4 text-sm">
            <Info label="Subject" value={`${slot.subjectName} (${slot.subjectCode})`} />
            <Info label="Lecturer" value={slot.lecturerName} />
            <Info label="Class / Section" value={slot.section} />
            <Info label="Semester / Week" value={`Sem ${slot.semester} · Week 12`} />
            <Info label="Date" value={slot.date} />
            <Info label="Time" value={`${slot.startTime} – ${slot.endTime}`} />
            <Info label="Room" value={slot.room} />
            <div>
              <div className="text-xs text-muted-foreground">Status</div>
              <div className="mt-1 flex items-center gap-2">
                <StatusBadge status={slot.classType} />
                <StatusBadge status={slot.status} />
              </div>
            </div>
          </div>
        </CardContent>
      </Card>

      {!isStaff && (
        <div className="flex flex-wrap gap-2">
          <Button variant="outline" size="sm"><CheckCheck className="h-4 w-4 mr-1.5" /> Manual Attendance</Button>
          <Button variant="outline" size="sm" onClick={() => setQrOpen(true)}><QrCode className="h-4 w-4 mr-1.5" /> Generate QR Attendance</Button>
          <Button variant="outline" size="sm" onClick={() => setImportOpen(true)}><Upload className="h-4 w-4 mr-1.5" /> Import Attendance Data</Button>
          <Button variant="secondary" size="sm" onClick={markAllPresent}>Mark All Present</Button>
          <Button variant="ghost" size="sm" onClick={() => toast("Draft saved")}><Save className="h-4 w-4 mr-1.5" /> Save Draft</Button>
          <Button size="sm" className="ml-auto" onClick={() => setSubmitOpen(true)}><Send className="h-4 w-4 mr-1.5" /> Submit Attendance</Button>
        </div>
      )}

      <div className="grid grid-cols-2 md:grid-cols-4 lg:grid-cols-8 gap-3">
        <StatCard label="Total" value={sectionStudents.length} />
        <StatCard label="Present" value={summary.Present} tone="success" />
        <StatCard label="Absent" value={summary.Absent} tone="destructive" />
        <StatCard label="MC" value={summary.MC} tone="info" />
        <StatCard label="CK" value={summary.CK} tone="info" />
        <StatCard label="Late" value={summary.Late} tone="warning" />
        <StatCard label="Average" value={`${summary.avg}%`} tone="success" />
        <StatCard label="Below 80%" value={sectionStudents.filter((s) => s.attendance < 80).length} tone="destructive" />
      </div>

      <Card>
        <CardHeader><CardTitle className="text-base">Student Attendance</CardTitle></CardHeader>
        <CardContent className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead className="text-xs text-muted-foreground border-b">
              <tr>
                <th className="text-left py-2 px-2">No.</th>
                <th className="text-left py-2 px-2">Student ID</th>
                <th className="text-left py-2 px-2">Name</th>
                <th className="text-left py-2 px-2">Section</th>
                <th className="text-left py-2 px-2">Status</th>
                <th className="text-left py-2 px-2">Check-in</th>
                <th className="text-left py-2 px-2">Remarks</th>
                <th className="text-left py-2 px-2">Att %</th>
                <th className="text-left py-2 px-2">Warning</th>
                <th className="text-left py-2 px-2">Action</th>
              </tr>
            </thead>
            <tbody>
              {sectionStudents.map((s, i) => {
                const r = records.find((x) => x.studentId === s.id);
                if (!r) return null;
                return (
                  <tr key={s.id} className="border-b last:border-0 hover:bg-muted/30">
                    <td className="py-2 px-2">{i + 1}</td>
                    <td className="py-2 px-2 font-mono text-xs">{s.id}</td>
                    <td className="py-2 px-2 font-medium">{s.name}</td>
                    <td className="py-2 px-2">{s.section}</td>
                    <td className="py-2 px-2">
                      <Select value={r.status} onValueChange={(v) => updateRecord(s.id, { status: v as AttendanceStatus })}>
                        <SelectTrigger className="h-8 w-28"><SelectValue /></SelectTrigger>
                        <SelectContent>
                          {(["Present", "Absent", "MC", "CK", "Late"] as AttendanceStatus[]).map((x) => (
                            <SelectItem key={x} value={x}>{x}</SelectItem>
                          ))}
                        </SelectContent>
                      </Select>
                    </td>
                    <td className="py-2 px-2 text-xs text-muted-foreground">{r.checkIn}</td>
                    <td className="py-2 px-2">
                      <Input className="h-8 w-44" placeholder="No reason" value={r.remarks} onChange={(e) => updateRecord(s.id, { remarks: e.target.value })} />
                    </td>
                    <td className="py-2 px-2 font-semibold">{s.attendance}%</td>
                    <td className="py-2 px-2">{s.attendance < 80 ? <StatusBadge status="Below 80%" /> : <StatusBadge status="Good" />}</td>
                    <td className="py-2 px-2">
                      <Button size="sm" variant="ghost" className="h-7" onClick={() => setHistoryStudent(s.id)}>
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

      {/* QR Modal */}
      <Dialog open={qrOpen} onOpenChange={setQrOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>QR Attendance / Kehadiran QR</DialogTitle>
            <DialogDescription>Students can scan to check in within the time window.</DialogDescription>
          </DialogHeader>
          <div className="grid place-items-center py-2">
            <div className="h-48 w-48 grid grid-cols-8 grid-rows-8 gap-0.5 bg-white p-2 rounded border-4 border-foreground/10">
              {Array.from({ length: 64 }).map((_, i) => (
                <div key={i} className={(i * 7) % 3 === 0 ? "bg-foreground" : "bg-transparent"} />
              ))}
            </div>
          </div>
          <div className="text-sm space-y-1">
            <div><span className="text-muted-foreground">Subject:</span> {slot.subjectName}</div>
            <div><span className="text-muted-foreground">Section:</span> {slot.section}</div>
            <div><span className="text-muted-foreground">Date / Time:</span> {slot.date} · {slot.startTime}–{slot.endTime}</div>
            <div><span className="text-muted-foreground">Link:</span> <code className="text-xs">https://forms.tvetmara.edu.my/att/{slot.id}</code></div>
            <p className="text-xs text-muted-foreground pt-2">QR attendance can be connected with Microsoft Forms or a student attendance form in real implementation.</p>
          </div>
          <DialogFooter className="gap-2">
            <Button variant="outline" onClick={() => { navigator.clipboard?.writeText("https://forms.tvetmara.edu.my/att/" + slot.id); toast.success("Link copied"); }}>Copy Link</Button>
            <Button variant="outline" onClick={() => toast.success("QR downloaded")}>Download QR</Button>
            <Button onClick={() => setQrOpen(false)}>Close</Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Import Modal */}
      <Dialog open={importOpen} onOpenChange={setImportOpen}>
        <DialogContent>
          <DialogHeader><DialogTitle>Import Attendance Data</DialogTitle></DialogHeader>
          <div className="border-2 border-dashed rounded-lg p-8 text-center">
            <Upload className="h-8 w-8 mx-auto text-muted-foreground mb-2" />
            <p className="text-sm">Drop CSV / Excel file here</p>
            <Button size="sm" variant="outline" className="mt-3" onClick={() => toast.success("File uploaded")}>Upload File</Button>
          </div>
          <div className="text-xs">
            <div className="font-semibold mb-1">Preview:</div>
            <table className="w-full border">
              <thead><tr className="bg-muted"><th className="p-1 text-left">Student ID</th><th className="p-1 text-left">Status</th><th className="p-1 text-left">Time</th></tr></thead>
              <tbody>
                {sectionStudents.slice(0, 3).map((s) => (
                  <tr key={s.id} className="border-t"><td className="p-1">{s.id}</td><td className="p-1">Present</td><td className="p-1">{slot.startTime}</td></tr>
                ))}
              </tbody>
            </table>
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setImportOpen(false)}>Cancel</Button>
            <Button onClick={() => { setImportOpen(false); toast.success("Imported attendance applied"); }}>Apply Imported Attendance</Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Submit confirmation */}
      <Dialog open={submitOpen} onOpenChange={setSubmitOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Submit Attendance?</DialogTitle>
            <DialogDescription>Are you sure you want to submit attendance for this class? After submission, changes may require admin approval.</DialogDescription>
          </DialogHeader>
          <DialogFooter>
            <Button variant="outline" onClick={() => setSubmitOpen(false)}>Cancel</Button>
            <Button onClick={submit}>Submit Attendance</Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Absence history */}
      <Dialog open={!!historyStudent} onOpenChange={(o) => !o && setHistoryStudent(null)}>
        <DialogContent className="max-w-2xl">
          <DialogHeader><DialogTitle>Absence History</DialogTitle></DialogHeader>
          <table className="w-full text-sm">
            <thead className="border-b"><tr><th className="text-left py-2">Week</th><th className="text-left">Date</th><th className="text-left">Subject</th><th className="text-left">Section</th><th className="text-left">Status</th><th className="text-left">Remarks</th></tr></thead>
            <tbody>
              {[
                { w: 8, d: "2026-03-10", sub: "EE101", st: "Absent", r: "No reason" },
                { w: 9, d: "2026-03-17", sub: "EE102", st: "MC", r: "Medical certificate" },
                { w: 10, d: "2026-03-24", sub: "EE103", st: "Late", r: "Late 20 min" },
                { w: 11, d: "2026-04-07", sub: "EE104", st: "Absent", r: "No reason" },
              ].map((h, i) => (
                <tr key={i} className="border-b last:border-0"><td className="py-2">W{h.w}</td><td>{h.d}</td><td>{h.sub}</td><td>{slot.section}</td><td><StatusBadge status={h.st} /></td><td className="text-muted-foreground">{h.r}</td></tr>
              ))}
            </tbody>
          </table>
        </DialogContent>
      </Dialog>
    </div>
  );
}

function FilterField({ label, value }: { label: string; value: string }) {
  return (
    <div>
      <Label className="text-xs">{label}</Label>
      <Input className="h-9 mt-1" value={value} readOnly />
    </div>
  );
}

function Info({ label, value }: { label: string; value: string }) {
  return (
    <div>
      <div className="text-xs text-muted-foreground">{label}</div>
      <div className="font-medium mt-0.5">{value}</div>
    </div>
  );
}