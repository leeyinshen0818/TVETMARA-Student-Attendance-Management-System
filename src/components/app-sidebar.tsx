import { Link, useRouterState } from "@tanstack/react-router";
import {
  LayoutDashboard,
  ClipboardCheck,
  AlertTriangle,
  BarChart3,
  Upload,
  CalendarDays,
  CalendarPlus,
  GraduationCap,
  Users,
  UserCog,
  Settings,
  LogOut,
  GraduationCapIcon,
} from "lucide-react";
import {
  Sidebar,
  SidebarContent,
  SidebarGroup,
  SidebarGroupContent,
  SidebarGroupLabel,
  SidebarHeader,
  SidebarFooter,
  SidebarMenu,
  SidebarMenuButton,
  SidebarMenuItem,
  useSidebar,
} from "@/components/ui/sidebar";
import { useApp } from "@/lib/store";
import type { Role } from "@/lib/mock-data";

type Item = { title: string; url: string; icon: any; roles?: Role[] };

const modules: Item[] = [
  { title: "Dashboard", url: "/dashboard", icon: LayoutDashboard },
  { title: "M1 Taking Attendance", url: "/m1", icon: ClipboardCheck, roles: ["lecturer", "admin"] },
  { title: "M2 Discipline Issue", url: "/m2", icon: AlertTriangle },
  { title: "M3 Reporting", url: "/m3", icon: BarChart3 },
  { title: "M4 Upload Timetable", url: "/m4", icon: Upload, roles: ["admin"] },
  { title: "M5 Timetable Slot", url: "/m5", icon: CalendarDays },
  { title: "M6 Booking Module", url: "/m6", icon: CalendarPlus },
];

const records: Item[] = [
  { title: "Student Records", url: "/students", icon: GraduationCap },
  { title: "Lecturer Records", url: "/lecturers", icon: Users },
  { title: "Manage Users", url: "/users", icon: UserCog, roles: ["admin"] },
  { title: "Settings", url: "/settings", icon: Settings, roles: ["admin"] },
];

export function AppSidebar() {
  const { state } = useSidebar();
  const collapsed = state === "collapsed";
  const path = useRouterState({ select: (r) => r.location.pathname });
  const { currentUser, logout } = useApp();

  const visible = (item: Item) => !item.roles || (currentUser && item.roles.includes(currentUser.role));
  const isActive = (url: string) => path === url;

  return (
    <Sidebar collapsible="icon">
      <SidebarHeader>
        <div className="flex items-center gap-2 px-2 py-3">
          <div className="flex h-9 w-9 items-center justify-center rounded-md bg-sidebar-primary text-sidebar-primary-foreground">
            <GraduationCapIcon className="h-5 w-5" />
          </div>
          {!collapsed && (
            <div className="leading-tight">
              <div className="text-sm font-bold text-sidebar-foreground">TVETMARA</div>
              <div className="text-[10px] text-sidebar-foreground/70">Attendance System</div>
            </div>
          )}
        </div>
      </SidebarHeader>
      <SidebarContent>
        <SidebarGroup>
          <SidebarGroupLabel>Modules</SidebarGroupLabel>
          <SidebarGroupContent>
            <SidebarMenu>
              {modules.filter(visible).map((item) => (
                <SidebarMenuItem key={item.url}>
                  <SidebarMenuButton asChild isActive={isActive(item.url)} tooltip={item.title}>
                    <Link to={item.url} className="flex items-center gap-2">
                      <item.icon className="h-4 w-4" />
                      {!collapsed && <span>{item.title}</span>}
                    </Link>
                  </SidebarMenuButton>
                </SidebarMenuItem>
              ))}
            </SidebarMenu>
          </SidebarGroupContent>
        </SidebarGroup>
        <SidebarGroup>
          <SidebarGroupLabel>Records</SidebarGroupLabel>
          <SidebarGroupContent>
            <SidebarMenu>
              {records.filter(visible).map((item) => (
                <SidebarMenuItem key={item.url}>
                  <SidebarMenuButton asChild isActive={isActive(item.url)} tooltip={item.title}>
                    <Link to={item.url} className="flex items-center gap-2">
                      <item.icon className="h-4 w-4" />
                      {!collapsed && <span>{item.title}</span>}
                    </Link>
                  </SidebarMenuButton>
                </SidebarMenuItem>
              ))}
            </SidebarMenu>
          </SidebarGroupContent>
        </SidebarGroup>
      </SidebarContent>
      <SidebarFooter>
        <SidebarMenu>
          <SidebarMenuItem>
            <SidebarMenuButton onClick={logout} tooltip="Logout">
              <LogOut className="h-4 w-4" />
              {!collapsed && <span>Logout</span>}
            </SidebarMenuButton>
          </SidebarMenuItem>
        </SidebarMenu>
      </SidebarFooter>
    </Sidebar>
  );
}