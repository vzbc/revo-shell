import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "Revo Shell — All your QuickShells in one place",
  description:
    "Revo Shell is the place to add all your QuickShells in one place. Install beautiful Hyprland + Quickshell desktops with one GUI installer.",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body className="noise antialiased">{children}</body>
    </html>
  );
}
