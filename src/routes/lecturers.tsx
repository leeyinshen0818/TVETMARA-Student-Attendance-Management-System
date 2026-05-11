import * as React from "react";
import { createFileRoute, Link } from "@tanstack/react-router";
import { toast } from "sonner";
import { CalendarDays, ClipboardCheck, Mail } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { PageHeader } from "@/components/page-header";
import { useApp } from "@/lib/store";

export const Route = createFileRoute("/lecturers")({ component: LecturersPage });

function LecturersPage() {
  const { lecturers, timetable, currentUser } = useApp();
  const [department, setDepartment] = React.useState("All");
  const [subject, setSubject] = React.useState("All");
  const [section, setSection] = React.useState("All");
  const [q, setQ] = React.useState("");

  const departments = Array.from(new Set(lecturers.map((l) => l.department)));
  const subjects = Array.from(new Set(lecturers.flatMap((l) => l.subjects)));
  const sections = Array.from(new Set(timetable.map((t) => t.section)));
  const filtered = lecturers.filter((lecturer) => {
    const slots = timetable.filter((slot) => slot.lecturerId === lecturer.id);
    const lecturerSections = Array.from(new Set(slots.map((slot) => slot.section)));
    const matchesSearch = !q || [lecturer.id, lecturer.name, lecturer.email, lecturer.department].some((value) => value.toLowerCase().includes(q.toLowerCase()));
    return (
      (department === "All" || lecturer.department === department) &&
      (subject === "All" || lecturer.subjects.includes(subject)) &&
      (section === "All" || lecturerSections.includes(section)) &&
      matchesSearch
    );
  });

  if (currentUser?.role === "lecturer") {
    const lecturer = lecturers.find((item) => item.id === currentUser.id || item.email === currentUser.email || item.name === currentUser.name);
    return (
      <div className="space-y-5">
        <PageHeader title="My Profile" subtitle="Manage your account information and settings." />
        <Card>
          <CardContent className="p-6 space-y-6">
            <div className="space-y-4">
              <h3 className="text-lg font-medium">Account Information</h3>
              <div className="grid gap-4 md:grid-cols-2">
                <div className="space-y-2">
                  <Label>Name</Label>
                  <Input defaultValue={lecturer?.name || currentUser.name} />
                </div>
                <div className="space-y-2">
                  <Label>Email</Label>
                  <Input defaultValue={lecturer?.email || currentUser.email} type="email" />
                </div>
                <div className="space-y-2">
                  <Label>Lecturer ID</Label>
                  <Input defaultValue={lecturer?.id || currentUser.id} disabled />
                </div>
                <div className="space-y-2">
                  <Label>Department</Label>
                  <Input defaultValue={lecturer?.department || currentUser.department || ""} disabled />
                </div>
              </div>
            </div>

            <div className="space-y-4">
              <h3 className="text-lg font-medium">Security</h3>
              <div className="grid gap-4 md:grid-cols-2">
                <div className="space-y-2">
                  <Label>New Password</Label>
                  <Input type="password" placeholder="••••••••" />
                </div>
                <div className="space-y-2">
                  <Label>Confirm Password</Label>
                  <Input type="password" placeholder="••••••••" />
                </div>
              </div>
            </div>

            <div className="flex justify-end pt-4">
              <Button onClick={() => toast.success("Profile updated successfully")}>Save Changes</Button>
            </div>
          </CardContent>
        </Card>
      </div>
    );
  }

  return (
    <div className="space-y-5">
      <PageHeader title="Lecturer Records" />
      <Card>
        <CardContent className="grid grid-cols-2 md:grid-cols-4 gap-3 p-4">
          <Filter label="Department" value={department} options={departments} onChange={setDepartment} />
          <Filter label="Subject" value={subject} options={subjects} onChange={setSubject} />
          <Filter label="Class" value={section} options={sections} onChange={setSection} />
          <div>
            <Label className="text-xs">Search</Label>
            <Input className="h-9 mt-1" value={q} onChange={(event) => setQ(event.target.value)} placeholder="Name, email, ID" />
          </div>
        </CardContent>
      </Card>
      <Card><CardContent className="p-0 overflow-x-auto">
        <table className="w-full text-sm">
          <thead className="text-xs text-muted-foreground border-b bg-muted/40"><tr>{["ID","Name","Email","Department","Subjects","Sections","Classes / Week","Action"].map((h) => <th key={h} className="text-left p-2">{h}</th>)}</tr></thead>
          <tbody>
            {filtered.map((l) => {
              const slots = timetable.filter((t) => t.lecturerId === l.id);
              const sections = Array.from(new Set(slots.map((s) => s.section)));
              return (
                <tr key={l.id} className="border-b last:border-0">
                  <td className="p-2 font-mono text-xs">{l.id}</td><td className="p-2 font-medium">{l.name}</td><td className="p-2 text-xs">{l.email}</td>
                  <td className="p-2">{l.department}</td><td className="p-2 text-xs">{l.subjects.join(", ")}</td><td className="p-2 text-xs">{sections.join(", ") || "—"}</td>
                  <td className="p-2 font-bold">{slots.length}</td>
                  <td className="p-2"><div className="flex gap-1">
                    <Button asChild size="sm" variant="ghost" className="h-7 px-2"><Link to="/m5"><CalendarDays className="h-3.5 w-3.5" /></Link></Button>
                    <Button asChild size="sm" variant="ghost" className="h-7 px-2"><Link to="/m3"><ClipboardCheck className="h-3.5 w-3.5" /></Link></Button>
                    <Button size="sm" variant="ghost" className="h-7 px-2" onClick={() => toast.success("Email composer opened")}><Mail className="h-3.5 w-3.5" /></Button>
                  </div></td>
                </tr>
              );
            })}
          </tbody>
        </table>
      </CardContent></Card>
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
