"use client";

import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import {
  Card,
  CardContent,
  CardDescription,
  CardFooter,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { GlareHover } from "@/components/ui/glare-hover";

const FEATURES = [
  "Full dots install — Hyprland + Quickshell",
  "Per-file backup before overwrite",
  "19 ready shells in one monorepo",
];

const APPIMAGE_HREF = "/RevoShell-Installer.AppImage";

export function DownloadCard() {
  return (
    <GlareHover className="w-full rounded-xl" duration={600}>
      <Card className="w-full">
        <CardHeader>
          <div className="flex items-center justify-between">
            <CardTitle>Revo Installer</CardTitle>
            <Badge>Free</Badge>
          </div>
          <CardDescription>
            One AppImage. Installs every dot on your system.
          </CardDescription>
          <div className="flex items-baseline gap-1 pt-2">
            <span className="text-4xl font-semibold tracking-tight">$0</span>
            <span className="text-sm text-muted-foreground text-zinc-500 dark:text-zinc-400">
              forever
            </span>
          </div>
        </CardHeader>
        <CardContent className="flex flex-col gap-2.5">
          {FEATURES.map((f) => (
            <div key={f} className="flex items-center gap-2 text-sm">
              <svg width="15" height="15" viewBox="0 0 15 15" fill="none">
                <path
                  d="M12.5 3.5L6 10L2.5 6.5"
                  stroke="currentColor"
                  strokeWidth="1.5"
                  strokeLinecap="round"
                  strokeLinejoin="round"
                />
              </svg>
              {f}
            </div>
          ))}
        </CardContent>
        <CardFooter>
          <a
            href={APPIMAGE_HREF}
            download="RevoShell-Installer.AppImage"
            className="w-full"
            aria-label="Download Revo Shell Installer AppImage"
          >
            <Button className="w-full">Download AppImage</Button>
          </a>
        </CardFooter>
      </Card>
    </GlareHover>
  );
}
