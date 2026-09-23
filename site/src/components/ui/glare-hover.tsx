"use client";

import React, { useEffect, useRef, useState } from "react";
import { cn } from "@/lib/utils";

export function GlareHover({
  children,
  className,
  duration = 600,
  glareColor = "rgba(255,255,255,0.35)",
  glareSize = 250,
}: {
  children: React.ReactNode;
  className?: string;
  duration?: number;
  glareColor?: string;
  glareSize?: number;
}) {
  const ref = useRef<HTMLDivElement>(null);
  const [pos, setPos] = useState({ x: 0, y: 0 });
  const [active, setActive] = useState(false);

  useEffect(() => {
    const el = ref.current;
    if (!el) return;
    const onMove = (e: PointerEvent) => {
      const r = el.getBoundingClientRect();
      setPos({ x: e.clientX - r.left, y: e.clientY - r.top });
    };
    const onEnter = () => setActive(true);
    const onLeave = () => setActive(false);
    el.addEventListener("pointermove", onMove);
    el.addEventListener("pointerenter", onEnter);
    el.addEventListener("pointerleave", onLeave);
    return () => {
      el.removeEventListener("pointermove", onMove);
      el.removeEventListener("pointerenter", onEnter);
      el.removeEventListener("pointerleave", onLeave);
    };
  }, []);

  return (
    <div
      ref={ref}
      className={cn(
        "relative overflow-hidden",
        className,
      )}
      style={{ transitionDuration: `${duration}ms` }}
    >
      {children}
      <div
        aria-hidden
        className="pointer-events-none absolute inset-0 z-10 transition-opacity"
        style={{
          opacity: active ? 1 : 0,
          transitionDuration: `${duration}ms`,
          background: `radial-gradient(${glareSize}px circle at ${pos.x}px ${pos.y}px, ${glareColor}, transparent 60%)`,
        }}
      />
    </div>
  );
}
