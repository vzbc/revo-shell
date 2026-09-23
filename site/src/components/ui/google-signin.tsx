"use client";

import { useEffect, useRef, useState } from "react";
import { GoogleIcon } from "@/components/icons/google";
import {
  clearStoredUser,
  createSession,
  destroySession,
  readStoredUser,
  storeUser,
  type AuthUser,
} from "@/lib/auth";

const CLIENT_ID =
  "404802591966-9idov983hkv7g8lm0avmc6qo699fi7o2.apps.googleusercontent.com";

declare global {
  interface Window {
    google?: {
      accounts: {
        id: {
          initialize: (config: {
            client_id: string;
            callback: (response: { credential: string }) => void;
          }) => void;
          renderButton: (
            parent: HTMLElement,
            options: {
              theme?: string;
              size?: string;
              text?: string;
              shape?: string;
              width?: number;
              locale?: string;
            },
          ) => void;
        };
      };
    };
  }
}

function decodeJwt(credential: string): Record<string, unknown> | null {
  try {
    const payload = credential.split(".")[1];
    const json = atob(payload.replace(/-/g, "+").replace(/_/g, "/"));
    return JSON.parse(json) as Record<string, unknown>;
  } catch {
    return null;
  }
}

export function GoogleSignInButton() {
  const containerRef = useRef<HTMLDivElement>(null);
  const [user, setUser] = useState<AuthUser | null>(null);
  const [ready, setReady] = useState(false);

  useEffect(() => {
    const handleCredential = (response: { credential: string }) => {
      const claims = decodeJwt(response.credential);
      if (!claims) return;
      const profile = {
        name: (claims["name"] as string) || (claims["email"] as string) || "Signed in",
        email: claims["email"] as string | undefined,
        picture: claims["picture"] as string | undefined,
      };
      setUser(profile);
      storeUser(profile);
      void createSession();
      window.dispatchEvent(new Event("revo-auth"));
    };

    const existing = readStoredUser();
    if (existing) {
      setUser(existing);
      void createSession();
    }

    const init = () => {
      if (!window.google?.accounts?.id || !containerRef.current) return;
      window.google.accounts.id.initialize({
        client_id: CLIENT_ID,
        callback: handleCredential,
      });
      window.google.accounts.id.renderButton(containerRef.current, {
        theme: "filled_black",
        size: "large",
        text: "continue_with",
        shape: "pill",
        width: 280,
        locale: "en",
      });
      setReady(true);
    };

    if (window.google?.accounts?.id) {
      init();
      return;
    }

    const script = document.createElement("script");
    script.src = "https://accounts.google.com/gsi/client?hl=en";
    script.async = true;
    script.defer = true;
    script.onload = init;
    script.onerror = () => setReady(false);
    document.head.appendChild(script);

    return () => {
      script.onload = null;
      script.onerror = null;
    };
  }, []);

  if (user) {
    return (
      <div className="inline-flex items-center gap-3 rounded-full border border-white/15 bg-white/5 px-4 py-2 text-sm text-white backdrop-blur">
        {user.picture ? (
          // eslint-disable-next-line @next/next/no-img-element
          <img
            src={user.picture}
            alt=""
            className="h-7 w-7 rounded-full"
            referrerPolicy="no-referrer"
          />
        ) : (
          <span className="flex h-7 w-7 items-center justify-center rounded-full bg-white text-black">
            <GoogleIcon className="h-4 w-4" />
          </span>
        )}
        <span className="max-w-[160px] truncate">{user.name ?? user.email ?? "Signed in"}</span>
        <button
          type="button"
          onClick={() => {
            setUser(null);
            clearStoredUser();
            void destroySession();
            window.dispatchEvent(new Event("revo-auth"));
          }}
          className="text-zinc-400 underline-offset-4 hover:text-white hover:underline"
        >
          Sign out
        </button>
      </div>
    );
  }

  return (
    <div className="flex flex-col items-center gap-2">
      <div ref={containerRef} data-testid="google-signin" />
      {!ready && (
        <span className="inline-flex items-center gap-3 rounded-full border border-white/15 bg-white/5 px-6 py-3 text-sm font-medium text-white backdrop-blur">
          <span className="flex h-8 w-8 items-center justify-center rounded-full bg-white">
            <GoogleIcon className="h-4 w-4" />
          </span>
          Continue with Google
        </span>
      )}
    </div>
  );
}
