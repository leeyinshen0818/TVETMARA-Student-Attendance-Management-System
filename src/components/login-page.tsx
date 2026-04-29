import * as React from "react";
import { toast } from "sonner";
import { GraduationCap, ShieldCheck, BookOpen, Briefcase, Lock, Mail, LogIn } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { useApp } from "@/lib/store";
import type { Role } from "@/lib/mock-data";

export const DEMO_ACCOUNTS: Record<Role, { email: string; password: string; title: string; desc: string; icon: any }> = {
  admin: { email: "admin@tvetmara.edu.my", password: "admin123", title: "Admin", desc: "System setup, users, approvals & full data", icon: ShieldCheck },
  lecturer: { email: "lecturer@tvetmara.edu.my", password: "lecturer123", title: "Lecturer", desc: "Take attendance for own classes & report issues", icon: BookOpen },
  staff: { email: "academic@tvetmara.edu.my", password: "academic123", title: "Academic Staff / Management", desc: "Monitor attendance, follow-up & reports", icon: Briefcase },
};

export function LoginPage() {
  const { loginWithEmail } = useApp();
  const [selected, setSelected] = React.useState<Role>("admin");
  const [email, setEmail] = React.useState(DEMO_ACCOUNTS.admin.email);
  const [password, setPassword] = React.useState(DEMO_ACCOUNTS.admin.password);

  const pickRole = (role: Role) => {
    setSelected(role);
    setEmail(DEMO_ACCOUNTS[role].email);
    setPassword(DEMO_ACCOUNTS[role].password);
  };

  const submit = (e: React.FormEvent) => {
    e.preventDefault();
    if (loginWithEmail(email, password)) {
      toast.success(`Welcome, ${DEMO_ACCOUNTS[selected].title}`);
    } else {
      toast.error("Invalid credentials. Please use one of the demo accounts.");
    }
  };

  const tones: Record<Role, string> = {
    admin: "border-primary bg-primary/5 ring-2 ring-primary",
    lecturer: "border-primary bg-primary/5 ring-2 ring-primary",
    staff: "border-primary bg-primary/5 ring-2 ring-primary",
  };

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
            Centralized attendance management platform for TVETMARA Johor Bahru.
          </p>
          <ul className="mt-6 space-y-2 text-sm text-sidebar-foreground/80">
            <li>• M1–M6 Attendance Modules</li>
            <li>• Real-time reporting & alerts</li>
            <li>• Admin · Lecturer · Academic Staff roles</li>
          </ul>
        </div>
        <div className="text-xs text-sidebar-foreground/60">© 2026 TVETMARA Johor Bahru. Prototype build.</div>
      </div>
      <div className="flex items-center justify-center p-4 sm:p-8 overflow-y-auto">
        <Card className="w-full max-w-lg">
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
            <CardTitle>Sign in to your account</CardTitle>
            <CardDescription>Select your role — credentials will fill automatically.</CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="grid grid-cols-1 sm:grid-cols-3 gap-2">
              {(Object.keys(DEMO_ACCOUNTS) as Role[]).map((r) => {
                const a = DEMO_ACCOUNTS[r];
                const active = selected === r;
                return (
                  <button
                    key={r}
                    type="button"
                    onClick={() => pickRole(r)}
                    className={`text-left rounded-md border p-3 transition hover:border-primary hover:bg-primary/5 ${active ? tones[r] : "border-border"}`}
                  >
                    <a.icon className={`h-5 w-5 mb-1.5 ${active ? "text-primary" : "text-muted-foreground"}`} />
                    <div className="text-xs font-semibold leading-tight">{a.title}</div>
                    <div className="text-[10px] text-muted-foreground mt-0.5 line-clamp-2">{a.desc}</div>
                  </button>
                );
              })}
            </div>

            <form onSubmit={submit} className="space-y-3">
              <div>
                <Label htmlFor="email" className="text-xs">Username / Email</Label>
                <div className="relative mt-1">
                  <Mail className="absolute left-2.5 top-2.5 h-4 w-4 text-muted-foreground" />
                  <Input id="email" type="email" value={email} onChange={(e) => setEmail(e.target.value)} className="pl-8 h-9" />
                </div>
              </div>
              <div>
                <Label htmlFor="password" className="text-xs">Password</Label>
                <div className="relative mt-1">
                  <Lock className="absolute left-2.5 top-2.5 h-4 w-4 text-muted-foreground" />
                  <Input id="password" type="password" value={password} onChange={(e) => setPassword(e.target.value)} className="pl-8 h-9" />
                </div>
              </div>
              <div className="flex items-center justify-between text-xs">
                <span className="text-muted-foreground">Selected role:</span>
                <span className="font-semibold text-primary">{DEMO_ACCOUNTS[selected].title}</span>
              </div>
              <Button type="submit" className="w-full">
                <LogIn className="h-4 w-4 mr-2" />
                Login as {DEMO_ACCOUNTS[selected].title}
              </Button>
            </form>

            <div className="rounded-md border bg-muted/40 p-3">
              <div className="text-[11px] font-semibold mb-1.5 text-muted-foreground uppercase tracking-wide">Demo Accounts</div>
              <div className="space-y-1.5 text-xs">
                {(Object.keys(DEMO_ACCOUNTS) as Role[]).map((r) => (
                  <div key={r} className="flex items-start justify-between gap-2">
                    <div>
                      <div className="font-medium">{DEMO_ACCOUNTS[r].title}</div>
                      <div className="text-[10px] text-muted-foreground font-mono">
                        {DEMO_ACCOUNTS[r].email} / {DEMO_ACCOUNTS[r].password}
                      </div>
                    </div>
                    <Button type="button" size="sm" variant="ghost" className="h-6 text-[10px] px-2" onClick={() => pickRole(r)}>Use</Button>
                  </div>
                ))}
              </div>
            </div>

            <p className="text-[10px] text-muted-foreground text-center">
              Prototype demo · No real authentication is performed.
            </p>
          </CardContent>
        </Card>
      </div>
    </div>
  );
}