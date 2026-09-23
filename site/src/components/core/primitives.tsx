"use client";

import { useEffect, useState, useRef, type ReactNode } from "react";
import {
  motion,
  AnimatePresence,
  useMotionValue,
  useSpring,
} from "motion/react";
import { DownloadCard } from "@/components/ui/download-card";

type Variant = {
  x: number | string;
  opacity: number;
  height?: number | string;
  position?: string;
  top?: number;
  left?: number;
  width?: number | string;
  zIndex?: number;
};

type TransitionPanelProps = {
  activeIndex: number;
  variants: {
    enter: (dir: number) => Variant;
    center: Variant;
    exit: (dir: number) => Variant;
  };
  transition?: {
    x?: { type: "spring"; stiffness: number; damping: number };
    opacity?: { duration: number };
  };
  custom: number;
  children: ReactNode;
  className?: string;
};

export function TransitionPanel({
  activeIndex,
  variants,
  transition,
  custom,
  children,
  className,
}: TransitionPanelProps) {
  const [prevIndex, setPrevIndex] = useState(activeIndex);
  const [bounds, setBounds] = useState(0);
  const ref = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (ref.current) setBounds(ref.current.offsetHeight);
  }, [activeIndex, children]);

  useEffect(() => {
    setPrevIndex(activeIndex);
  }, [activeIndex]);

  const items = Array.isArray(children) ? children : [children];
  const current = items[activeIndex];
  const previous = prevIndex !== activeIndex ? items[prevIndex] : null;

  return (
    <div
      ref={ref}
      className={className}
      style={{
        height: bounds > 0 ? bounds : undefined,
        position: "relative",
        overflow: "hidden",
      }}
    >
      <AnimatePresence initial={false} custom={custom}>
        <motion.div
          key={activeIndex}
          custom={custom}
          variants={{
            enter: (d: number) => variants.enter(d),
            center: { ...variants.center },
            exit: (d: number) => variants.exit(d),
          }}
          initial="enter"
          animate="center"
          exit="exit"
          transition={transition}
          className="absolute inset-0"
        >
          {current}
        </motion.div>
      </AnimatePresence>
      {previous}
    </div>
  );
}

export function InfoPanel() {
  const [activeIndex, setActiveIndex] = useState(0);
  const [direction, setDirection] = useState(1);

  const FEATURES = [
    {
      title: "Dots",
      description:
        "Every Revo Shell desktop ships as battle-tested dotfiles — Hyprland, Quickshell, Rofi, Kitty, and wallpapers — versioned in one monorepo you can fork instantly.",
    },
    {
      title: "QuickShells",
      description:
        "Pick from 19 ready QuickShells: End4, Lucid, Ryoku, Zesis, Vast, and more. Each shell is a complete bar, dock, launcher, and lockscreen system.",
    },
    {
      title: "Installer",
      description:
        "A native GUI installer walks you through repo → shell → password. Full install with backups — no copy-paste from a README.",
    },
    {
      title: "Hyprland",
      description:
        "Animations, workspaces, and window rules tuned for Arch / CachyOS. One command turns a fresh install into a polished desktop.",
    },
  ];

  useEffect(() => {
    const id = window.setInterval(() => {
      setDirection(1);
      setActiveIndex((i) => (i + 1) % FEATURES.length);
    }, 4500);
    return () => window.clearInterval(id);
  }, [FEATURES.length]);

  return (
    <div className="w-full max-w-[364px] overflow-hidden rounded-xl border border-zinc-950/10 bg-white shadow-xl dark:border-zinc-50/10 dark:bg-zinc-900">
      <TransitionPanel
        activeIndex={activeIndex}
        variants={{
          enter: (direction: number) => ({
            x: direction > 0 ? 364 : -364,
            opacity: 0,
            position: "absolute",
            top: 0,
            left: 0,
            width: "100%",
          } as Variant),
          center: {
            zIndex: 1,
            x: 0,
            opacity: 1,
          } as Variant,
          exit: (direction: number) => ({
            zIndex: 0,
            x: direction < 0 ? 364 : -364,
            opacity: 0,
            position: "absolute",
            top: 0,
            left: 0,
            width: "100%",
          } as Variant),
        }}
        transition={{
          x: { type: "spring", stiffness: 300, damping: 30 },
          opacity: { duration: 0.2 },
        }}
        custom={direction}
      >
        {FEATURES.map((feature) => (
          <div key={feature.title} className="px-4 pt-4 pb-2">
            <h3 className="mb-1 font-medium text-zinc-800 dark:text-zinc-100">
              {feature.title}
            </h3>
            <p className="text-sm leading-relaxed text-zinc-600 dark:text-zinc-400">
              {feature.description}
            </p>
          </div>
        ))}
      </TransitionPanel>
      <div className="p-4">
        <DownloadCard />
      </div>
    </div>
  );
}

/** Character-level fade-in text effect */
export function TextEffect({
  children,
  per = "char",
  preset = "fade",
  className,
}: {
  children: string;
  per?: "char" | "word";
  preset?: "fade";
  className?: string;
}) {
  const segments =
    per === "char" ? children.split("") : children.split(/(\s+)/);

  return (
    <span className={className} aria-label={children}>
      {segments.map((seg, i) => (
        <motion.span
          key={i}
          aria-hidden
          initial={{ opacity: 0, filter: "blur(6px)" }}
          whileInView={{ opacity: 1, filter: "blur(0px)" }}
          viewport={{ once: true, margin: "-40px" }}
          transition={{ duration: 0.35, delay: i * 0.03, ease: "easeOut" }}
          className="inline-block whitespace-pre"
          style={preset === "fade" ? undefined : undefined}
        >
          {seg}
        </motion.span>
      ))}
    </span>
  );
}

/** Image before/after comparison slider */
export function ImageComparison({
  leftSrc,
  rightSrc,
  leftAlt = "Before",
  rightAlt = "After",
  className,
}: {
  leftSrc: string;
  rightSrc: string;
  leftAlt?: string;
  rightAlt?: string;
  className?: string;
}) {
  const [pos, setPos] = useState(50);
  const ref = useRef<HTMLDivElement>(null);

  const onMove = (clientX: number) => {
    const el = ref.current;
    if (!el) return;
    const r = el.getBoundingClientRect();
    const p = ((clientX - r.left) / r.width) * 100;
    setPos(Math.min(100, Math.max(0, p)));
  };

  return (
    <div
      ref={ref}
      className={
        className ??
        "relative aspect-[16/10] w-full overflow-hidden rounded-lg border border-zinc-200 select-none dark:border-zinc-800"
      }
      onMouseMove={(e) => e.buttons === 1 && onMove(e.clientX)}
      onTouchMove={(e) => onMove(e.touches[0].clientX)}
    >
      {/* Right (After) full */}
      {/* eslint-disable-next-line @next/next/no-img-element */}
      <img
        src={rightSrc}
        alt={rightAlt}
        className="absolute inset-0 h-full w-full object-cover"
        draggable={false}
      />
      {/* Left (Before) clipped */}
      <div
        className="absolute inset-0 overflow-hidden"
        style={{ width: `${pos}%` }}
      >
        {/* eslint-disable-next-line @next/next/no-img-element */}
        <img
          src={leftSrc}
          alt={leftAlt}
          className="absolute inset-0 h-full object-cover"
          style={{ width: ref.current?.offsetWidth ?? "100%", maxWidth: "none" }}
          draggable={false}
        />
      </div>

      {/* Labels */}
      <span className="absolute left-3 top-3 rounded bg-black/60 px-2 py-1 text-xs text-white backdrop-blur">
        {leftAlt}
      </span>
      <span className="absolute right-3 top-3 rounded bg-black/60 px-2 py-1 text-xs text-white backdrop-blur">
        {rightAlt}
      </span>

      {/* Divider */}
      <div
        className="absolute top-0 bottom-0 w-0.5 bg-white shadow-[0_0_8px_rgba(0,0,0,0.5)]"
        style={{ left: `${pos}%` }}
      />

      {/* Range input for a11y */}
      <input
        type="range"
        min={0}
        max={100}
        value={pos}
        onChange={(e) => setPos(Number(e.target.value))}
        aria-label="Compare before and after"
        className="compare-range absolute inset-0 h-full w-full opacity-0"
      />

      {/* Visual handle */}
      <div
        className="pointer-events-none absolute top-1/2 flex h-10 w-10 -translate-x-1/2 -translate-y-1/2 items-center justify-center rounded-full border-2 border-black bg-white shadow-lg"
        style={{ left: `${pos}%` }}
      >
        <span className="text-xs font-bold text-black">↔</span>
      </div>
    </div>
  );
}

/** Chat bubbles */
export function Bubble({
  children,
  align = "start",
  variant = "default",
  className,
}: {
  children: ReactNode;
  align?: "start" | "end";
  variant?: "default" | "muted";
  className?: string;
}) {
  return (
    <div
      className={`flex w-full ${align === "end" ? "justify-end" : "justify-start"} ${className ?? ""}`}
    >
      <div
        className={`max-w-[85%] rounded-2xl px-4 py-2.5 text-sm leading-relaxed ${
          variant === "muted"
            ? "bg-zinc-100 text-zinc-800 dark:bg-zinc-800 dark:text-zinc-200"
            : "bg-zinc-900 text-white dark:bg-white dark:text-zinc-900"
        }`}
      >
        {children}
      </div>
    </div>
  );
}

export function BubbleGroup({
  children,
  className,
}: {
  children: ReactNode;
  className?: string;
}) {
  return (
    <div className={`flex flex-col gap-2 ${className ?? ""}`}>{children}</div>
  );
}

export function BubbleReactions({ children }: { children: ReactNode }) {
  return (
    <div className="mt-1.5 flex gap-1 text-xs text-zinc-500">{children}</div>
  );
}

export function BubbleContent({ children }: { children: ReactNode }) {
  return <>{children}</>;
}

/** Small helper hook for measuring (kept for API parity) */
export function useMeasure() {
  const ref = useRef<HTMLDivElement>(null);
  const [bounds, setBounds] = useState({ height: 0, width: 0 });
  useEffect(() => {
    if (!ref.current) return;
    const ro = new ResizeObserver(([entry]) => {
      setBounds({
        height: entry.contentRect.height,
        width: entry.contentRect.width,
      });
    });
    ro.observe(ref.current);
    return () => ro.disconnect();
  }, []);
  return [ref, bounds] as const;
}

/** Shared motion values for custom cursor (re-exported for demos) */
export function useSpringPos(x: number, y: number) {
  const mx = useMotionValue(x);
  const my = useMotionValue(y);
  const sx = useSpring(mx, { stiffness: 300, damping: 30 });
  const sy = useSpring(my, { stiffness: 300, damping: 30 });
  return { mx, my, sx, sy };
}
