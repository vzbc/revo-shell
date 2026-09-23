"use client";

import type { ReactNode } from "react";
import { motion, AnimatePresence } from "motion/react";
import { cn } from "@/lib/utils";

export type SidebarLink = {
  label: string;
  href: string;
  icon: ReactNode;
};

type Props = {
  open: boolean;
  setOpen: (open: boolean) => void;
  links: SidebarLink[];
  logo?: ReactNode;
  logoIcon?: ReactNode;
  footer?: ReactNode;
  children?: ReactNode;
};

export function SidebarSection({
  open,
  setOpen,
  links,
  logo,
  logoIcon,
  footer,
  children,
}: Props) {
  return (
    <div
      className={cn(
        "mx-auto flex w-full max-w-7xl flex-1 flex-col overflow-hidden rounded-xl border border-neutral-200 bg-gray-100 md:flex-row dark:border-neutral-700 dark:bg-neutral-900",
        "h-[60vh] min-h-[420px]"
      )}
    >
      <motion.nav
        initial={false}
        animate={{ width: open ? 240 : 64 }}
        transition={{ type: "spring", stiffness: 300, damping: 30 }}
        className="relative flex h-full flex-col border-r border-neutral-200 bg-white p-3 dark:border-neutral-700 dark:bg-neutral-950"
        onMouseEnter={() => setOpen(true)}
        onMouseLeave={() => setOpen(false)}
      >
        <div className="mb-6 flex h-8 items-center overflow-hidden">
          <AnimatePresence initial={false} mode="wait">
            {open ? (
              <motion.div
                key="full"
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                exit={{ opacity: 0 }}
                className="flex items-center gap-2 whitespace-nowrap text-sm font-medium text-black dark:text-white"
              >
                {logo}
              </motion.div>
            ) : (
              <motion.div
                key="icon"
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                exit={{ opacity: 0 }}
                className="flex items-center"
              >
                {logoIcon}
              </motion.div>
            )}
          </AnimatePresence>
        </div>

        <div className="flex flex-col gap-1.5">
          {links.map((link) => (
            <a
              key={link.label}
              href={link.href}
              className="flex items-center gap-3 overflow-hidden whitespace-nowrap rounded-lg px-2.5 py-2 text-sm text-neutral-600 transition-colors hover:bg-neutral-100 hover:text-neutral-900 dark:text-neutral-400 dark:hover:bg-neutral-800 dark:hover:text-neutral-100"
            >
              <span className="shrink-0">{link.icon}</span>
              <motion.span
                animate={{ opacity: open ? 1 : 0 }}
                transition={{ duration: 0.15 }}
                className="text-[13px]"
              >
                {link.label}
              </motion.span>
            </a>
          ))}
        </div>

        {footer ? (
          <div className="mt-auto pt-4">
            <motion.div
              animate={{ opacity: open ? 1 : 0 }}
              className="flex items-center gap-3 overflow-hidden whitespace-nowrap"
            >
              {footer}
            </motion.div>
          </div>
        ) : null}
      </motion.nav>

      <div className="flex min-w-0 flex-1 flex-col overflow-hidden">
        {children}
      </div>
    </div>
  );
}

export function DashboardSkeleton() {
  return (
    <div className="flex h-full w-full flex-1 flex-col gap-2 rounded-tl-xl border border-neutral-200 bg-white p-3 md:p-8 dark:border-neutral-700 dark:bg-neutral-900">
      <div className="flex gap-2">
        {[0, 1, 2, 3].map((i) => (
          <div
            key={i}
            className="h-16 w-full animate-pulse rounded-lg bg-gray-100 dark:bg-neutral-800"
          />
        ))}
      </div>
      <div className="flex flex-1 gap-2">
        <div className="h-full w-full animate-pulse rounded-lg bg-gray-100 dark:bg-neutral-800" />
        <div className="h-full w-full animate-pulse rounded-lg bg-gray-100 dark:bg-neutral-800" />
      </div>
    </div>
  );
}
