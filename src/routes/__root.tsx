import { Outlet, Link, createRootRoute, HeadContent, Scripts } from "@tanstack/react-router";

import appCss from "../styles.css?url";
import { AppProvider } from "@/lib/store";
import { AppLayout } from "@/components/app-layout";
import { Toaster } from "@/components/ui/sonner";

function NotFoundComponent() {
  return (
    <div className="flex min-h-screen items-center justify-center bg-background px-4">
      <div className="max-w-md text-center">
        <h1 className="text-7xl font-bold text-foreground">404</h1>
        <h2 className="mt-4 text-xl font-semibold text-foreground">Page not found</h2>
        <p className="mt-2 text-sm text-muted-foreground">
          The page you're looking for doesn't exist or has been moved.
        </p>
        <div className="mt-6">
          <Link
            to="/"
            className="inline-flex items-center justify-center rounded-md bg-primary px-4 py-2 text-sm font-medium text-primary-foreground transition-colors hover:bg-primary/90"
          >
            Go home
          </Link>
        </div>
      </div>
    </div>
  );
}

export const Route = createRootRoute({
  head: () => ({
    meta: [
      { charSet: "utf-8" },
      { name: "viewport", content: "width=device-width, initial-scale=1" },
      { title: "TVETMARA Student Attendance Management System" },
      { name: "description", content: "Centralised attendance, timetable, discipline & replacement class management for TVETMARA Johor Bahru." },
      { name: "author", content: "Lovable" },
      { property: "og:title", content: "TVETMARA Student Attendance Management System" },
      { property: "og:description", content: "Centralised attendance, timetable, discipline & replacement class management for TVETMARA Johor Bahru." },
      { property: "og:type", content: "website" },
      { name: "twitter:card", content: "summary" },
      { name: "twitter:site", content: "@Lovable" },
      { name: "twitter:title", content: "TVETMARA Student Attendance Management System" },
      { name: "twitter:description", content: "Centralised attendance, timetable, discipline & replacement class management for TVETMARA Johor Bahru." },
      { property: "og:image", content: "https://pub-bb2e103a32db4e198524a2e9ed8f35b4.r2.dev/1bf27cd3-a59b-49ab-9a69-2e5ff31a655a/id-preview-5e508a11--ade04f6f-38e9-4755-9a7c-f6ff05431aae.lovable.app-1777474937011.png" },
      { name: "twitter:image", content: "https://pub-bb2e103a32db4e198524a2e9ed8f35b4.r2.dev/1bf27cd3-a59b-49ab-9a69-2e5ff31a655a/id-preview-5e508a11--ade04f6f-38e9-4755-9a7c-f6ff05431aae.lovable.app-1777474937011.png" },
    ],
    links: [
      {
        rel: "stylesheet",
        href: appCss,
      },
    ],
  }),
  shellComponent: RootShell,
  component: RootComponent,
  notFoundComponent: NotFoundComponent,
});

function RootShell({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <head>
        <HeadContent />
      </head>
      <body>
        {children}
        <Scripts />
      </body>
    </html>
  );
}

function RootComponent() {
  return (
    <AppProvider>
      <AppLayout />
      <Toaster richColors position="top-right" />
    </AppProvider>
  );
}
