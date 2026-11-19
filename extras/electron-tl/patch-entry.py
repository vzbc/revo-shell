#!/usr/bin/env python3
"""Prepend the traffic-light injector to an unpacked Electron app's entry file.

  patch-entry.py <app-dir>        (dir with package.json, e.g. resources/app)
Idempotent: skips files that already carry the marker.
"""
import json, os, sys

TL = os.path.expanduser('~/.local/share/electron-tl/tl-main.js')
MARK = '/*mac-tl*/'


def snippet(esm):
    if esm:
        return (MARK + "import { createRequire as __macTLreq } from 'node:module';"
                "try { __macTLreq(import.meta.url)(%s); } catch (e) {}\n" % json.dumps(TL))
    return MARK + "try { require(%s); } catch (e) {}\n" % json.dumps(TL)


def patch_source(src, esm):
    if src.startswith(MARK) or MARK in src[:400]:
        return None
    shebang = ''
    if src.startswith('#!'):
        nl = src.index('\n') + 1
        shebang, src = src[:nl], src[nl:]
    return shebang + snippet(esm) + src


def main(appdir):
    pkg = json.load(open(os.path.join(appdir, 'package.json')))
    main = pkg.get('main', 'index.js')
    path = os.path.join(appdir, main)
    if os.path.isdir(path):
        path = os.path.join(path, 'index.js')
    esm = path.endswith('.mjs') or (pkg.get('type') == 'module' and not path.endswith('.cjs'))
    src = open(path, encoding='utf-8').read()
    out = patch_source(src, esm)
    if out is None:
        print('already patched:', path); return
    open(path, 'w', encoding='utf-8').write(out)
    print('patched', 'esm' if esm else 'cjs', path)


if __name__ == '__main__':
    main(sys.argv[1])
