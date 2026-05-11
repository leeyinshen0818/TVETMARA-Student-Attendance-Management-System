import * as React from "react";
import { createFileRoute } from "@tanstack/react-router";
import { toast } from "sonner";
import { Eye, Mail, History } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Dialog, DialogContent, DialogFooter, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Textarea } from "@/components/ui/textarea";
import { PageHeader } from "@/components/page-header";
import { StatusBadge } from "@/components/status-badge";
import { useApp } from "@/lib/store";
import type { Student } from "@/lib/mock-data";

export const Route = createFileRoute("/students")({ component: StudentsPage });

function StudentsPage() {
  const { students: allStudents, timetable, currentUser } = useApp();
  const isLecturer = currentUser?.role === "lecturer";
  const sections = isLecturer
    ? Array.from(new Set(timetable.filter((t) => t.lecturerId === currentUser?.id).map((t) => t.section)))
    : null;
  const students = sections ? allStudents.filter((s) => sections.includes(s.section)) : allStudents;
  const [q, setQ] = React.useState("");
  const [course, setCourse] = React.useState("All");
  const [section, setSection] = React.useState("All");
  const [semester, setSemester] = React.useState("All");
  const [profile, setProfile] = React.useState<Student | null>(null);
  const [contact, setContact] = React.useState<Student | null>(null);
  const courses = Array.from(new Set(students.map((s) => s.program)));
  const classOptions = Array.from(new Set(students.map((s) => s.section)));
  const semesters = Array.from(new Set(students.map((s) => String(s.semester))));
  const filtered = students
    .filter((s) => course === "All" || s.program === course)
    .filter((s) => section === "All" || s.section === section)
    .filter((s) => semester === "All" || String(s.semester) === semester)
    .filter((s) => s.name.toLowerCase().includes(q.toLowerCase()) || s.id.includes(q) || s.section.toLowerCase().includes(q.toLowerCase()));

  return (
    <div className="space-y-5">
      <PageHeader
        title={isLecturer ? "My Students" : "Student Records"}
        subtitle={isLecturer ? "Students enrolled in your assigned classes." : "View student profiles, attendance summary and contact info."}
      />
      <Card>
        <CardContent className="grid grid-cols-2 md:grid-cols-4 gap-3 p-4">
          <Filter label="Course" value={course} options={courses} onChange={setCourse} />
          <Filter label="Class" value={section} options={classOptions} onChange={setSection} />
          <Filter label="Semester" value={semester} options={semesters} onChange={setSemester} />
          <div>
            <Label className="text-xs">Search</Label>
            <Input placeholder="Name, ID, class" value={q} onChange={(e) => setQ(e.target.value)} className="mt-1 h-9" />
          </div>
        </CardContent>
      </Card>
      <Card><CardContent className="p-0 overflow-x-auto">
        <table className="w-full text-sm">
          <thead className="text-xs text-muted-foreground border-b bg-muted/40"><tr>{["ID","Name","IC","Email","Phone","Program","Section","Sem","Status","Att %","Action"].map((h) => <th key={h} className="text-left p-2">{h}</th>)}</tr></thead>
          <tbody>
            {filtered.map((s) => (
              <tr key={s.id} className="border-b last:border-0 hover:bg-muted/30">
                <td className="p-2 font-mono text-xs">{s.id}</td><td className="p-2 font-medium">{s.name}</td><td className="p-2 text-xs">{s.ic}</td>
                <td className="p-2 text-xs">{s.email}</td><td className="p-2 text-xs">{s.phone}</td><td className="p-2 text-xs">{s.program}</td>
                <td className="p-2">{s.section}</td><td className="p-2">{s.semester}</td><td className="p-2"><StatusBadge status={s.status} /></td>
                <td className="p-2"><span className={s.attendance < 80 ? "text-destructive font-bold" : "font-bold"}>{s.attendance}%</span></td>
                <td className="p-2"><div className="flex gap-1">
                  <Button size="sm" variant="ghost" className="h-7 px-2" onClick={() => setProfile(s)}><Eye className="h-3.5 w-3.5" /></Button>
                  <Button size="sm" variant="ghost" className="h-7 px-2" onClick={() => setProfile(s)}><History className="h-3.5 w-3.5" /></Button>
                  <Button size="sm" variant="ghost" className="h-7 px-2" onClick={() => setContact(s)}><Mail className="h-3.5 w-3.5" /></Button>
                </div></td>
              </tr>
            ))}
          </tbody>
        </table>
      </CardContent></Card>

      <Dialog open={!!profile} onOpenChange={(o) => !o && setProfile(null)}>
        <DialogContent className="max-w-2xl">
          <DialogHeader><DialogTitle>{profile?.name}</DialogTitle></DialogHeader>
          {profile && (
            <div className="space-y-4 text-sm">
              <div className="grid grid-cols-2 md:grid-cols-3 gap-3">
                <Info label="Student ID" value={profile.id} /><Info label="IC" value={profile.ic} /><Info label="Section" value={profile.section} />
                <Info label="Email" value={profile.email} /><Info label="Phone" value={profile.phone} /><Info label="Semester" value={String(profile.semester)} />
                <Info label="Program" value={profile.program} /><Info label="Attendance" value={`${profile.attendance}%`} /><Info label="Status" value={profile.status} />
              </div>
              <div><div className="text-xs font-semibold mb-2">Subjects Attendance</div>
                <table className="w-full text-xs"><thead className="border-b text-muted-foreground"><tr><th className="text-left py-1">Subject</th><th className="text-left">Sessions</th><th className="text-left">Att %</th></tr></thead>
                  <tbody>{["EE101","EE102","EE103","EE104"].map((c, i) => <tr key={c} className="border-b last:border-0"><td className="py-1">{c}</td><td>{18 - i}</td><td className="font-bold">{75 + i * 4}%</td></tr>)}</tbody>
                </table>
              </div>
            </div>
          )}
        </DialogContent>
      </Dialog>

      <Dialog open={!!contact} onOpenChange={(o) => !o && setContact(null)}>
        <DialogContent>
          <DialogHeader><DialogTitle>Contact Student</DialogTitle></DialogHeader>
          {contact && (
            <div className="space-y-3">
              <Input className="h-9" value={contact.email} readOnly />
              <Input className="h-9" defaultValue="Attendance Reminder - TVETMARA Johor Bahru" />
              <Textarea rows={5} defaultValue={`Dear ${contact.name},\n\nThis is a reminder regarding your attendance. Please contact the academic office for follow-up.\n\nThank you.`} />
              <DialogFooter><Button variant="outline" onClick={() => setContact(null)}>Cancel</Button><Button onClick={() => { toast.success("Email sent"); setContact(null); }}>Send</Button></DialogFooter>
            </div>
          )}
        </DialogContent>
      </Dialog>
    </div>
  );
}

function Info({ label, value }: { label: string; value: string }) {
  return <div><div className="text-xs text-muted-foreground">{label}</div><div className="font-medium mt-0.5">{value}</div></div>;
}

function Filter({ label, value, options, onChange }: { label: string; value: string; options: string[]; onChange: (value: string) => void }) {
  return (
    <div>
      <Label className="text-xs">{label}</Label>
      <Select value={value} onValueChange={onChange}>
        <SelectTrigger className="h-9 mt-1"><SelectValue /></SelectTrigger>
        <SelectContent>
          <SelectItem value="All">All</SelectItem>
          {options.map((option) => <SelectItem key={option} value={option}>{option}</SelectItem>)}
        </SelectContent>
      </Select>
    </div>
  );
}
