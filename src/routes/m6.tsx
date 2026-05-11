import * as React from "react";
import { createFileRoute } from "@tanstack/react-router";
import { toast } from "sonner";
import { Check, X, Eye, RotateCcw, CheckCircle2 } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Dialog, DialogContent, DialogFooter, DialogHeader, DialogTitle, DialogDescription } from "@/components/ui/dialog";
import { PageHeader } from "@/components/page-header";
import { StatusBadge } from "@/components/status-badge";
import { useApp } from "@/lib/store";
import { ROOMS, type BookingRequest } from "@/lib/mock-data";

export const Route = createFileRoute("/m6")({
  validateSearch: (s: Record<string, unknown>) => ({ slot: (s.slot as string) || "" }),
  component: M6,
});

const REASONS = ["Lecturer unavailable","Public holiday","Emergency","Room problem","Student activity","Examination","Training / Meeting","Other"];

function M6() {
  const { slot: slotId } = Route.useSearch();
  const { timetable, bookings: allBookings, addBooking, updateBooking, currentUser } = useApp();
  const isAdmin = currentUser?.role === "admin";
  const isLecturer = currentUser?.role === "lecturer";
  const isStaff = false;
  const bookings = isLecturer
    ? allBookings.filter((b) => b.lecturerId === currentUser?.id)
    : allBookings;
  const slot = timetable.find((t) => t.id === slotId);

  const [date, setDate] = React.useState("2026-05-05");
  const [start, setStart] = React.useState("14:00");
  const [end, setEnd] = React.useState("16:00");
  const [room, setRoom] = React.useState(ROOMS[0]);
  const [reason, setReason] = React.useState(REASONS[0]);
  const [remarks, setRemarks] = React.useState("");
  const [availability, setAvailability] = React.useState<null | { ok: boolean }>(null);
  const [approving, setApproving] = React.useState<BookingRequest | null>(null);
  const [rejecting, setRejecting] = React.useState<BookingRequest | null>(null);
  const [rejectReason, setRejectReason] = React.useState("");
  const [viewing, setViewing] = React.useState<BookingRequest | null>(null);

  const submit = () => {
    if (!slot) { toast.error("Select a class slot from M5 first"); return; }
    addBooking({
      id: `B${Date.now().toString().slice(-4)}`,
      lecturerId: slot.lecturerId,
      lecturerName: slot.lecturerName,
      subject: slot.subjectName,
      section: slot.section,
      originalDate: slot.date,
      originalTime: `${slot.startTime} - ${slot.endTime}`,
      replacementDate: date,
      replacementStart: start,
      replacementEnd: end,
      room,
      reason,
      remarks,
      status: "Pending",
    });
    toast.success("Booking request submitted");
    setRemarks("");
  };

  const reset = () => { setRemarks(""); setAvailability(null); };

  return (
    <div className="space-y-5">
      <PageHeader
        title={isAdmin ? "Booking Approvals / Kelulusan Tempahan" : isStaff ? "Booking Records / Rekod Tempahan" : "M6: Booking Request / Permohonan Tempahan"}
        subtitle={isAdmin ? "Approve or reject replacement class requests." : isStaff ? "View-only list of replacement class bookings." : "Submit a replacement class request and track your booking status."}
      />

      {!isAdmin && !isStaff && (
      <div className="grid lg:grid-cols-3 gap-4">
        <Card className="lg:col-span-2">
          <CardHeader><CardTitle className="text-base">Replacement Class Booking Form</CardTitle></CardHeader>
          <CardContent className="space-y-3">
            {slot ? (
              <div className="grid grid-cols-2 md:grid-cols-3 gap-3 p-3 bg-muted/40 rounded">
                <Info label="Subject" value={slot.subjectName} />
                <Info label="Section" value={slot.section} />
                <Info label="Lecturer" value={slot.lecturerName} />
                <Info label="Original Date" value={slot.date} />
                <Info label="Original Time" value={`${slot.startTime} – ${slot.endTime}`} />
                <Info label="Original Room" value={slot.room} />
              </div>
            ) : (
              <div className="p-3 bg-warning/10 border-l-4 border-warning text-sm rounded">No slot pre-selected. Open this page from M5 to pre-fill a class, or fill the form manually.</div>
            )}
            <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
              <F label="Replacement Date"><Input className="h-9" type="date" value={date} onChange={(e) => setDate(e.target.value)} /></F>
              <F label="Start Time"><Input className="h-9" type="time" value={start} onChange={(e) => setStart(e.target.value)} /></F>
              <F label="End Time"><Input className="h-9" type="time" value={end} onChange={(e) => setEnd(e.target.value)} /></F>
              <F label="Requested Room">
                <Select value={room} onValueChange={setRoom}><SelectTrigger className="h-9"><SelectValue /></SelectTrigger><SelectContent>{ROOMS.map((r) => <SelectItem key={r} value={r}>{r}</SelectItem>)}</SelectContent></Select>
              </F>
            </div>
            <F label="Reason">
              <Select value={reason} onValueChange={setReason}><SelectTrigger className="h-9"><SelectValue /></SelectTrigger><SelectContent>{REASONS.map((r) => <SelectItem key={r} value={r}>{r}</SelectItem>)}</SelectContent></Select>
            </F>
            <F label="Additional Remarks"><Textarea rows={3} value={remarks} onChange={(e) => setRemarks(e.target.value)} /></F>
            <div className="flex flex-wrap gap-2">
              <Button variant="outline" onClick={() => setAvailability({ ok: Math.random() > 0.3 })}>Check Availability</Button>
              <Button onClick={submit}>Submit Booking Request</Button>
              <Button variant="ghost" onClick={reset}><RotateCcw className="h-4 w-4 mr-1.5" />Reset</Button>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader><CardTitle className="text-base">Availability</CardTitle></CardHeader>
          <CardContent className="space-y-2 text-sm">
            {availability === null && <p className="text-muted-foreground text-xs">Click "Check Availability" to verify lecturer, room, and class availability.</p>}
            {availability && (
              <>
                <Row label="Lecturer" status={availability.ok ? "Available" : "Not Available"} ok={availability.ok} />
                <Row label="Room" status={availability.ok ? "Available" : "Not Available"} ok={availability.ok} />
                <Row label="Class" status="Available" ok />
                <Row label="Time validity" status="Valid" ok />
                <Row label="Conflict" status={availability.ok ? "No Conflict" : "Conflict Found"} ok={availability.ok} />
                {!availability.ok && (
                  <div className="mt-3 border-t pt-3">
                    <div className="text-xs font-semibold mb-2 text-destructive">Suggested alternative slots:</div>
                    <table className="w-full text-xs">
                      <thead className="text-muted-foreground"><tr><th className="text-left">Date</th><th className="text-left">Time</th><th className="text-left">Room</th><th></th></tr></thead>
                      <tbody>
                        {[
                          { d: "2026-05-06", t: "10:15", r: "Lecture Room A" },
                          { d: "2026-05-07", t: "13:30", r: "Lab Elektrik 2" },
                        ].map((a, i) => (
                          <tr key={i} className="border-t"><td className="py-1">{a.d}</td><td>{a.t}</td><td>{a.r}</td>
                            <td><Button size="sm" variant="ghost" className="h-6 text-xs" onClick={() => { setDate(a.d); setStart(a.t); setRoom(a.r); setAvailability({ ok: true }); }}>Select</Button></td></tr>
                        ))}
                      </tbody>
                    </table>
                  </div>
                )}
              </>
            )}
          </CardContent>
        </Card>
      </div>
      )}

      <Card>
        <CardHeader><CardTitle className="text-base">Booking Request List</CardTitle></CardHeader>
        <CardContent className="p-0 overflow-x-auto">
          <table className="w-full text-sm">
            <thead className="text-xs text-muted-foreground border-b bg-muted/40"><tr>{["ID","Lecturer","Subject","Section","Original","Replacement","Time","Room","Reason","Status","Action"].map((h) => <th key={h} className="text-left p-2">{h}</th>)}</tr></thead>
            <tbody>
              {bookings.map((b) => (
                <tr key={b.id} className="border-b last:border-0">
                  <td className="p-2 font-mono text-xs">{b.id}</td><td className="p-2 text-xs">{b.lecturerName}</td><td className="p-2">{b.subject}</td><td className="p-2">{b.section}</td>
                  <td className="p-2 text-xs">{b.originalDate}</td><td className="p-2 text-xs">{b.replacementDate}</td><td className="p-2 text-xs">{b.replacementStart}–{b.replacementEnd}</td>
                  <td className="p-2 text-xs">{b.room}</td><td className="p-2 text-xs">{b.reason}</td><td className="p-2"><StatusBadge status={b.status} /></td>
                  <td className="p-2"><div className="flex gap-1">
                    <Button size="sm" variant="ghost" className="h-7 px-2" onClick={() => setViewing(b)}><Eye className="h-3.5 w-3.5" /></Button>
                    {b.status === "Pending" && currentUser?.role === "admin" && (<>
                      <Button size="sm" variant="ghost" className="h-7 px-2 text-success" onClick={() => setApproving(b)}><Check className="h-3.5 w-3.5" /></Button>
                      <Button size="sm" variant="ghost" className="h-7 px-2 text-destructive" onClick={() => setRejecting(b)}><X className="h-3.5 w-3.5" /></Button>
                    </>)}
                    {b.status === "Approved" && <Button size="sm" variant="ghost" className="h-7 px-2" onClick={() => { updateBooking(b.id, { status: "Completed" }); toast.success("Marked completed"); }}><CheckCircle2 className="h-3.5 w-3.5" /></Button>}
                  </div></td>
                </tr>
              ))}
            </tbody>
          </table>
        </CardContent>
      </Card>

      <Card>
        <CardHeader><CardTitle className="text-base">Upcoming Replacement Classes</CardTitle></CardHeader>
        <CardContent className="p-0 overflow-x-auto">
          <table className="w-full text-sm">
            <thead className="text-xs text-muted-foreground border-b bg-muted/40"><tr>{["Date","Time","Subject","Section","Room","Status"].map((h) => <th key={h} className="text-left p-2">{h}</th>)}</tr></thead>
            <tbody>
              {bookings.filter((b) => b.status === "Approved" || b.status === "Completed").map((b) => (
                <tr key={b.id} className="border-b last:border-0"><td className="p-2">{b.replacementDate}</td><td className="p-2">{b.replacementStart}–{b.replacementEnd}</td><td className="p-2">{b.subject}</td><td className="p-2">{b.section}</td><td className="p-2">{b.room}</td><td className="p-2"><StatusBadge status={b.status} /></td></tr>
              ))}
            </tbody>
          </table>
        </CardContent>
      </Card>

      <Dialog open={!!approving} onOpenChange={(o) => !o && setApproving(null)}>
        <DialogContent>
          <DialogHeader><DialogTitle>Approve Replacement Booking?</DialogTitle><DialogDescription>Approving this request will add the replacement class into the timetable slot list. Do you want to continue?</DialogDescription></DialogHeader>
          <DialogFooter><Button variant="outline" onClick={() => setApproving(null)}>Cancel</Button><Button onClick={() => { updateBooking(approving!.id, { status: "Approved" }); toast.success("Booking approved. Replacement class added to timetable."); setApproving(null); }}>Approve</Button></DialogFooter>
        </DialogContent>
      </Dialog>

      <Dialog open={!!rejecting} onOpenChange={(o) => !o && setRejecting(null)}>
        <DialogContent>
          <DialogHeader><DialogTitle>Reject Booking</DialogTitle></DialogHeader>
          <Textarea rows={3} placeholder="Reason for rejection..." value={rejectReason} onChange={(e) => setRejectReason(e.target.value)} />
          <DialogFooter><Button variant="outline" onClick={() => setRejecting(null)}>Cancel</Button><Button variant="destructive" onClick={() => { updateBooking(rejecting!.id, { status: "Rejected" }); toast.success("Request rejected"); setRejecting(null); setRejectReason(""); }}>Reject</Button></DialogFooter>
        </DialogContent>
      </Dialog>

      <Dialog open={!!viewing} onOpenChange={(o) => !o && setViewing(null)}>
        <DialogContent>
          <DialogHeader><DialogTitle>Booking Details</DialogTitle><DialogDescription>{viewing?.id}</DialogDescription></DialogHeader>
          {viewing && <div className="grid grid-cols-2 gap-3 text-sm"><Info label="Lecturer" value={viewing.lecturerName} /><Info label="Subject" value={viewing.subject} /><Info label="Section" value={viewing.section} /><Info label="Room" value={viewing.room} /><Info label="Original" value={`${viewing.originalDate} ${viewing.originalTime}`} /><Info label="Replacement" value={`${viewing.replacementDate} ${viewing.replacementStart}–${viewing.replacementEnd}`} /><Info label="Reason" value={viewing.reason} /><Info label="Status" value={viewing.status} />{viewing.remarks && <div className="col-span-2"><div className="text-xs text-muted-foreground">Remarks</div><div>{viewing.remarks}</div></div>}</div>}
        </DialogContent>
      </Dialog>
    </div>
  );
}

function F({ label, children }: { label: string; children: React.ReactNode }) {
  return <div><Label className="text-xs">{label}</Label><div className="mt-1">{children}</div></div>;
}
function Info({ label, value }: { label: string; value: string }) {
  return <div><div className="text-xs text-muted-foreground">{label}</div><div className="font-medium mt-0.5 text-sm">{value}</div></div>;
}
function Row({ label, status, ok }: { label: string; status: string; ok: boolean }) {
  return <div className="flex justify-between items-center"><span className="text-muted-foreground">{label}</span><span className={ok ? "text-success font-semibold" : "text-destructive font-semibold"}>{status}</span></div>;
}