"use client";

import { motion } from "motion/react";
import { cn } from "@/lib/utils";

type Props = {
  children: React.ReactNode;
  className?: string;
  containerClassName?: string;
  as?: "button" | "a";
  href?: string;
  download?: string;
  target?: string;
  rel?: string;
  onClick?: () => void;
};

export function HoverBorderGradient({
  children,
  className,
  containerClassName,
  as = "button",
  href,
  download,
  target,
  rel,
  onClick,
}: Props) {
  const Tag = as === "a" ? motion.a : motion.button;
  const base =
    "relative z-10 flex items-center justify-center gap-2 rounded-full px-7 py-3 text-sm font-medium transition-colors duration-200";

  return (
    <div className={cn("group relative inline-block", containerClassName)}>
      {/* Gradient border glow */}
      <div
        aria-hidden
        className="absolute -inset-[2px] rounded-full bg-[conic-gradient(from_var(--angle),#fff_0%,#888_25%,#fff_50%,#666_75%,#fff_100%)] opacity-60 blur-[1px] transition-opacity duration-300 group-hover:opacity-100"
        style={{
          ["--angle" as string]: "0deg",
        }}
      />
      <motion.div
        aria-hidden
        className="absolute -inset-[2px] rounded-full bg-[conic-gradient(from_0deg,#ffffff,#a1a1aa,#ffffff,#71717a,#ffffff)] opacity-50 group-hover:opacity-90"
        animate={{ rotate: 360 }}
        transition={{ duration: 4, repeat: Infinity, ease: "linear" }}
        style={{ filter: "blur(0.5px)" }}
      />
      <div className="absolute inset-0 rounded-full bg-black" />
      <Tag
        {...(as === "a"
          ? { href, download, target, rel }
          : { onClick, type: "button" as const })}
        className={cn(base, className, "bg-black text-white hover:bg-zinc-950")}
      >
        {children}
      </Tag>
    </div>
  );
}
