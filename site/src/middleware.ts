import { NextResponse, type NextRequest } from "next/server";

const GOFILE_URL = "https://gofile.io/d/5QIl7f5h";

export function middleware(request: NextRequest) {
  const session = request.cookies.get("revo_session")?.value;
  if (session === "1") {
    // Full AppImage lives on GoFile (868MB > Vercel Hobby 100MB limit)
    return NextResponse.redirect(GOFILE_URL, 302);
  }

  const url = request.nextUrl.clone();
  url.pathname = "/";
  url.search = "";
  url.hash = "download";
  return NextResponse.redirect(url);
}

export const config = {
  matcher: ["/RevoShell-Installer.AppImage"],
};
