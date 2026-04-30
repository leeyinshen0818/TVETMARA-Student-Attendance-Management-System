import { Bell, Search, CalendarDays } from "lucide-react";
import { SidebarTrigger } from "@/components/ui/sidebar";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";
import { useApp } from "@/lib/store";
import { format } from "date-fns";

export function TopBar() {
  const { currentUser } = useApp();
  const today = format(new Date("2026-04-29"), "EEEE, dd MMM yyyy");

  const roleLabel = currentUser?.role === "admin" ? "Admin" : "Lecturer";
  const roleClass =
    currentUser?.role === "admin"
      ? "bg-primary text-primary-foreground"
      : "bg-success text-success-foreground";

  return (
    <header className="sticky top-0 z-30 flex h-14 items-center gap-3 border-b bg-card px-3 sm:px-4">
      <SidebarTrigger />
      <div className="hidden sm:flex flex-1 items-center gap-3">
        <div className="hidden md:block">
          <h1 className="text-sm font-semibold leading-none">TVETMARA Student Attendance Management System</h1>
          <p className="text-[11px] text-muted-foreground mt-0.5">TVETMARA Johor Bahru</p>
        </div>
      </div>
      <div className="hidden lg:flex relative w-72">
        <Search className="absolute left-2.5 top-2.5 h-4 w-4 text-muted-foreground" />
        <Input placeholder="Search students, classes, reports..." className="pl-8 h-9" />
      </div>
      <div className="ml-auto flex items-center gap-2 sm:gap-3">
        <div className="hidden md:flex items-center gap-1.5 text-xs text-muted-foreground">
          <CalendarDays className="h-4 w-4" />
          {today}
        </div>
        <Button variant="ghost" size="icon" className="relative">
          <Bell className="h-4 w-4" />
          <span className="absolute top-1 right-1 h-2 w-2 rounded-full bg-destructive" />
        </Button>
        {currentUser && (
          <div className="flex items-center gap-2">
            <div className="text-right hidden sm:block">
              <div className="text-xs font-semibold leading-tight">{currentUser.name}</div>
              <div className="text-[10px] text-muted-foreground">{currentUser.email}</div>
            </div>
            <span className={`rounded-full px-2 py-0.5 text-[10px] font-semibold ${roleClass}`}>{roleLabel}</span>
          </div>
        )}
      </div>
    </header>
  );
}