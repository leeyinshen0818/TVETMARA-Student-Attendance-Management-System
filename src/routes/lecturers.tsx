import { createFileRoute, Link } from "@tanstack/react-router";
import { toast } from "sonner";
import { CalendarDays, ClipboardCheck, Mail } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { PageHeader } from "@/components/page-header";
import { useApp } from "@/lib/store";

export const Route = createFileRoute("/lecturers")({ component: LecturersPage });

function LecturersPage() {
  const { lecturers, timetable } = useApp();
  return (
    <div className="space-y-5">
      <PageHeader title="Lecturer Records / Rekod Pensyarah" />
      <Card><CardContent className="p-0 overflow-x-auto">
        <table className="w-full text-sm">
          <thead className="text-xs text-muted-foreground border-b bg-muted/40"><tr>{["ID","Name","Email","Department","Subjects","Sections","Classes / Week","Action"].map((h) => <th key={h} className="text-left p-2">{h}</th>)}</tr></thead>
          <tbody>
            {lecturers.map((l) => {
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