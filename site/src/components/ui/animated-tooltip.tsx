"use client";

import { useState } from "react";
import Image from "next/image";
import { motion, AnimatePresence } from "motion/react";

export type TooltipPerson = {
  id: number;
  name: string;
  designation: string;
  image: string;
};

export function AnimatedTooltip({ items }: { items: TooltipPerson[] }) {
  const [hovered, setHovered] = useState<number | null>(null);

  return (
    <div className="flex flex-row flex-wrap items-center justify-center gap-4">
      {items.map((item) => (
        <div
          key={item.id}
          className="group relative flex cursor-pointer items-center justify-center"
          onMouseEnter={() => setHovered(item.id)}
          onMouseLeave={() => setHovered(null)}
        >
          <AnimatePresence>
            {hovered === item.id && (
              <motion.div
                initial={{ opacity: 0, y: 20, scale: 0.6 }}
                animate={{ opacity: 1, y: 0, scale: 1 }}
                exit={{ opacity: 0, y: 10, scale: 0.8 }}
                transition={{ duration: 0.2, ease: "easeOut" }}
                className="absolute -top-20 z-30 flex flex-col items-center rounded-xl border border-white/10 bg-black/95 px-3 py-2 text-center shadow-xl backdrop-blur"
              >
                <div className="absolute -bottom-1.5 h-3 w-3 rotate-45 border-b border-r border-white/10 bg-black/95" />
                <p className="text-sm font-semibold text-white">{item.name}</p>
                <p className="text-xs text-neutral-400">{item.designation}</p>
              </motion.div>
            )}
          </AnimatePresence>
          <motion.div
            animate={{
              scale: hovered === item.id ? 1.15 : 1,
              zIndex: hovered === item.id ? 40 : 10,
            }}
            transition={{ duration: 0.2 }}
            className="relative h-14 w-14 overflow-hidden rounded-full border-2 border-white/20 shadow-lg"
          >
            <Image
              src={item.image}
              alt={item.name}
              fill
              className="object-cover"
              sizes="56px"
            />
          </motion.div>
        </div>
      ))}
    </div>
  );
}
