import { cn } from "@/lib/utils";

const map: Record<string, string> = {
  Present: "bg-success text-success-foreground",
  Approved: "bg-success text-success-foreground",
  Completed: "bg-success text-success-foreground",
  "Mark Completed": "bg-success text-success-foreground",
  Good: "bg-success text-success-foreground",
  Valid: "bg-success text-success-foreground",
  Active: "bg-success text-success-foreground",
  Resolved: "bg-success text-success-foreground",
  "Action Taken": "bg-success text-success-foreground",
  "Attendance Completed": "bg-success text-success-foreground",

  Absent: "bg-destructive text-destructive-foreground",
  Rejected: "bg-destructive text-destructive-foreground",
  Critical: "bg-destructive text-destructive-foreground",
  Warning: "bg-destructive text-destructive-foreground",
  Clash: "bg-destructive text-destructive-foreground",
  "Below 80%": "bg-destructive text-destructive-foreground",
  Inactive: "bg-destructive text-destructive-foreground",
  Cancelled: "bg-destructive text-destructive-foreground",
  Escalated: "bg-destructive text-destructive-foreground",
  High: "bg-destructive text-destructive-foreground",

  Pending: "bg-warning text-warning-foreground",
  Late: "bg-warning text-warning-foreground",
  "Under Review": "bg-warning text-warning-foreground",
  Ongoing: "bg-warning text-warning-foreground",
  "Attendance Not Taken": "bg-warning text-warning-foreground",
  "Attendance Pending": "bg-warning text-warning-foreground",
  "Missing Data": "bg-warning text-warning-foreground",
  Medium: "bg-warning text-warning-foreground",
  New: "bg-warning text-warning-foreground",

  MC: "bg-info text-info-foreground",
  CK: "bg-info text-info-foreground",
  Information: "bg-info text-info-foreground",
  Theory: "bg-info text-info-foreground",
  Practical: "bg-info text-info-foreground",
  Upcoming: "bg-info text-info-foreground",
  Low: "bg-info text-info-foreground",

  "Replacement Class": "bg-replacement text-replacement-foreground",
  Rescheduled: "bg-replacement text-replacement-foreground",

  "Normal Class": "bg-secondary text-secondary-foreground",
};

export function StatusBadge({ status, className }: { status: string; className?: string }) {
  const cls = map[status] || "bg-secondary text-secondary-foreground";
  return (
    <span
      className={cn(
        "inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium whitespace-nowrap",
        cls,
        className,
      )}
    >
      {status}
    </span>
  );
}