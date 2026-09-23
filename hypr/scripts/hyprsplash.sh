#!/bin/bash
VIDEO="$HOME/Videos/steamgirl.mp4"
mpv --fullscreen --no-border --no-stop-screensaver \
    --really-quiet --loop-file=no --osd-level=0 \
    --no-osc --no-input-default-bindings "$VIDEO" &
MPV_PID=$!
sleep 10
kill $MPV_PID 2>/dev/null
