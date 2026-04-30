import { ShieldAlert } from "lucide-react";
import { Link } from "@tanstack/react-router";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { useApp } from "@/lib/store";

export function AccessRestricted({ feature, message }: { feature?: string; message?: string }) {
  const { currentUser } = useApp();
  return (
    <div className="flex items-center justify-center min-h-[60vh]">
      <Card className="max-w-md w-full">
        <CardContent className="p-8 text-center space-y-4">
          <div className="mx-auto w-14 h-14 rounded-full bg-destructive/10 flex items-center justify-center">
            <ShieldAlert className="h-7 w-7 text-destructive" />
          </div>
          <div>
            <h2 className="text-lg font-bold">Access Restricted</h2>
            {message ? (
              <p className="text-sm text-muted-foreground mt-1">{message}</p>
            ) : (
              <p className="text-sm text-muted-foreground mt-1">
                Your role <span className="font-semibold capitalize">{currentUser?.role}</span> does not have permission to access
                {feature ? ` ${feature}` : " this page"}.
              </p>
            )}
          </div>
          <Button asChild variant="outline" size="sm">
            <Link to="/dashboard">Back to Dashboard</Link>
          </Button>
        </CardContent>
      </Card>
    </div>
  );
}