import * as React from "react";
import { createFileRoute, Link } from "@tanstack/react-router";
import { toast } from "sonner";
import { ClipboardCheck, QrCode, AlertTriangle, CalendarPlus, X, Eye } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card";
import { Tabs, TabsList, TabsTrigger, TabsContent } from "@/components/ui/tabs";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Label } from "@/components/ui/label";
import { PageHeader } from "@/components/page-header";
import { StatCard } from "@/components/stat-card";
import { StatusBadge } from "@/components/status-badge";
import { useApp } from "@/lib/store";
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter } from "@/components/ui/dialog";

export const Route = createFileRoute("/m5")({ component: M5 });

const DAYS = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"];

function M5() {
  const { timetable: allTimetable, setTimetable, currentUser } = useApp();
  const [qr, setQr] = React.useState<string | null>(null);
  const today = "2026-04-29";

  const timetable = currentUser?.role === "lecturer"
    ? allTimetable.filter((t) => t.lecturerId === currentUser.id)
    : allTimetable;

  const todays = timetable.filter((t) => t.date === today).sort((a, b) => a.startTime.localeCompare(b.startTime));
  const replacement = timetable.filter((t) => t.slotType === "Replacement Class");
  const cancelClass = (id: string) => { setTimetable((p) => p.map((t) => (t.id === id ? { ...t, status: "Cancelled" as const } : t))); toast.success("Class cancelled"); };

  const titleByRole = currentUser?.role === "lecturer"
    ? "My Timetable / Jadual Saya"
    : "Timetable Management / Pengurusan Jadual Waktu";

  return (
    <div className="space-y-5">
      <PageHeader title={titleByRole} subtitle={currentUser?.role === "lecturer" ? "Your assigned classes only." : "All scheduled classes & quick access to attendance."} />

      <Card>
        <CardHeader className="pb-3"><CardTitle className="text-sm">Filters</CardTitle></CardHeader>
        <CardContent className="grid grid-cols-2 md:grid-cols-4 lg:grid-cols-7 gap-3">
          {["Lecturer", "Program", "Section", "Subject", "Room", "Date", "Status"].map((f) => (
            <div key={f}><Label className="text-xs">{f}</Label><Select><SelectTrigger className="h-9 mt-1"><SelectValue placeholder="All" /></SelectTrigger><SelectContent><SelectItem value="all">All</SelectItem></SelectContent></Select></div>
          ))}
        </CardContent>
      </Card>

      <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-5 gap-3">
        <StatCard label="Classes Today" value={todays.length} />
        <StatCard label="Completed" value={todays.filter((t) => t.status === "Attendance Completed").length} tone="success" />
        <StatCard label="Pending" value={todays.filter((t) => t.status === "Attendance Not Taken" || t.status === "Attendance Pending").length} tone="warning" />
        <StatCard label="Replacement" value={replacement.length} tone="replacement" />
        <StatCard label="Cancelled" value={timetable.filter((t) => t.status === "Cancelled").length} tone="destructive" />
      </div>

      <Tabs defaultValue="today">
        <TabsList>
          <TabsTrigger value="today">Today's Schedule</TabsTrigger>
          <TabsTrigger value="weekly">Weekly</TabsTrigger>
          <TabsTrigger value="calendar">Calendar</TabsTrigger>
          <TabsTrigger value="list">List</TabsTrigger>
        </TabsList>

        <TabsContent value="today">
          <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-3">
            {todays.map((t) => (
              <Card key={t.id} className="hover:shadow-md transition-shadow">
                <CardHeader className="pb-2">
                  <div className="flex items-start justify-between gap-2">
                    <div className="min-w-0">
                      <CardTitle className="text-sm">{t.subjectName}</CardTitle>
                      <CardDescription className="text-xs">{t.subjectCode} · {t.section}</CardDescription>
                    </div>
                    <StatusBadge status={t.slotType} />
                  </div>
                </CardHeader>
                <CardContent className="space-y-2 text-xs">
                  <div className="flex justify-between"><span className="text-muted-foreground">Time</span><span className="font-semibold">{t.startTime} – {t.endTime}</span></div>
                  <div className="flex justify-between"><span className="text-muted-foreground">Room</span><span>{t.room}</span></div>
                  <div className="flex justify-between"><span className="text-muted-foreground">Lecturer</span><span className="text-right">{t.lecturerName}</span></div>
                  <div className="flex justify-between items-center"><span className="text-muted-foreground">Status</span><StatusBadge status={t.status} /></div>
                  <div className="flex flex-wrap gap-1 pt-2 border-t">
                    <Button asChild size="sm" variant="outline" className="h-7 text-xs"><Link to="/m1" search={{ slot: t.id }}><ClipboardCheck className="h-3 w-3 mr-1" />Take</Link></Button>
                    <Button size="sm" variant="ghost" className="h-7 text-xs" onClick={() => setQr(t.id)}><QrCode className="h-3 w-3 mr-1" />QR</Button>
                    <Button asChild size="sm" variant="ghost" className="h-7 text-xs"><Link to="/m2"><AlertTriangle className="h-3 w-3 mr-1" />Issue</Link></Button>
                    <Button asChild size="sm" variant="ghost" className="h-7 text-xs"><Link to="/m6" search={{ slot: t.id }}><CalendarPlus className="h-3 w-3 mr-1" />Replace</Link></Button>
                    <Button size="sm" variant="ghost" className="h-7 text-xs text-destructive" onClick={() => cancelClass(t.id)}><X className="h-3 w-3 mr-1" />Cancel</Button>
                  </div>
                </CardContent>
              </Card>
            ))}
          </div>
        </TabsContent>

        <TabsContent value="weekly">
          <Card><CardContent className="p-0 overflow-x-auto">
            <table className="w-full text-xs">
              <thead className="bg-muted/40 border-b"><tr><th className="p-2 text-left">Time</th>{DAYS.map((d) => <th key={d} className="p-2 text-left">{d}</th>)}</tr></thead>
              <tbody>
                {["08:00","10:15","13:30","15:45"].map((time) => (
                  <tr key={time} className="border-b">
                    <td className="p-2 font-semibold align-top">{time}</td>
                    {DAYS.map((day) => {
                      const slots = timetable.filter((t) => t.day === day && t.startTime === time);
                      return (
                        <td key={day} className="p-2 align-top">
                          {slots.map((s) => (
                            <div key={s.id} className={`rounded p-2 mb-1 text-[11px] ${s.slotType === "Replacement Class" ? "bg-replacement/15 border-l-2 border-replacement" : "bg-primary/10 border-l-2 border-primary"}`}>
                              <div className="font-semibold">{s.subjectCode}</div>
                              <div className="text-muted-foreground">{s.section} · {s.room}</div>
                            </div>
                          ))}
                        </td>
                      );
                    })}
                  </tr>
                ))}
              </tbody>
            </table>
          </CardContent></Card>
        </TabsContent>

        <TabsContent value="calendar">
          <Card><CardContent className="p-4">
            <div className="grid grid-cols-7 gap-1 text-xs">
              {["Sun","Mon","Tue","Wed","Thu","Fri","Sat"].map((d) => <div key={d} className="text-center text-muted-foreground font-semibold p-2">{d}</div>)}
              {Array.from({ length: 30 }).map((_, i) => {
                const day = i + 1;
                const dateStr = `2026-04-${day.toString().padStart(2, "0")}`;
                const slots = timetable.filter((t) => t.date === dateStr);
                const isToday = dateStr === today;
                return (
                  <div key={i} className={`min-h-20 border rounded p-1 ${isToday ? "bg-primary/10 border-primary" : ""}`}>
                    <div className="text-[10px] font-bold">{day}</div>
                    {slots.slice(0, 2).map((s) => (
                      <div key={s.id} className={`text-[9px] mt-0.5 truncate rounded px-1 ${s.slotType === "Replacement Class" ? "bg-replacement text-replacement-foreground" : "bg-success text-success-foreground"}`}>{s.subjectCode}</div>
                    ))}
                    {slots.length > 2 && <div className="text-[9px] text-muted-foreground">+{slots.length - 2}</div>}
                  </div>
                );
              })}
            </div>
          </CardContent></Card>
        </TabsContent>

        <TabsContent value="list">
          <Card><CardContent className="p-0 overflow-x-auto">
            <table className="w-full text-sm">
              <thead className="text-xs text-muted-foreground border-b bg-muted/40"><tr>{["Date","Day","Time","Subject","Section","Lecturer","Room","Slot","Status","Action"].map((h) => <th key={h} className="text-left p-2">{h}</th>)}</tr></thead>
              <tbody>
                {timetable.slice(0, 25).map((t) => (
                  <tr key={t.id} className="border-b last:border-0">
                    <td className="p-2">{t.date}</td><td className="p-2">{t.day}</td><td className="p-2">{t.startTime}–{t.endTime}</td>
                    <td className="p-2">{t.subjectName}</td><td className="p-2">{t.section}</td><td className="p-2 text-xs">{t.lecturerName}</td>
                    <td className="p-2 text-xs">{t.room}</td><td className="p-2"><StatusBadge status={t.slotType} /></td><td className="p-2"><StatusBadge status={t.status} /></td>
                    <td className="p-2"><Button asChild size="sm" variant="outline" className="h-7 text-xs"><Link to="/m1" search={{ slot: t.id }}>Open</Link></Button></td>
                  </tr>
                ))}
              </tbody>
            </table>
          </CardContent></Card>
        </TabsContent>
      </Tabs>

      <Dialog open={!!qr} onOpenChange={(o) => !o && setQr(null)}>
        <DialogContent>
          <DialogHeader><DialogTitle>QR Attendance</DialogTitle></DialogHeader>
          <div className="grid place-items-center py-2">
            <div className="h-44 w-44 grid grid-cols-8 grid-rows-8 gap-0.5 bg-white p-2 rounded border-4 border-foreground/10">
              {Array.from({ length: 64 }).map((_, i) => <div key={i} className={(i * 7 + (qr?.length || 0)) % 3 === 0 ? "bg-foreground" : ""} />)}
            </div>
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => { navigator.clipboard?.writeText(`https://forms.tvetmara.edu.my/att/${qr}`); toast.success("Link copied"); }}>Copy Link</Button>
            <Button onClick={() => setQr(null)}>Close</Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}