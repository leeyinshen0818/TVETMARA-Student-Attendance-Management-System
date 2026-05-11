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
  UserCircle,
  FileSearch,
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

type Item = { title: string; url: string; icon: any };
type MenuGroup = { label: string; items: Item[] };

const MENUS: Record<Role, MenuGroup[]> = {
  admin: [
    {
      label: "Overview",
      items: [{ title: "Dashboard", url: "/dashboard", icon: LayoutDashboard }],
    },
    {
      label: "Operations",
      items: [
        { title: "Upload Time Schedule", url: "/m4", icon: Upload },
        { title: "Showing Timetable Slot", url: "/m5", icon: CalendarDays },
        { title: "Reporting Module", url: "/m3", icon: BarChart3 },
        { title: "Discipline Reports", url: "/m2", icon: AlertTriangle },
        { title: "Booking Approvals", url: "/m6", icon: CalendarPlus },
      ],
    },
    {
      label: "Records",
      items: [
        { title: "Manage Users", url: "/users", icon: UserCog },
        { title: "Student Records", url: "/students", icon: GraduationCap },
        { title: "Lecturer Records", url: "/lecturers", icon: Users },
        { title: "Settings", url: "/settings", icon: Settings },
      ],
    },
  ],
  lecturer: [
    {
      label: "Overview",
      items: [{ title: "Dashboard", url: "/dashboard", icon: LayoutDashboard }],
    },
    {
      label: "Teaching",
      items: [
        { title: "My Timetable", url: "/m5", icon: CalendarDays },
        { title: "Taking Attendance", url: "/m1", icon: ClipboardCheck },
        { title: "My Attendance Reports", url: "/m3", icon: BarChart3 },
        { title: "Report Discipline Issue", url: "/m2", icon: AlertTriangle },
        { title: "Booking Request", url: "/m6", icon: CalendarPlus },
      ],
    },
    {
      label: "Records",
      items: [
        { title: "My Students", url: "/students", icon: GraduationCap },
        { title: "My Profile", url: "/lecturers", icon: UserCircle },
      ],
    },
  ],
};

export function AppSidebar() {
  const { state } = useSidebar();
  const collapsed = state === "collapsed";
  const path = useRouterState({ select: (r) => r.location.pathname });
  const { currentUser, logout } = useApp();
  const groups = currentUser ? MENUS[currentUser.role] : [];
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
        {groups.map((g) => (
          <SidebarGroup key={g.label}>
            <SidebarGroupLabel>{g.label}</SidebarGroupLabel>
            <SidebarGroupContent>
              <SidebarMenu>
                {g.items.map((item) => (
                  <SidebarMenuItem key={item.title}>
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
        ))}
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
