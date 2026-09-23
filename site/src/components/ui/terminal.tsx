"use client";

import { useEffect, useState } from "react";

type TerminalProps = {
  commands: string[];
  outputs?: Record<number, string[]>;
  typingSpeed?: number;
  delayBetweenCommands?: number;
};

export function Terminal({
  commands,
  outputs = {},
  typingSpeed = 45,
  delayBetweenCommands = 1000,
}: TerminalProps) {
  const [lines, setLines] = useState<{ type: "cmd" | "out"; text: string }[]>(
    []
  );
  const [cmdIndex, setCmdIndex] = useState(0);
  const [typed, setTyped] = useState("");
  const [phase, setPhase] = useState<"typing" | "output" | "done">("typing");

  // Typewriter for current command
  useEffect(() => {
    if (phase !== "typing" || cmdIndex >= commands.length) return;
    const full = commands[cmdIndex];
    if (typed.length >= full.length) {
      const t = setTimeout(() => setPhase("output"), 200);
      return () => clearTimeout(t);
    }
    const t = setTimeout(() => {
      setTyped(full.slice(0, typed.length + 1));
    }, typingSpeed);
    return () => clearTimeout(t);
  }, [typed, cmdIndex, phase, commands, typingSpeed]);

  // When a command finishes typing, push it + outputs, then next
  useEffect(() => {
    if (phase !== "output") return;
    const outs = outputs[cmdIndex] ?? [];
    setLines((prev) => [
      ...prev,
      { type: "cmd", text: commands[cmdIndex] },
      ...outs.map((text) => ({ type: "out" as const, text })),
    ]);
    setTyped("");
    const next = cmdIndex + 1;
    const t = setTimeout(() => {
      if (next >= commands.length) {
        setPhase("done");
        setCmdIndex(next);
      } else {
        setCmdIndex(next);
        setPhase("typing");
      }
    }, delayBetweenCommands);
    return () => clearTimeout(t);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [phase]);

  // Restart loop after a pause
  useEffect(() => {
    if (phase !== "done") return;
    const t = setTimeout(() => {
      setLines([]);
      setCmdIndex(0);
      setTyped("");
      setPhase("typing");
    }, 3500);
    return () => clearTimeout(t);
  }, [phase]);

  const showCaret = phase === "typing";

  return (
    <div className="w-full max-w-xl rounded-xl border border-white/10 bg-[#0c0c0e]/90 shadow-2xl shadow-black/40 backdrop-blur-md">
      {/* Title bar */}
      <div className="flex items-center gap-2 border-b border-white/10 px-4 py-2.5">
        <span className="h-3 w-3 rounded-full bg-[#ff5f57]" />
        <span className="h-3 w-3 rounded-full bg-[#febc2e]" />
        <span className="h-3 w-3 rounded-full bg-[#28c840]" />
        <span className="ml-3 font-mono text-[11px] text-zinc-500">
          revo-shell — zsh
        </span>
      </div>
      {/* Body */}
      <div className="min-h-[160px] space-y-1.5 p-4 font-mono text-[13px] leading-relaxed">
        {lines.map((l, i) =>
          l.type === "cmd" ? (
            <div key={i} className="text-zinc-100">
              <span className="text-emerald-400">➜</span>{" "}
              <span className="text-sky-400">~</span>{" "}
              <span className="text-zinc-400">$</span> {l.text}
            </div>
          ) : (
            <div key={i} className="pl-4 text-zinc-400">
              {l.text}
            </div>
          )
        )}
        {phase !== "done" && cmdIndex < commands.length && (
          <div className="text-zinc-100">
            <span className="text-emerald-400">➜</span>{" "}
            <span className="text-sky-400">~</span>{" "}
            <span className="text-zinc-400">$</span> {typed}
            {showCaret && (
              <span className="caret ml-0.5 inline-block h-4 w-[7px] translate-y-[2px] bg-zinc-100" />
            )}
          </div>
        )}
      </div>
    </div>
  );
}
