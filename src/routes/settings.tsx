import { createFileRoute } from "@tanstack/react-router";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Switch } from "@/components/ui/switch";
import { Textarea } from "@/components/ui/textarea";
import { PageHeader } from "@/components/page-header";
import { useApp } from "@/lib/store";

export const Route = createFileRoute("/settings")({ component: SettingsPage });

function SettingsPage() {
  const { settings, setSettings } = useApp();
  return (
    <div className="space-y-5">
      <PageHeader title="Settings" />
      <Card><CardHeader><CardTitle className="text-base">Attendance Rules</CardTitle></CardHeader>
        <CardContent className="grid md:grid-cols-2 gap-4">
          <div><Label className="text-xs">Attendance Threshold (%)</Label><Input className="h-9 mt-1" type="number" value={settings.threshold} onChange={(e) => setSettings({ ...settings, threshold: +e.target.value })} /></div>
          <div><Label className="text-xs">Edit Deadline</Label><Input className="h-9 mt-1" value={settings.editDeadline} onChange={(e) => setSettings({ ...settings, editDeadline: e.target.value })} /></div>
          <div className="flex items-center justify-between border rounded p-3"><div><div className="text-sm font-medium">MC counted as present</div><div className="text-xs text-muted-foreground">Medical certificate counts toward attendance</div></div><Switch checked={settings.mcAsPresent} onCheckedChange={(v) => setSettings({ ...settings, mcAsPresent: v })} /></div>
          <div className="flex items-center justify-between border rounded p-3"><div><div className="text-sm font-medium">CK counted as present</div><div className="text-xs text-muted-foreground">Approved leave counts toward attendance</div></div><Switch checked={settings.ckAsPresent} onCheckedChange={(v) => setSettings({ ...settings, ckAsPresent: v })} /></div>
          <div><Label className="text-xs">QR Attendance Time Window (minutes)</Label><Input className="h-9 mt-1" type="number" value={settings.qrWindow} onChange={(e) => setSettings({ ...settings, qrWindow: +e.target.value })} /></div>
          <div><Label className="text-xs">Academic Session</Label><Input className="h-9 mt-1" value={settings.session} onChange={(e) => setSettings({ ...settings, session: e.target.value })} /></div>
          <div><Label className="text-xs">Semester</Label><Input className="h-9 mt-1" type="number" value={settings.semester} onChange={(e) => setSettings({ ...settings, semester: +e.target.value })} /></div>
        </CardContent>
      </Card>
      <Card><CardHeader><CardTitle className="text-base">Email Notification Template</CardTitle></CardHeader>
        <CardContent><Textarea rows={5} value={settings.emailTemplate} onChange={(e) => setSettings({ ...settings, emailTemplate: e.target.value })} /></CardContent>
      </Card>
      <div className="flex justify-end"><Button onClick={() => toast.success("Settings saved")}>Save Settings</Button></div>
    </div>
  );
}
