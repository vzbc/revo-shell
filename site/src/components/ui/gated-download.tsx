"use client";

import type { ReactNode } from "react";
import { HoverBorderGradient } from "@/components/ui/hover-border-gradient";
import { scrollToSignIn, useAuthUser } from "@/lib/auth";
import { cn } from "@/lib/utils";

// Full AppImage (~868MB) hosted on GoFile — exceeds Vercel Hobby 100MB limit
const APPIMAGE_HREF = "https://gofile.io/d/5QIl7f5h";

const lockedCtaClass =
  "dark:bg-black bg-white text-black dark:text-white";
const lockedBlockClass =
  "inline-flex w-full items-center justify-center rounded-md border border-white/20 bg-white/10 px-4 py-2 text-sm font-medium text-white backdrop-blur transition hover:border-white/40 hover:bg-white/15";

type Props = {
  children: ReactNode;
  className?: string;
  containerClassName?: string;
  labelLocked?: string;
  variant?: "cta" | "block";
};

export function GatedDownload({
  children,
  className,
  containerClassName,
  labelLocked = "Sign in with Google to download",
  variant = "cta",
}: Props) {
  const user = useAuthUser();
  const locked = user === undefined || user === null;

  if (locked) {
    if (variant === "cta") {
      return (
        <HoverBorderGradient
          as="button"
          containerClassName={cn("rounded-full", containerClassName)}
          className={cn(lockedCtaClass, className)}
          onClick={scrollToSignIn}
        >
          {labelLocked}
        </HoverBorderGradient>
      );
    }

    return (
      <button
        type="button"
        className={cn(lockedBlockClass, className)}
        onClick={scrollToSignIn}
      >
        {labelLocked}
      </button>
    );
  }

  if (variant === "cta") {
    return (
      <HoverBorderGradient
        as="a"
        href={APPIMAGE_HREF}
        target="_blank"
        rel="noopener noreferrer"
        containerClassName={cn("rounded-full", containerClassName)}
        className={cn("dark:bg-black bg-white text-black dark:text-white", className)}
      >
        {children}
      </HoverBorderGradient>
    );
  }

  return (
    <a
      href={APPIMAGE_HREF}
      target="_blank"
      rel="noopener noreferrer"
      className={cn(
        "inline-flex w-full items-center justify-center rounded-md bg-zinc-900 px-4 py-2 text-sm font-medium text-zinc-50 shadow-sm transition-colors hover:bg-zinc-800 dark:bg-zinc-50 dark:text-zinc-900 dark:hover:bg-zinc-200",
        className,
      )}
      aria-label="Download Revo Shell Installer AppImage"
    >
      {children}
    </a>
  );
}
