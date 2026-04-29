import { GraduationCap, ShieldCheck, BookOpen, Briefcase } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card";
import { useApp } from "@/lib/store";
import type { Role } from "@/lib/mock-data";

export function LoginPage() {
  const { login } = useApp();
  const roles: { role: Role; title: string; desc: string; icon: any; cls: string }[] = [
    { role: "admin", title: "Login as Admin", desc: "Manage users, timetable, approvals & all data", icon: ShieldCheck, cls: "bg-primary text-primary-foreground hover:bg-primary/90" },
    { role: "lecturer", title: "Login as Lecturer", desc: "Take attendance, view timetable, report issues", icon: BookOpen, cls: "bg-success text-success-foreground hover:bg-success/90" },
    { role: "staff", title: "Login as Academic Staff", desc: "Monitor attendance trends, view & export reports", icon: Briefcase, cls: "bg-info text-info-foreground hover:bg-info/90" },
  ];
  return (
    <div className="min-h-screen w-full grid lg:grid-cols-2 bg-muted/30">
      <div className="hidden lg:flex flex-col justify-between bg-sidebar text-sidebar-foreground p-10">
        <div className="flex items-center gap-3">
          <div className="flex h-10 w-10 items-center justify-center rounded-md bg-sidebar-primary text-sidebar-primary-foreground">
            <GraduationCap className="h-6 w-6" />
          </div>
          <div>
            <div className="font-bold">TVETMARA</div>
            <div className="text-xs text-sidebar-foreground/70">Johor Bahru</div>
          </div>
        </div>
        <div>
          <h1 className="text-3xl font-bold">Student Attendance Management System</h1>
          <p className="mt-3 text-sidebar-foreground/80 max-w-md">
            Centralised platform for taking attendance, managing timetable slots, reporting discipline issues, and booking replacement classes.
          </p>
          <ul className="mt-6 space-y-2 text-sm text-sidebar-foreground/80">
            <li>• M1–M6 Attendance Modules</li>
            <li>• Real-time reporting & alerts</li>
            <li>• Admin · Lecturer · Academic Staff roles</li>
          </ul>
        </div>
        <div className="text-xs text-sidebar-foreground/60">© 2026 TVETMARA Johor Bahru. Prototype build.</div>
      </div>
      <div className="flex items-center justify-center p-6 sm:p-10">
        <Card className="w-full max-w-md">
          <CardHeader>
            <div className="flex lg:hidden items-center gap-3 mb-4">
              <div className="flex h-10 w-10 items-center justify-center rounded-md bg-primary text-primary-foreground">
                <GraduationCap className="h-6 w-6" />
              </div>
              <div>
                <div className="font-bold">TVETMARA</div>
                <div className="text-xs text-muted-foreground">Attendance System</div>
              </div>
            </div>
            <CardTitle>Sign in</CardTitle>
            <CardDescription>Select a demo role to enter the system / Pilih peranan untuk log masuk</CardDescription>
          </CardHeader>
          <CardContent className="space-y-3">
            {roles.map((r) => (
              <Button key={r.role} onClick={() => login(r.role)} className={`w-full justify-start h-auto py-3 ${r.cls}`}>
                <r.icon className="h-5 w-5 mr-3 shrink-0" />
                <div className="text-left">
                  <div className="font-semibold text-sm">{r.title}</div>
                  <div className="text-[11px] opacity-90 font-normal">{r.desc}</div>
                </div>
              </Button>
            ))}
            <p className="text-[11px] text-muted-foreground pt-2">
              Prototype demo. No real authentication is performed.
            </p>
          </CardContent>
        </Card>
      </div>
    </div>
  );
}