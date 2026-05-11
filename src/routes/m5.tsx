import * as React from "react";
import { createFileRoute, Link } from "@tanstack/react-router";
import { toast } from "sonner";
import { CalendarPlus, ClipboardCheck, Download, FileSpreadsheet, Search, X } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { PageHeader } from "@/components/page-header";
import { StatCard } from "@/components/stat-card";
import { StatusBadge } from "@/components/status-badge";
import { useApp } from "@/lib/store";
import { LECTURERS, STUDENTS } from "@/lib/mock-data";

export const Route = createFileRoute("/m5")({ component: M5 });

const ALL = "All";

function M5() {
  const { timetable: allTimetable, setTimetable, currentUser } = useApp();
  const [filters, setFilters] = React.useState({
    semester: ALL,
    lecturer: ALL,
    program: ALL,
    section: ALL,
    q: "",
  });

  const scopedTimetable = currentUser?.role === "lecturer"
    ? allTimetable.filter((t) => t.lecturerId === currentUser.id)
    : allTimetable;

  const optionRows = scopedTimetable
    .filter((t) => filters.semester === ALL || String(t.semester) === filters.semester)
    .filter((t) => filters.program === ALL || t.program === filters.program)
    .filter((t) => filters.section === ALL || t.section === filters.section);

  const options = {
    semester: Array.from(
      new Set(
        scopedTimetable
          .filter((t) => filters.program === ALL || t.program === filters.program)
          .filter((t) => filters.section === ALL || t.section === filters.section)
          .map((t) => String(t.semester)),
      ),
    ).sort(),
    lecturer: Array.from(new Set(optionRows.map((t) => t.lecturerName))).sort(),
    program: Array.from(
      new Set(
        scopedTimetable
          .filter((t) => filters.semester === ALL || String(t.semester) === filters.semester)
          .filter((t) => filters.section === ALL || t.section === filters.section)
          .map((t) => t.program),
      ),
    ).sort(),
    section: Array.from(
      new Set(
        scopedTimetable
          .filter((t) => filters.semester === ALL || String(t.semester) === filters.semester)
          .filter((t) => filters.program === ALL || t.program === filters.program)
          .map((t) => t.section),
      ),
    ).sort(),
  };

  const timetable = scopedTimetable
    .filter((t) => filters.semester === ALL || String(t.semester) === filters.semester)
    .filter((t) => filters.lecturer === ALL || t.lecturerName === filters.lecturer)
    .filter((t) => filters.program === ALL || t.program === filters.program)
    .filter((t) => filters.section === ALL || t.section === filters.section)
    .filter((t) => {
      const q = filters.q.toLowerCase();
      return !q || [t.subjectCode, t.subjectName, t.section, t.room, t.lecturerName].some((value) => value.toLowerCase().includes(q));
    })
    .sort((a, b) => `${a.date}${a.startTime}`.localeCompare(`${b.date}${b.startTime}`));

  const setF = (key: keyof typeof filters) => (value: string) =>
    setFilters((prev) => {
      const next = { ...prev, [key]: value };
      if (key === "semester" || key === "program") {
        next.section = ALL;
        next.lecturer = ALL;
      }
      if (key === "section") {
        next.lecturer = ALL;
      }
      return next;
    });

  const cancelClass = (id: string) => {
    setTimetable((prev) => prev.map((t) => (t.id === id ? { ...t, status: "Cancelled" as const } : t)));
    toast.success("Class cancelled");
  };

  const downloadCsv = () => {
    const headers = ["Date", "Day", "Start", "End", "Course", "Section", "Registered/Capacity", "Class Code", "Subject", "Lecturer", "Location", "Semester", "Type"];
    const rows = timetable.map((t) => [t.date, t.day, t.startTime, t.endTime, t.program, t.section, capacityText(t), t.subjectCode, t.subjectName, t.lecturerName, t.room, t.semester, t.classType]);
    const csv = [headers, ...rows].map((row) => row.map((cell) => `"${String(cell).replace(/"/g, '""')}"`).join(",")).join("\n");
    const blob = new Blob([csv], { type: "text/csv;charset=utf-8" });
    const url = URL.createObjectURL(blob);
    const link = document.createElement("a");
    link.href = url;
    link.download = "tvetmara-timetable-slots.csv";
    link.click();
    URL.revokeObjectURL(url);
  };

  return (
    <div className="space-y-5">
      <PageHeader
        title={currentUser?.role === "lecturer" ? "My Timetable" : "Showing Timetable Slot"}
        subtitle={currentUser?.role === "lecturer" ? "Your assigned section timetable in official format." : "Official timetable slot view for sharing with students and lecturers."}
        actions={
          <Button variant="outline" size="sm" onClick={downloadCsv}>
            <Download className="h-4 w-4 mr-1.5" /> Download CSV
          </Button>
        }
      />

      <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
        <StatCard label="Total Slots" value={timetable.length} />
        <StatCard label="Replacement" value={timetable.filter((t) => t.slotType === "Replacement Class").length} tone="replacement" />
        <StatCard label="Section" value={Array.from(new Set(timetable.map((t) => t.section))).length} tone="info" />
        <StatCard label="Available Seats" value={timetable.reduce((sum, t) => sum + Math.max(0, (t.capacity ?? 0) - (t.enrolled ?? 0)), 0)} tone="success" />
      </div>

      <Card>
        <CardHeader className="pb-3">
          <CardTitle className="text-sm flex items-center gap-2">
            <Search className="h-4 w-4" /> Filters
          </CardTitle>
        </CardHeader>
        <CardContent className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-6 gap-3">
          <Filter label="Semester" value={filters.semester} options={options.semester} onChange={setF("semester")} />
          <Filter label="Lecturer" value={filters.lecturer} options={options.lecturer} onChange={setF("lecturer")} />
          <Filter label="Course" value={filters.program} options={options.program} onChange={setF("program")} />
          <Filter label="Section" value={filters.section} options={options.section} onChange={setF("section")} />
          <div>
            <Label className="text-xs">Search</Label>
            <Input className="h-9 mt-1" value={filters.q} onChange={(e) => setF("q")(e.target.value)} placeholder="Kod, subjek, bilik" />
          </div>
        </CardContent>
      </Card>

      <Card>
        <CardHeader className="flex flex-row items-center justify-between">
          <CardTitle className="text-base flex items-center gap-2">
            <FileSpreadsheet className="h-4 w-4" /> Official Timetable Slots
          </CardTitle>
          <div className="text-xs text-muted-foreground">{timetable.length} record(s)</div>
        </CardHeader>
        <CardContent className="p-0 overflow-x-auto">
          <table className="w-full min-w-[1200px] border-collapse text-xs">
            <thead>
              <tr className="bg-slate-800 text-white">
                <th colSpan={11} className="p-2 text-center text-base">TIMETABLE FOR SEMESTER {filters.semester === ALL ? "SEMUA" : filters.semester}, SESSION 2025/2026</th>
              </tr>
              <tr className="bg-slate-700 text-white">
                <th colSpan={11} className="p-2 text-center">SHOWING TIMETABLE SLOT / PAPARAN SLOT JADUAL</th>
              </tr>
              <tr className="bg-orange-100">
                {["NO.", "CODE", "NAMA KURSUS", "SEKSYEN", "PROGRAM", "CAPACITY", "HARI/MASA LOKASI", "PENSYARAH", "EMAIL", "JENIS", "TINDAKAN"].map((h) => (
                  <th key={h} className="border p-2 text-left whitespace-nowrap">{h}</th>
                ))}
              </tr>
            </thead>
            <tbody>
              {timetable.map((t, index) => {
                const lecturer = LECTURERS.find((item) => item.id === t.lecturerId || item.name === t.lecturerName);
                return (
                <tr key={t.id} className="hover:bg-muted/30">
                  <td className="border p-2 text-center">{index + 1}</td>
                  <td className="border p-2 font-mono">{t.subjectCode}</td>
                  <td className="border p-2">{t.subjectName}</td>
                  <td className="border p-2 text-center font-medium">{t.section}</td>
                  <td className="border p-2 text-center">{t.program}</td>
                  <td className="border p-2 text-center font-medium">{capacityText(t)}</td>
                  <td className="border p-2 text-center">
                    <div className="font-semibold">{t.day.slice(0, 3).toUpperCase()}</div>
                    <div>{t.startTime}-{t.endTime}</div>
                    <div>{t.room}</div>
                  </td>
                  <td className="border p-2">{t.lecturerName}</td>
                  <td className="border p-2 text-center">{lecturer?.email.split("@")[0] || "-"}</td>
                  <td className="border p-2"><StatusBadge status={t.slotType} /></td>
                  <td className="border p-2">
                    <div className="flex gap-1">
                      {currentUser?.role === "lecturer" && (
                        <>
                          <Button asChild size="sm" variant="outline" className="h-7 text-xs">
                            <Link to="/m1" search={{ slot: t.id }}>
                              <ClipboardCheck className="h-3 w-3 mr-1" /> Take
                            </Link>
                          </Button>
                          <Button asChild size="sm" variant="ghost" className="h-7 text-xs">
                            <Link to="/m6" search={{ slot: t.id }}>
                              <CalendarPlus className="h-3 w-3 mr-1" /> Replace
                            </Link>
                          </Button>
                        </>
                      )}
                      {currentUser?.role === "admin" && (
                        <Button size="sm" variant="ghost" className="h-7 text-xs text-destructive" onClick={() => cancelClass(t.id)}>
                          <X className="h-3 w-3 mr-1" /> Cancel
                        </Button>
                      )}
                    </div>
                  </td>
                </tr>
              )})}
            </tbody>
          </table>
        </CardContent>
      </Card>
    </div>
  );
}

function Filter({ label, value, options, onChange }: { label: string; value: string; options: string[]; onChange: (value: string) => void }) {
  return (
    <div>
      <Label className="text-xs">{label}</Label>
      <Select value={value} onValueChange={onChange}>
        <SelectTrigger className="h-9 mt-1"><SelectValue /></SelectTrigger>
        <SelectContent>
          <SelectItem value={ALL}>All</SelectItem>
          {options.map((option) => (
            <SelectItem key={option} value={option}>{option}</SelectItem>
          ))}
        </SelectContent>
      </Select>
    </div>
  );
}

function capacityText(t: { section: string; enrolled?: number; capacity?: number }) {
  const enrolled = t.enrolled ?? STUDENTS.filter((student) => student.section === t.section).length;
  const capacity = t.capacity ?? enrolled + 2;
  return `${enrolled}/${capacity}`;
}
