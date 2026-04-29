import * as React from "react";
import { createFileRoute } from "@tanstack/react-router";
import { toast } from "sonner";
import { Plus, Edit, Power, KeyRound } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Dialog, DialogContent, DialogFooter, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { PageHeader } from "@/components/page-header";
import { StatusBadge } from "@/components/status-badge";
import { useApp } from "@/lib/store";
import type { User } from "@/lib/mock-data";
import { RoleGate } from "@/components/role-gate";

export const Route = createFileRoute("/users")({
  component: () => (
    <RoleGate allow={["admin"]} feature="Manage Users">
      <UsersPage />
    </RoleGate>
  ),
});

function UsersPage() {
  const { users, setUsers } = useApp();
  const [editing, setEditing] = React.useState<User | null>(null);
  const [open, setOpen] = React.useState(false);

  const save = (u: User) => {
    setUsers((p) => (p.find((x) => x.id === u.id) ? p.map((x) => (x.id === u.id ? u : x)) : [...p, u]));
    toast.success("User saved"); setOpen(false); setEditing(null);
  };

  return (
    <div className="space-y-5">
      <PageHeader title="Manage Users / Pengurusan Pengguna" actions={<Button onClick={() => { setEditing({ id: `U${Date.now().toString().slice(-4)}`, name: "", email: "", role: "lecturer", department: "", status: "Active", lastLogin: "—" }); setOpen(true); }}><Plus className="h-4 w-4 mr-1.5" />Add User</Button>} />
      <Card><CardContent className="p-0 overflow-x-auto">
        <table className="w-full text-sm">
          <thead className="text-xs text-muted-foreground border-b bg-muted/40"><tr>{["ID","Name","Email","Role","Department","Status","Last Login","Action"].map((h) => <th key={h} className="text-left p-2">{h}</th>)}</tr></thead>
          <tbody>
            {users.map((u) => (
              <tr key={u.id} className="border-b last:border-0">
                <td className="p-2 font-mono text-xs">{u.id}</td><td className="p-2 font-medium">{u.name}</td><td className="p-2 text-xs">{u.email}</td>
                <td className="p-2 capitalize">{u.role}</td><td className="p-2 text-xs">{u.department}</td>
                <td className="p-2"><StatusBadge status={u.status} /></td><td className="p-2 text-xs">{u.lastLogin}</td>
                <td className="p-2"><div className="flex gap-1">
                  <Button size="sm" variant="ghost" className="h-7 px-2" onClick={() => { setEditing(u); setOpen(true); }}><Edit className="h-3.5 w-3.5" /></Button>
                  <Button size="sm" variant="ghost" className="h-7 px-2" onClick={() => { setUsers((p) => p.map((x) => x.id === u.id ? { ...x, status: x.status === "Active" ? "Inactive" : "Active" } : x)); toast.success("Status updated"); }}><Power className="h-3.5 w-3.5" /></Button>
                  <Button size="sm" variant="ghost" className="h-7 px-2" onClick={() => toast.success("Password reset link sent")}><KeyRound className="h-3.5 w-3.5" /></Button>
                </div></td>
              </tr>
            ))}
          </tbody>
        </table>
      </CardContent></Card>

      <Dialog open={open} onOpenChange={setOpen}>
        <DialogContent>
          <DialogHeader><DialogTitle>{editing && users.find((u) => u.id === editing.id) ? "Edit User" : "Add User"}</DialogTitle></DialogHeader>
          {editing && (
            <div className="space-y-3">
              <F label="Name"><Input className="h-9" value={editing.name} onChange={(e) => setEditing({ ...editing, name: e.target.value })} /></F>
              <F label="Email"><Input className="h-9" type="email" value={editing.email} onChange={(e) => setEditing({ ...editing, email: e.target.value })} /></F>
              <F label="Role">
                <Select value={editing.role} onValueChange={(v) => setEditing({ ...editing, role: v as any })}>
                  <SelectTrigger className="h-9"><SelectValue /></SelectTrigger>
                  <SelectContent>{[{v:"admin",l:"Admin"},{v:"lecturer",l:"Lecturer"},{v:"staff",l:"Academic Staff"}].map((x) => <SelectItem key={x.v} value={x.v}>{x.l}</SelectItem>)}</SelectContent>
                </Select>
              </F>
              <F label="Department"><Input className="h-9" value={editing.department || ""} onChange={(e) => setEditing({ ...editing, department: e.target.value })} /></F>
              <F label="Status">
                <Select value={editing.status} onValueChange={(v) => setEditing({ ...editing, status: v as any })}>
                  <SelectTrigger className="h-9"><SelectValue /></SelectTrigger><SelectContent>{["Active","Inactive"].map((s) => <SelectItem key={s} value={s}>{s}</SelectItem>)}</SelectContent>
                </Select>
              </F>
              <DialogFooter><Button variant="outline" onClick={() => setOpen(false)}>Cancel</Button><Button onClick={() => save(editing)}>Save</Button></DialogFooter>
            </div>
          )}
        </DialogContent>
      </Dialog>
    </div>
  );
}

function F({ label, children }: { label: string; children: React.ReactNode }) {
  return <div><Label className="text-xs">{label}</Label><div className="mt-1">{children}</div></div>;
}