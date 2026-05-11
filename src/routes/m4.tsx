import * as React from "react";
import { createFileRoute } from "@tanstack/react-router";
import { toast } from "sonner";
import { Upload, Download, Plus, AlertCircle } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Dialog, DialogContent, DialogFooter, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { PageHeader } from "@/components/page-header";
import { StatCard } from "@/components/stat-card";
import { StatusBadge } from "@/components/status-badge";
import { useApp } from "@/lib/store";
import { LECTURERS, SUBJECTS, SECTIONS, ROOMS } from "@/lib/mock-data";

export const Route = createFileRoute("/m4")({ component: M4 });

type Preview = {
  row: number; session: string; semester: number; program: string; section: string; subjectCode: string; subjectName: string;
  lecturer: string; day: string; start: string; end: string; room: string; classType: string; weekRange: string;
  validation: "Valid" | "Missing Data" | "Lecturer Clash" | "Room Clash" | "Duplicate Slot" | "Invalid Time";
  issue?: string;
};

const SAMPLE: Preview[] = [
  { row: 1, session: "2025/2026", semester: 2, program: "Electrical Installation", section: "ELI-1A", subjectCode: "EE101", subjectName: "Electrical Installation Theory", lecturer: "Encik Ahmad bin Ismail", day: "Monday", start: "08:00", end: "10:00", room: "Lab Elektrik 1", classType: "Theory", weekRange: "1-18", validation: "Valid" },
  { row: 2, session: "2025/2026", semester: 2, program: "Electrical Installation", section: "ELI-1B", subjectCode: "EE102", subjectName: "Electrical Installation Practice", lecturer: "Puan Siti Nurhaliza", day: "Monday", start: "10:15", end: "12:15", room: "Lab Elektrik 2", classType: "Practical", weekRange: "1-18", validation: "Valid" },
  { row: 3, session: "2025/2026", semester: 2, program: "Electrical Installation", section: "ELI-1A", subjectCode: "EE103", subjectName: "Supply Act & Regulations", lecturer: "Encik Ahmad bin Ismail", day: "Monday", start: "08:00", end: "10:00", room: "Lecture Room A", classType: "Theory", weekRange: "1-18", validation: "Lecturer Clash", issue: "Lecturer Encik Ahmad is assigned to two classes at Monday 08:00 – 10:00. Suggested correction: reassign to another time slot or different lecturer." },
  { row: 4, session: "2025/2026", semester: 2, program: "Automotive Technology", section: "AUTO-2A", subjectCode: "AT201", subjectName: "Automotive Service Practice", lecturer: "Encik Razak bin Hamid", day: "Tuesday", start: "13:30", end: "", room: "Bengkel Automotif", classType: "Practical", weekRange: "1-18", validation: "Missing Data", issue: "End time is missing for this slot. Suggested correction: provide a valid end time." },
  { row: 5, session: "2025/2026", semester: 2, program: "Welding Technology", section: "WELD-1A", subjectCode: "WT101", subjectName: "Welding Practical", lecturer: "Encik Faizal bin Omar", day: "Wednesday", start: "08:00", end: "10:00", room: "Bengkel Kimpalan", classType: "Practical", weekRange: "1-18", validation: "Valid" },
  { row: 6, session: "2025/2026", semester: 2, program: "Mechanical Maintenance", section: "MECH-2B", subjectCode: "MM201", subjectName: "Mechanical Maintenance", lecturer: "Puan Norazlin", day: "Wednesday", start: "10:15", end: "12:15", room: "Lab Elektrik 1", classType: "Theory", weekRange: "1-18", validation: "Room Clash", issue: "Room Lab Elektrik 1 is double-booked at Wednesday 10:15 – 12:15. Suggested correction: assign a different room." },
  { row: 7, session: "2025/2026", semester: 2, program: "Air Conditioning Technology", section: "AC-1C", subjectCode: "AC101", subjectName: "Air Conditioning System", lecturer: "Encik Khairul bin Anuar", day: "Thursday", start: "13:30", end: "15:30", room: "Lecture Room B", classType: "Theory", weekRange: "1-18", validation: "Valid" },
  { row: 8, session: "2025/2026", semester: 2, program: "Electrical Installation", section: "ELI-1A", subjectCode: "EE101", subjectName: "Electrical Installation Theory", lecturer: "Encik Ahmad bin Ismail", day: "Monday", start: "08:00", end: "10:00", room: "Lab Elektrik 1", classType: "Theory", weekRange: "1-18", validation: "Duplicate Slot", issue: "This slot already exists in row 1. Suggested correction: remove duplicate entry." },
];

function M4() {
  const { setTimetable } = useApp();
  const [preview, setPreview] = React.useState<Preview[]>([]);
  const [issue, setIssue] = React.useState<Preview | null>(null);
  const [manualOpen, setManualOpen] = React.useState(false);

  const counts = {
    total: preview.length,
    valid: preview.filter((p) => p.validation === "Valid").length,
    missing: preview.filter((p) => p.validation === "Missing Data").length,
    lecCl: preview.filter((p) => p.validation === "Lecturer Clash").length,
    roomCl: preview.filter((p) => p.validation === "Room Clash").length,
    dup: preview.filter((p) => p.validation === "Duplicate Slot").length,
    invTime: preview.filter((p) => p.validation === "Invalid Time").length,
  };

  const upload = () => { setPreview(SAMPLE); toast.success("Timetable file uploaded successfully. Please review the preview below."); };

  return (
    <div className="space-y-5">
      <PageHeader
        title="M4: Upload Time Schedule / Muat Naik Jadual Waktu"
        subtitle="Upload timetable so the system creates attendance sessions linked to slots."
        actions={<>
          <Button variant="outline" size="sm" onClick={() => toast.success("Template downloaded")}><Download className="h-4 w-4 mr-1.5" /> Download Template</Button>
          <Button size="sm" onClick={() => setManualOpen(true)}><Plus className="h-4 w-4 mr-1.5" /> Add Slot Manually</Button>
        </>}
      />

      <Card>
        <CardContent className="p-6">
          <div className="border-2 border-dashed rounded-lg p-10 text-center hover:bg-muted/30 transition-colors">
            <Upload className="h-10 w-10 mx-auto text-muted-foreground mb-3" />
            <p className="text-sm font-medium">Drag and drop timetable file here</p>
            <p className="text-xs text-muted-foreground mt-1">Supported formats: CSV, Excel (.xlsx)</p>
            <Button className="mt-4" onClick={upload}><Upload className="h-4 w-4 mr-1.5" /> Upload Timetable</Button>
          </div>
        </CardContent>
      </Card>

      {preview.length > 0 && (
        <>
          <div className="grid grid-cols-2 md:grid-cols-4 lg:grid-cols-7 gap-3">
            <StatCard label="Total Rows" value={counts.total} />
            <StatCard label="Valid" value={counts.valid} tone="success" />
            <StatCard label="Missing Data" value={counts.missing} tone="warning" />
            <StatCard label="Lecturer Clash" value={counts.lecCl} tone="destructive" />
            <StatCard label="Room Clash" value={counts.roomCl} tone="destructive" />
            <StatCard label="Duplicate" value={counts.dup} tone="destructive" />
            <StatCard label="Invalid Time" value={counts.invTime} tone="destructive" />
          </div>

          <Card>
            <CardHeader><CardTitle className="text-base">Timetable Preview</CardTitle></CardHeader>
            <CardContent className="p-0 overflow-x-auto">
              <table className="w-full text-xs">
                <thead className="text-muted-foreground border-b bg-muted/40">
                  <tr>{["#", "Session", "Sem", "Program", "Section", "Code", "Subject", "Lecturer", "Day", "Start", "End", "Room", "Type", "Weeks", "Validation", "Action"].map((h) => <th key={h} className="text-left p-2 whitespace-nowrap">{h}</th>)}</tr>
                </thead>
                <tbody>
                  {preview.map((p) => (
                    <tr key={p.row} className="border-b last:border-0">
                      <td className="p-2">{p.row}</td><td className="p-2">{p.session}</td><td className="p-2">{p.semester}</td>
                      <td className="p-2">{p.program}</td><td className="p-2">{p.section}</td><td className="p-2 font-mono">{p.subjectCode}</td>
                      <td className="p-2">{p.subjectName}</td><td className="p-2">{p.lecturer}</td><td className="p-2">{p.day}</td>
                      <td className="p-2">{p.start}</td><td className="p-2">{p.end || "—"}</td><td className="p-2">{p.room}</td>
                      <td className="p-2">{p.classType}</td><td className="p-2">{p.weekRange}</td>
                      <td className="p-2"><StatusBadge status={p.validation} /></td>
                      <td className="p-2">{p.issue && <Button size="sm" variant="ghost" className="h-7 px-2" onClick={() => setIssue(p)}><AlertCircle className="h-3.5 w-3.5" /></Button>}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </CardContent>
          </Card>

          <div className="flex flex-wrap gap-2 justify-end">
            <Button variant="outline" onClick={() => toast.success("Validation completed")}>Validate Timetable</Button>
            <Button variant="outline" onClick={() => { setPreview([]); toast("Upload cleared"); }}>Clear Upload</Button>
            <Button variant="outline" onClick={() => toast.success("Timetable exported")}>Export Timetable</Button>
            <Button onClick={() => { toast.success("Timetable saved successfully. Lecturers can now view their timetable slots."); }}>Save Valid Timetable</Button>
          </div>
        </>
      )}

      <Dialog open={!!issue} onOpenChange={(o) => !o && setIssue(null)}>
        <DialogContent>
          <DialogHeader><DialogTitle>Validation Issue – Row {issue?.row}</DialogTitle></DialogHeader>
          {issue && (
            <div className="space-y-3 text-sm">
              <div><span className="text-muted-foreground">Type: </span><StatusBadge status={issue.validation} /></div>
              <div className="bg-warning/10 border-l-4 border-warning rounded p-3 text-sm">{issue.issue}</div>
            </div>
          )}
        </DialogContent>
      </Dialog>

      <Dialog open={manualOpen} onOpenChange={setManualOpen}>
        <DialogContent className="max-w-2xl">
          <DialogHeader><DialogTitle>Add Timetable Slot</DialogTitle></DialogHeader>
          <div className="grid grid-cols-2 gap-3">
            <F label="Session"><Input className="h-9" defaultValue="2025/2026" /></F>
            <F label="Semester"><Input className="h-9" type="number" defaultValue={2} /></F>
            <F label="Program"><Sel options={["Electrical Installation","Automotive Technology","Welding Technology","Mechanical Maintenance","Air Conditioning Technology","Computer System Technology"]} /></F>
            <F label="Section"><Sel options={SECTIONS} /></F>
            <F label="Subject Code"><Sel options={SUBJECTS.map((s) => s.code)} /></F>
            <F label="Subject Name"><Input className="h-9" /></F>
            <F label="Lecturer"><Sel options={LECTURERS.map((l) => l.name)} /></F>
            <F label="Day"><Sel options={["Monday","Tuesday","Wednesday","Thursday","Friday"]} /></F>
            <F label="Start"><Input className="h-9" type="time" /></F>
            <F label="End"><Input className="h-9" type="time" /></F>
            <F label="Room"><Sel options={ROOMS} /></F>
            <F label="Class Type"><Sel options={["Theory","Practical"]} /></F>
            <F label="Week Range"><Input className="h-9" defaultValue="1-18" /></F>
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setManualOpen(false)}>Cancel</Button>
            <Button onClick={() => { toast.success("Slot saved"); setManualOpen(false); }}>Save Slot</Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}

function F({ label, children }: { label: string; children: React.ReactNode }) {
  return <div><Label className="text-xs">{label}</Label><div className="mt-1">{children}</div></div>;
}
function Sel({ options }: { options: string[] }) {
  return (
    <Select><SelectTrigger className="h-9"><SelectValue placeholder="Select" /></SelectTrigger>
      <SelectContent>{options.map((o) => <SelectItem key={o} value={o}>{o}</SelectItem>)}</SelectContent>
    </Select>
  );
}