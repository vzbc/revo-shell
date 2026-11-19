#!/usr/bin/env python3
"""Prepend the macOS traffic-light injector to an Electron app.asar's entry.

  patch-asar.py <app.asar> [--out FILE] [--check]

The new entry file is appended to the archive's data area and the header is
updated (offset, size, SHA256 integrity), so nothing else moves. Keeps a
one-time backup next to the archive as app.asar.mac-tl-orig. Idempotent.
The injected line only require()s ~USER/.local/share/electron-tl/tl-main.js
inside try/catch, so a missing file just means no traffic lights.
"""
import hashlib, json, os, struct, sys

MARK = b'/*mac-tl*/'
BLOCK = 4 * 1024 * 1024


def tl_path():
    user = os.environ.get('SUDO_USER') or os.environ.get('MAC_TL_USER')
    home = os.path.expanduser('~' + user) if user else os.path.expanduser('~')
    return os.path.join(home, '.local/share/electron-tl/tl-main.js')


def read_asar(p):
    with open(p, 'rb') as f:
        a = f.read(16)
        _, header_size, _, json_len = struct.unpack('<4I', a)
        f.seek(16)
        header = json.loads(f.read(json_len))
        base = 8 + header_size
        f.seek(0, 2)
        end = f.tell()
    return header, base, end


def find(header, rel):
    node = header
    for part in rel.strip('/').split('/'):
        node = node['files'][part]
    return node


def read_file(p, base, node):
    with open(p, 'rb') as f:
        f.seek(base + int(node['offset']))
        return f.read(node['size'])


def integrity(data):
    return {'algorithm': 'SHA256', 'hash': hashlib.sha256(data).hexdigest(), 'blockSize': BLOCK,
            'blocks': [hashlib.sha256(data[i:i + BLOCK]).hexdigest() for i in range(0, max(len(data), 1), BLOCK)]}


def snippet(esm, path):
    if esm:
        return (MARK + b"import { createRequire as __macTLreq } from 'node:module';"
                b"try { __macTLreq(import.meta.url)(" + json.dumps(path).encode() + b"); } catch (e) {}\n")
    return MARK + b"try { require(" + json.dumps(path).encode() + b"); } catch (e) {}\n"


def entry_of(p, header, base):
    pkg = json.loads(read_file(p, base, find(header, 'package.json')))
    main = os.path.normpath(pkg.get('main') or 'index.js')
    while main.startswith('./'):
        main = main[2:]
    try:
        node = find(header, main)
        if 'files' in node:
            main = main.rstrip('/') + '/index.js'
            node = find(header, main)
    except KeyError:
        if not main.endswith('.js'):
            main += '.js'
        node = find(header, main)
    esm = main.endswith('.mjs') or (pkg.get('type') == 'module' and not main.endswith('.cjs'))
    return main, node, esm


def patch(p, out=None, check=False):
    header, base, end = read_asar(p)
    main, node, esm = entry_of(p, header, base)
    if node.get('unpacked'):
        sys.exit('entry %s is unpacked; patch app.asar.unpacked/%s instead' % (main, main))
    src = read_file(p, base, node)
    if MARK in src[:600]:
        print('already patched:', p, main)
        return
    if check:
        print('would patch', p, main, 'esm' if esm else 'cjs')
        return
    shebang = b''
    if src.startswith(b'#!'):
        nl = src.index(b'\n') + 1
        shebang, src = src[:nl], src[nl:]
    new = shebang + snippet(esm, tl_path()) + src
    data_len = end - base
    node['offset'] = str(data_len)
    node['size'] = len(new)
    node['integrity'] = integrity(new)
    js = json.dumps(header, separators=(',', ':')).encode()
    pad = (-len(js)) % 4
    payload = struct.pack('<I', len(js)) + js + b'\0' * pad
    hpickle = struct.pack('<I', len(payload)) + payload
    first = struct.pack('<II', 4, len(hpickle))
    dst = out or p
    tmp = dst + '.mac-tl-tmp'
    with open(p, 'rb') as fi, open(tmp, 'wb') as fo:
        fo.write(first + hpickle)
        fi.seek(base)
        while True:
            b = fi.read(1 << 20)
            if not b:
                break
            fo.write(b)
        fo.write(new)
    st = os.stat(p)
    os.chmod(tmp, st.st_mode & 0o7777)
    try:
        os.chown(tmp, st.st_uid, st.st_gid)
    except PermissionError:
        pass
    # verify before swapping in
    h2, b2, _ = read_asar(tmp)
    m2, n2, _ = entry_of(tmp, h2, b2)
    assert read_file(tmp, b2, n2) == new and m2 == main
    for rel in ('package.json',):
        assert read_file(tmp, b2, find(h2, rel)) == read_file(p, base, find(header, rel))
    if out is None:
        bak = p + '.mac-tl-orig'          # pristine copy of the current version
        if os.path.exists(bak):
            os.unlink(bak)
        os.link(p, bak)
    os.replace(tmp, dst)
    print('patched', dst, main, 'esm' if esm else 'cjs')


if __name__ == '__main__':
    args = sys.argv[1:]
    out = args[args.index('--out') + 1] if '--out' in args else None
    patch(args[0], out, '--check' in args)
