"use client";

import { useEffect, useState } from "react";
import { motion, AnimatePresence } from "motion/react";
import { PlusIcon } from "lucide-react";

export function CustomCursor() {
  const [pos, setPos] = useState({ x: -100, y: -100 });
  const [hovering, setHovering] = useState(false);
  const [visible, setVisible] = useState(false);

  useEffect(() => {
    const fine = window.matchMedia("(pointer: fine)").matches;
    if (!fine) return;

    document.body.classList.add("has-custom-cursor");
    setVisible(true);

    const onMove = (e: MouseEvent) => {
      setPos({ x: e.clientX, y: e.clientY });
      const el = e.target as HTMLElement | null;
      const interactive = !!el?.closest(
        'a, button, [role="button"], input, textarea, select, .cursor-hover'
      );
      setHovering(interactive);
    };

    window.addEventListener("mousemove", onMove, { passive: true });
    return () => {
      window.removeEventListener("mousemove", onMove);
      document.body.classList.remove("has-custom-cursor");
    };
  }, []);

  if (!visible) return null;

  return (
    <AnimatePresence>
      <motion.div
        className="pointer-events-none fixed left-0 top-0 z-[9999]"
        animate={{ x: pos.x, y: pos.y }}
        transition={{ type: "spring", stiffness: 500, damping: 40, mass: 0.4 }}
        style={{ translateX: "-50%", translateY: "-50%" }}
      >
        <motion.div
          className="flex items-center justify-center rounded-[24px] bg-gray-500/40 backdrop-blur-md dark:bg-gray-300/40"
          animate={{
            width: hovering ? 80 : 16,
            height: hovering ? 32 : 16,
          }}
          transition={{ ease: "easeInOut", duration: 0.15 }}
        >
          <AnimatePresence>
            {hovering ? (
              <motion.div
                initial={{ opacity: 0, scale: 0.6 }}
                animate={{ opacity: 1, scale: 1 }}
                exit={{ opacity: 0, scale: 0.6 }}
                className="inline-flex items-center text-sm text-white"
              >
                More <PlusIcon className="ml-1 h-4 w-4" />
              </motion.div>
            ) : null}
          </AnimatePresence>
        </motion.div>
      </motion.div>
    </AnimatePresence>
  );
}
