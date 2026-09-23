"use client";

import { useEffect, useState } from "react";

export type AuthUser = {
  name?: string;
  email?: string;
  picture?: string;
};

const STORAGE_KEY = "revo_google_user";

export function readStoredUser(): AuthUser | null {
  if (typeof window === "undefined") return null;
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    return raw ? (JSON.parse(raw) as AuthUser) : null;
  } catch {
    return null;
  }
}

export function storeUser(user: AuthUser) {
  try {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(user));
  } catch {
    /* ignore */
  }
}

export function clearStoredUser() {
  try {
    localStorage.removeItem(STORAGE_KEY);
  } catch {
    /* ignore */
  }
}

export async function createSession(): Promise<boolean> {
  try {
    const res = await fetch("/api/session", { method: "POST" });
    return res.ok;
  } catch {
    return false;
  }
}

export async function destroySession(): Promise<void> {
  try {
    await fetch("/api/session", { method: "DELETE" });
  } catch {
    /* ignore */
  }
}

export function useAuthUser(): AuthUser | null | undefined {
  const [user, setUser] = useState<AuthUser | null | undefined>(undefined);

  useEffect(() => {
    const refresh = () => setUser(readStoredUser());
    refresh();
    const onStorage = (e: StorageEvent) => {
      if (e.key === STORAGE_KEY) refresh();
    };
    const onAuth = () => refresh();
    window.addEventListener("storage", onStorage);
    window.addEventListener("revo-auth", onAuth);
    return () => {
      window.removeEventListener("storage", onStorage);
      window.removeEventListener("revo-auth", onAuth);
    };
  }, []);

  return user;
}

export function scrollToSignIn() {
  const el =
    document.querySelector<HTMLElement>("[data-testid='google-signin']") ??
    document.getElementById("download");
  el?.scrollIntoView({ behavior: "smooth", block: "center" });
}
