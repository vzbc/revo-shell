import Image from "next/image";
import { CustomCursor } from "@/components/core/cursor";
import {
  HeroParallax,
  type ParallaxProduct,
} from "@/components/ui/hero-parallax";
import { Terminal } from "@/components/ui/terminal";
import { GatedDownload } from "@/components/ui/gated-download";
import {
  AnimatedTooltip,
  type TooltipPerson,
} from "@/components/ui/animated-tooltip";
import { MacbookScroll } from "@/components/ui/macbook-scroll";
import { GoogleSignInButton } from "@/components/ui/google-signin";
import {
  TextEffect,
  ImageComparison,
  Bubble,
  BubbleGroup,
  BubbleContent,
  BubbleReactions,
} from "@/components/core/primitives";

const shots: ParallaxProduct[] = Array.from({ length: 9 }, (_, i) => ({
  title: `Shell ${i + 1}`,
  link: "#macbook",
  thumbnail: `/shots/shot-${i + 1}.png`,
}));

const people: TooltipPerson[] = [
  {
    id: 1,
    name: "Alex",
    designation: "Hyprland user",
    image: "/avatars/avatar1.jpg",
  },
  {
    id: 2,
    name: "Sam",
    designation: "Quickshell fan",
    image: "/avatars/avatar2.jpg",
  },
  {
    id: 3,
    name: "Riley",
    designation: "Dotfiles author",
    image: "/avatars/avatar3.jpg",
  },
  {
    id: 4,
    name: "Jordan",
    designation: "Arch maintainer",
    image: "/avatars/avatar4.jpg",
  },
  {
    id: 5,
    name: "Casey",
    designation: "Rice collector",
    image: "/avatars/person5.jpg",
  },
  {
    id: 6,
    name: "Morgan",
    designation: "Wayland dev",
    image: "/avatars/person6.jpg",
  },
];

export default function Home() {
  return (
    <main className="relative bg-black text-white">
      <CustomCursor />

      {/* ========== HERO ========== */}
      <section id="hero">
        <HeroParallax products={shots}>
          <p className="mb-4 text-sm font-medium uppercase tracking-[0.25em] text-zinc-500">
            Revo Shell
          </p>
          <h1 className="max-w-4xl text-4xl font-semibold leading-[1.1] tracking-tight text-white sm:text-5xl md:text-6xl lg:text-7xl">
            <TextEffect per="char" preset="fade">
              Welcome to Revo Shell
            </TextEffect>
          </h1>
          <p className="mt-5 max-w-xl text-base text-zinc-400 md:text-lg">
            Revo Shell — its place to add all your{" "}
            <span className="text-white">QuickShells</span> in one place.
          </p>

          <div className="mt-8 w-full max-w-xl">
            <Terminal
              commands={[
                "curl -fsSL https://revo.sh | sh",
                "revo-shell install --gui",
                "revo-shell list shells",
                "hyprctl reload",
              ]}
              outputs={{
                0: ["✔ Preflight checks passed.", "✔ Detected CachyOS (Arch)."],
                1: ["✔ Launched GUI installer…", "✔ Monorepo staged."],
                2: [
                  "19 shells ready:",
                  "  end4 · lucid · ryoku · zesis · vast · …",
                ],
                3: ["✔ Hyprland reloaded. Enjoy the rice."],
              }}
              typingSpeed={40}
              delayBetweenCommands={900}
            />
          </div>

          <div className="mt-10 flex flex-col items-center gap-4">
            <GatedDownload variant="cta">
              Download AppImage
            </GatedDownload>
            <GoogleSignInButton />
          </div>

          <div className="mt-14">
            <p className="mb-4 text-xs uppercase tracking-widest text-zinc-600">
              Loved by the community
            </p>
            <AnimatedTooltip items={people} />
          </div>
        </HeroParallax>
      </section>

      {/* ========== MACBOOK SCROLL ========== */}
      <section id="macbook" className="bg-white dark:bg-[#0B0B0F]">
        <MacbookScroll
          title={
            <span>
              Your desktop, rebuilt.
              <br />
              Scroll for the real shots.
            </span>
          }
          src="/shots/shot-2.png"
          showGradient={false}
        />
        <div className="mx-auto grid max-w-6xl grid-cols-2 gap-4 px-6 pb-24 md:grid-cols-3">
          {[3, 5, 7, 8, 9, 4].map((n) => (
            <div
              key={n}
              className="relative aspect-[16/10] overflow-hidden rounded-lg border border-zinc-800"
            >
              <Image
                src={`/shots/shot-${n}.png`}
                alt={`Revo Shell screenshot ${n}`}
                fill
                className="object-cover"
                sizes="(max-width: 768px) 50vw, 33vw"
              />
            </div>
          ))}
        </div>
      </section>

      {/* ========== BEFORE / AFTER ========== */}
      <section className="bg-zinc-950 px-4 py-24 md:py-32">
        <div className="mx-auto max-w-4xl">
          <h2 className="mb-3 text-center text-3xl font-semibold tracking-tight text-white md:text-4xl">
            Before / After
          </h2>
          <p className="mb-10 text-center text-zinc-400">
            Stock Hyprland → Revo Shell. Drag the handle.
          </p>
          <ImageComparison
            leftSrc="/before.png"
            rightSrc="/after.png"
            leftAlt="Stock Hyprland"
            rightAlt="Revo Shell"
          />
        </div>
      </section>

      {/* ========== CHAT ========== */}
      <section className="bg-black px-4 py-24 md:py-32">
        <div className="mx-auto flex max-w-6xl flex-col items-center gap-12 lg:flex-row lg:items-start lg:justify-between">
          <div className="max-w-md">
            <h2 className="text-3xl font-semibold tracking-tight text-white md:text-4xl">
              <TextEffect per="char" preset="fade">
                Built with the community
              </TextEffect>
            </h2>
            <p className="mt-4 text-zinc-400">
              Real conversations from people who rice their desktops. One
              installer, zero config hell.
            </p>
          </div>

          <div className="w-full max-w-sm">
            <BubbleGroup>
              <Bubble align="end">
                <BubbleContent>
                  Hey — have you tried Revo Shell yet?
                </BubbleContent>
              </Bubble>
              <Bubble variant="muted">
                <BubbleContent>
                  Yes. 19 shells, one GUI installer. Insane.
                </BubbleContent>
                <BubbleReactions>
                  <span>👍</span>
                  <span>🔥</span>
                </BubbleReactions>
              </Bubble>
              <Bubble align="end">
                <BubbleContent>Does it back up my dots?</BubbleContent>
              </Bubble>
              <Bubble variant="muted">
                <BubbleContent>
                  Yep — full install with per-file backup. Never lose a config.
                </BubbleContent>
                <BubbleReactions>
                  <span>👀</span>
                  <span>+3</span>
                </BubbleReactions>
              </Bubble>
            </BubbleGroup>
          </div>
        </div>
      </section>

      {/* ========== DOWNLOAD CTA ========== */}
      <section
        id="download"
        className="border-t border-white/10 bg-black px-4 py-24 md:py-32"
      >
        <div className="mx-auto flex max-w-2xl flex-col items-center text-center">
          <h2 className="text-3xl font-semibold tracking-tight text-white md:text-5xl">
            Ready to revo your desktop?
          </h2>
          <p className="mt-4 text-zinc-400">
            One free AppImage walks you through repo → shell → password. Full
            install with backups — your dots land in minutes.
          </p>
          <div className="mt-8 flex flex-col items-center gap-4">
            <GatedDownload variant="cta">
              Download AppImage — Free
            </GatedDownload>
            <GoogleSignInButton />
            <a
              href="https://github.com/X3jo/revo-shell"
              target="_blank"
              rel="noopener noreferrer"
              className="text-sm text-zinc-500 underline-offset-4 hover:text-white hover:underline"
            >
              Or clone the monorepo on GitHub
            </a>
          </div>
        </div>
      </section>

      <footer className="border-t border-white/10 px-6 py-8 text-center text-xs text-zinc-600">
        © {new Date().getFullYear()} Revo Shell · Built for Hyprland ·{" "}
        <a
          href="https://github.com/X3jo/revo-shell"
          className="underline-offset-4 hover:text-zinc-300 hover:underline"
          target="_blank"
          rel="noopener noreferrer"
        >
          GitHub
        </a>
      </footer>
    </main>
  );
}
