#!/usr/bin/env python3
"""Atomically write macduo settings.json (argv: full json string)."""
import json
import os
import sys
import tempfile

PATH = os.path.expanduser("~") + "/.config/quickshell/macduo/settings.json"


def main():
    if len(sys.argv) < 2:
        return
    data = json.loads(sys.argv[1])
    directory = os.path.dirname(PATH)
    fd, tmp = tempfile.mkstemp(dir=directory, prefix=".settings.")
    try:
        with os.fdopen(fd, "w") as f:
            json.dump(data, f, indent=2)
        os.replace(tmp, PATH)
    except Exception:
        try:
            os.unlink(tmp)
        except OSError:
            pass
        raise


if __name__ == "__main__":
    main()
