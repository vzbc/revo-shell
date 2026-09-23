import * as React from "react";
import { cn } from "@/lib/utils";

type ButtonProps = React.ButtonHTMLAttributes<HTMLButtonElement> & {
  asChild?: boolean;
};

export function Button({
  className,
  asChild,
  children,
  ...props
}: ButtonProps) {
  const cls = cn(
    "inline-flex h-9 items-center justify-center gap-2 whitespace-nowrap rounded-md bg-zinc-900 px-4 py-2 text-sm font-medium text-zinc-50 shadow-sm transition-colors hover:bg-zinc-800 focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-zinc-400 disabled:pointer-events-none disabled:opacity-50 dark:bg-zinc-50 dark:text-zinc-900 dark:hover:bg-zinc-200",
    className,
  );

  if (asChild && React.isValidElement(children)) {
    const child = children as React.ReactElement<{ className?: string; children?: React.ReactNode }>;
    return React.cloneElement(child, {
      className: cn(cls, child.props.className),
    });
  }

  return (
    <button type="button" className={cls} {...props}>
      {children}
    </button>
  );
}
