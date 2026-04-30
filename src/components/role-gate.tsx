import * as React from "react";
import { useApp } from "@/lib/store";
import type { Role } from "@/lib/mock-data";
import { AccessRestricted } from "./access-restricted";

export function RoleGate({ allow, feature, message, children }: { allow: Role[]; feature?: string; message?: string; children: React.ReactNode }) {
  const { currentUser } = useApp();
  if (!currentUser || !allow.includes(currentUser.role)) {
    return <AccessRestricted feature={feature} message={message} />;
  }
  return <>{children}</>;
}