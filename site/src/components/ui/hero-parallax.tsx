"use client";

import { motion, useScroll, useTransform } from "motion/react";
import { useRef } from "react";
import Image from "next/image";

export type ParallaxProduct = {
  title: string;
  link: string;
  thumbnail: string;
};

export function HeroParallax({
  products,
  children,
}: {
  products: ParallaxProduct[];
  children?: React.ReactNode;
}) {
  const ref = useRef<HTMLDivElement>(null);
  const { scrollYProgress } = useScroll({
    target: ref,
    offset: ["start start", "end start"],
  });

  const backgroundY = useTransform(scrollYProgress, [0, 1], ["0%", "40%"]);
  const textY = useTransform(scrollYProgress, [0, 1], ["0%", "150%"]);
  const opacity = useTransform(scrollYProgress, [0, 0.7], [1, 0]);

  // Split into rows for floating thumbnails
  const mid = Math.ceil(products.length / 2);
  const row1 = products.slice(0, mid);
  const row2 = products.slice(mid);

  return (
    <div
      ref={ref}
      className="relative min-h-[100vh] w-full overflow-hidden bg-black"
    >
      {/* Floating screenshot rows (parallax) */}
      <motion.div
        style={{ y: backgroundY }}
        className="pointer-events-none absolute inset-0 z-0"
        aria-hidden
      >
        <div className="absolute left-0 right-0 top-[8%] flex gap-6 px-8 opacity-30">
          {row1.map((p, i) => (
            <motion.div
              key={`r1-${i}`}
              className="relative h-36 w-56 shrink-0 overflow-hidden rounded-xl border border-white/10 md:h-44 md:w-72"
              initial={{ opacity: 0, y: 40 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.15 + i * 0.08, duration: 0.7 }}
            >
              <Image
                src={p.thumbnail}
                alt={p.title}
                fill
                className="object-cover"
                sizes="288px"
              />
            </motion.div>
          ))}
        </div>
        <div className="absolute bottom-[10%] right-0 flex gap-6 px-8 opacity-25">
          {row2.map((p, i) => (
            <motion.div
              key={`r2-${i}`}
              className="relative h-36 w-56 shrink-0 overflow-hidden rounded-xl border border-white/10 md:h-44 md:w-72"
              initial={{ opacity: 0, y: 40 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.3 + i * 0.08, duration: 0.7 }}
            >
              <Image
                src={p.thumbnail}
                alt={p.title}
                fill
                className="object-cover"
                sizes="288px"
              />
            </motion.div>
          ))}
        </div>
        {/* Soft vignette so center text stays readable */}
        <div className="absolute inset-0 bg-[radial-gradient(ellipse_at_center,rgba(0,0,0,0.15)_0%,rgba(0,0,0,0.75)_70%,#000_100%)]" />
      </motion.div>

      {/* Center hero content */}
      <motion.div
        style={{ y: textY, opacity }}
        className="relative z-10 flex min-h-screen flex-col items-center justify-center px-6 text-center"
      >
        {children}
      </motion.div>
    </div>
  );
}
