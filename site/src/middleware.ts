import { NextResponse, type NextRequest } from "next/server";

export function middleware(request: NextRequest) {
  const session = request.cookies.get("revo_session")?.value;
  if (session === "1") {
    return NextResponse.next();
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
