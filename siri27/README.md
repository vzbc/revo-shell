# Siri27 — Siri for the macOS shell

Backend for `quickshell/macos/modules/siri` (edge glow + Type to Siri bubble).
`install.sh` copies this folder to `~/.local/share/siri27`.

| File | What it does |
|------|--------------|
| `siri27d.py` | listen (mic → whisper.cpp) / ask (typed) → model → Piper voice; JSON lines to the shell |
| `siri27ctl.py` | helper for System Settings › Apple Intelligence & Siri (shortcut, Ollama models, voices, history) |
| `src/fetch.sh` | builds whisper.cpp (CUDA / Vulkan / CPU) and downloads the speech + voice models (~700 MB) |
| `sounds/` | activation sound (`activate.wav`) |

- **Type to Siri** works right away with a local model (install and start [Ollama](https://ollama.com),
  then pick a model in System Settings › Apple Intelligence & Siri › Local Model) or with a
  ChatGPT / Claude API key (same pane, Extensions).
- **Voice** needs the speech stack once: `~/.local/share/siri27/src/fetch.sh`
- Shortcut: press `Super + Alt + S` to type, hold it to speak (changeable in System Settings).
- Settings file: `~/.config/siri27/config.json` (created on first use).
