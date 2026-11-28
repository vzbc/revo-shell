#!/usr/bin/env python3
"""hiresart.py ART_URL ARTIST TITLE ALBUM — print a sharper cover for the lock screen.

Players often hand MPRIS a tiny cover: Chromium/Firefox write a 150x150 PNG to
/tmp, Spotify sends its 300 px size, YouTube a 480x360 thumbnail. Stretched to
the lock screen's big artwork that looks soft and blocky. This prints one URL
per line, each better than the one before (the shell keeps the last):
  1. a known CDN's larger size (Spotify 640 px, YouTube maxres, Google 1200 px)
  2. a local 1024 px Lanczos + unsharp upscale of a small cover (instant, offline)
  3. the matching cover from the iTunes Search API at 1200 px (Deezer as backup)
Covers and misses are cached in ~/.cache/maclock/art.
"""
import hashlib, io, json, os, re, sys, unicodedata, urllib.parse, urllib.request

CACHE = os.path.expanduser("~/.cache/maclock/art")
UA = "MacLock/1.0 (lock screen artwork)"


def out(u):
    print(u, flush=True)


def norm(s):
    s = unicodedata.normalize("NFKC", s or "").casefold()
    s = re.sub(r"\s*[(\[][^)\]]*[)\]]", "", s)                     # (feat. …), [Remastered]
    s = re.sub(r"\s+-\s+.*(remaster|live|edit|version|mix).*$", "", s)
    s = re.sub(r"\b(feat|ft)\.?\s.*$", "", s)
    return re.sub(r"[\W_]+", "", s)


def get(url, timeout=6):
    req = urllib.request.Request(url, headers={"User-Agent": UA})
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return r.read()


def cdn_upgrade(u):
    if "i.scdn.co/image/" in u:                                    # Spotify: 1e02 = 300 px, b273 = 640 px
        return re.sub(r"ab67616d0000(1e02|4851)", "ab67616d0000b273", u)
    if "ytimg.com/vi/" in u:
        return re.sub(r"/(default|mqdefault|hqdefault|sddefault)(\.\w+)", r"/maxresdefault\2", u)
    if "googleusercontent.com" in u or "ggpht.com" in u:           # YouTube Music
        return re.sub(r"=w\d+-h\d+[^/]*$", "=w1200-h1200-l90-rj", u)
    return None


def upscale(path):
    try:
        from PIL import Image, ImageFilter
    except ImportError:
        return None
    try:
        data = open(path, "rb").read()
        im = Image.open(io.BytesIO(data)).convert("RGB")
    except OSError:
        return None
    if max(im.size) >= 600:
        return None
    f = os.path.join(CACHE, "up-" + hashlib.md5(data).hexdigest()[:16] + ".png")
    if not os.path.exists(f):
        w, h = im.size
        s = 1024 / max(w, h)
        im = im.resize((round(w * s), round(h * s)), Image.LANCZOS)
        im = im.filter(ImageFilter.UnsharpMask(radius=2.2, percent=70, threshold=2))
        im.save(f + ".tmp.png"); os.replace(f + ".tmp.png", f)
    return "file://" + f


def itunes(artist, title, album):
    for term, ent in ((artist + " " + title, "song"), (title, "song")):
        q = urllib.parse.urlencode({"term": term, "entity": ent, "limit": 25, "media": "music"})
        try:
            res = json.loads(get("https://itunes.apple.com/search?" + q)).get("results", [])
        except Exception:
            return None, False
        na, nt, nal = norm(artist), norm(title), norm(album)
        best = None
        for r in res:
            ra, rt = norm(r.get("artistName")), norm(r.get("trackName"))
            if not rt or not (rt == nt or (len(nt) > 3 and (rt.startswith(nt) or nt.startswith(rt)))):
                continue
            if na and not (na in ra or ra in na):
                continue
            score = 2 if nal and norm(r.get("collectionName")) == nal else 1
            if not best or score > best[0]:
                best = (score, r)
        if best and best[1].get("artworkUrl100"):
            return re.sub(r"/\d+x\d+bb\.", "/1200x1200bb.", best[1]["artworkUrl100"]), True
    return None, True


def deezer(artist, title):
    q = urllib.parse.urlencode({"q": 'artist:"%s" track:"%s"' % (artist, title), "limit": 10})
    try:
        res = json.loads(get("https://api.deezer.com/search?" + q)).get("data", [])
    except Exception:
        return None, False
    na, nt = norm(artist), norm(title)
    for r in res:
        if norm(r.get("title")) == nt and (not na or na in norm(r.get("artist", {}).get("name"))):
            u = r.get("album", {}).get("cover_xl")
            if u:
                return u, True
    return None, True


def main():
    url, artist, title, album = (sys.argv[1:] + [""] * 4)[:4]
    os.makedirs(CACHE, exist_ok=True)
    up = cdn_upgrade(url)
    if up and up != url:
        out(up)
        return                                                     # a CDN's own large size is the real cover
    if url.startswith("file://"):
        local = upscale(urllib.parse.unquote(url[7:]))
        if local:
            out(local)
    if not title:
        return
    key = hashlib.md5(("%s|%s|%s" % (artist, title, album)).encode()).hexdigest()[:16]
    f, miss = os.path.join(CACHE, key + ".jpg"), os.path.join(CACHE, key + ".none")
    if os.path.exists(f):
        out("file://" + f); return
    if os.path.exists(miss):
        return
    found, answered = itunes(artist, title, album)
    if not found:
        found, answered2 = deezer(artist, title)
        answered = answered and answered2
    if found:
        try:
            data = get(found, timeout=10)
            open(f + ".tmp", "wb").write(data); os.replace(f + ".tmp", f)
            out("file://" + f)
        except Exception:
            pass
    elif answered:
        open(miss, "w").close()                                    # no match anywhere: don't ask again


if __name__ == "__main__":
    main()
