"use client";

import { useState } from "react";
import Image from "next/image";
import {
  SidebarSection,
  type SidebarLink,
} from "@/components/ui/sidebar";
import {
  IconHome,
  IconTerminal2,
  IconDownload,
  IconSettings,
  IconBrandGithub,
} from "@tabler/icons-react";

const links: SidebarLink[] = [
  { label: "Home", href: "#hero", icon: <IconHome className="h-5 w-5" /> },
  { label: "Shells", href: "#macbook", icon: <IconTerminal2 className="h-5 w-5" /> },
  {
    label: "Download",
    href: "#download",
    icon: <IconDownload className="h-5 w-5" />,
  },
  {
    label: "Settings",
    href: "#info",
    icon: <IconSettings className="h-5 w-5" />,
  },
];

export function SidebarDemo() {
  const [open, setOpen] = useState(false);

  return (
    <SidebarSection
      open={open}
      setOpen={setOpen}
      links={links}
      logo={
        <>
          <span className="h-5 w-6 shrink-0 rounded-tl-lg rounded-tr-sm rounded-br-lg rounded-bl-sm bg-black dark:bg-white" />
          <span className="whitespace-pre font-medium text-black dark:text-white">
            Revo Shell
          </span>
        </>
      }
      logoIcon={
        <span className="h-5 w-6 shrink-0 rounded-tl-lg rounded-tr-sm rounded-br-lg rounded-bl-sm bg-black dark:bg-white" />
      }
      footer={
        <a
          href="https://github.com/X3jo/revo-shell"
          target="_blank"
          rel="noopener noreferrer"
          className="flex items-center gap-3 text-sm text-neutral-600 hover:text-neutral-900 dark:text-neutral-400"
        >
          <span className="flex h-7 w-7 shrink-0 items-center justify-center rounded-full bg-neutral-200 dark:bg-neutral-700">
            <IconBrandGithub className="h-4 w-4" />
          </span>
          <span className={open ? "opacity-100" : "opacity-0"}>X3jo</span>
        </a>
      }
    >
      <div className="relative flex h-full w-full items-center justify-center bg-zinc-100 dark:bg-zinc-900">
        <Image
          src="/after.png"
          alt="Revo Shell desktop"
          fill
          className="object-cover"
          sizes="(max-width: 768px) 100vw, 60vw"
          priority
        />
      </div>
    </SidebarSection>
  );
}
