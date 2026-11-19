#!/usr/bin/env python3
"""Siri27 backend for the macOS shell (Quickshell).

  siri27d.py listen        record until silence -> whisper -> brain -> speak
  siri27d.py ask "text"    typed request (Type to Siri) -> brain -> speak

Emits one JSON object per line on stdout:
  {"state": "listening|thinking|speaking|idle"}
  {"level": 0..1}          microphone power while listening (drives the glow)
  {"heard": "..."}         transcription
  {"delta": "..."}         streamed answer text
  {"answer": "..."}        full answer
  {"error": "..."}

Brain providers (~/.config/siri27/config.json): "ollama" (local GPU),
"openai" (ChatGPT) or "anthropic" (Claude). API keys are read from the
config file or from OPENAI_API_KEY / ANTHROPIC_API_KEY.
"""
import json, os, re, signal, struct, subprocess, sys, tempfile, time, urllib.request, urllib.error, wave, math

HOME = os.path.expanduser('~')
BASE = os.path.join(HOME, '.local/share/siri27')
CONF = os.path.join(HOME, '.config/siri27/config.json')
WHISPER = os.path.join(BASE, 'src/whisper.cpp/build/bin/whisper-cli')
WHISPER_MODEL = os.path.join(BASE, 'models/ggml-large-v3-turbo-q5_0.bin')
PIPER = os.path.join(BASE, 'src/piper/piper')
# activation sound: sounds/activate.wav (yours), else macOS 27's siri-begin-improved
BEGIN_SOUND = next((p for p in (os.path.join(BASE, 'sounds/activate.wav'),
                                os.path.join(BASE, 'sounds/siri-begin-improved.wav')) if os.path.exists(p)), '')

DEFAULT_CONF = {
    "provider": "ollama",
    "language": "auto",
    "speak": True,
    "system_prompt": "You are Siri. Answer briefly and helpfully, in the same language as the user (Arabic or English). Keep spoken answers to one or two short sentences unless asked for more.",
    "ollama": {"url": "http://127.0.0.1:11434", "model": "llama3.2"},
    "openai": {"api_key": "", "model": "gpt-4o-mini", "url": "https://api.openai.com/v1/chat/completions"},
    "anthropic": {"api_key": "", "model": "claude-sonnet-5-5", "url": "https://api.anthropic.com/v1/messages"},
    "voices": {"ar": "ar_JO-kareem-medium", "en": "en_US-hfc_female-medium"},
    "begin_sound": True,            # macOS 27 start-listening chime (CSSiriSpeechRecorder: siri-begin-improved)
    # System Settings › Apple Intelligence & Siri
    "apple_intelligence": True,
    "enabled": True,                # Siri
    "listen_for": "off",
    "allow_when_locked": False,
    "shortcut": "SUPER + ALT + S",  # press = Type to Siri, hold = speak
    "spoken_responses": "automatic",  # automatic | silent | spoken
    "captions": True,               # Always show Siri captions
    "show_speech": True,            # Always show speech
    "history": True,
    "silence_seconds": 1.2,
    "max_seconds": 15,
}


def emit(**kw):
    sys.stdout.write(json.dumps(kw, ensure_ascii=False) + '\n')
    sys.stdout.flush()


def load_conf():
    os.makedirs(os.path.dirname(CONF), exist_ok=True)
    if not os.path.exists(CONF):
        with open(CONF, 'w') as f:
            json.dump(DEFAULT_CONF, f, indent=2, ensure_ascii=False)
    with open(CONF) as f:
        c = json.load(f)
    merged = json.loads(json.dumps(DEFAULT_CONF))
    for k, v in c.items():
        if isinstance(v, dict) and isinstance(merged.get(k), dict):
            merged[k].update(v)
        else:
            merged[k] = v
    return merged


STOP = False          # SIGUSR1: the Siri key was released (hold-to-talk)


def _stop(*_):
    global STOP
    STOP = True


signal.signal(signal.SIGUSR1, _stop)


# ---------------------------------------------------------------- listening
def record(conf, ptt=False):
    """16 kHz mono s16 from PipeWire until silence; streams level events."""
    emit(state='listening')
    # Siri's begin chime; mic audio is dropped until it has finished so the
    # chime never lands in the recording or trips the voice detector.
    chime = None
    if conf.get('begin_sound', True) and os.path.exists(BEGIN_SOUND):
        chime = subprocess.Popen(['pw-play', BEGIN_SOUND], stderr=subprocess.DEVNULL)
    rate = 16000
    proc = subprocess.Popen(['pw-record', '--rate', str(rate), '--channels', '1', '--format', 's16', '-'],
                            stdout=subprocess.PIPE, stderr=subprocess.DEVNULL)
    chime_tail = None
    frames = bytearray()
    chunk = rate // 20 * 2          # 50 ms
    noise = None
    speech = False
    quiet_for = 0.0
    start = time.time()
    try:
        while True:
            buf = proc.stdout.read(chunk)
            if not buf:
                break
            if chime is not None:
                if chime.poll() is None:
                    start = time.time()
                    continue
                chime_tail = chime_tail or time.time()
                if time.time() - chime_tail < 0.12:   # room echo of the chime
                    start = time.time()
                    continue
                chime = None
            frames += buf
            if STOP:
                # key released: send whatever was said (>= 0.3 s of audio)
                speech = speech or len(frames) > rate * 2 * 0.3
                break
            n = len(buf) // 2
            s = struct.unpack('<%dh' % n, buf[:n * 2])
            rms = math.sqrt(sum(x * x for x in s) / max(1, n)) / 32768.0
            if noise is None:
                noise = rms
            noise = min(noise * 1.002 + 1e-6, rms) if not speech else noise
            level = max(0.0, min(1.0, (20 * math.log10(max(rms, 1e-5)) + 50) / 40))
            emit(level=round(level, 3))
            loud = rms > max(0.012, noise * 3.0)
            if loud:
                speech = True
                quiet_for = 0.0
            elif speech:
                quiet_for += 0.05
            el = time.time() - start
            if ptt:
                if el >= max(30, conf['max_seconds']):
                    break
            elif (speech and quiet_for >= conf['silence_seconds']) or el >= conf['max_seconds'] or (not speech and el > 6):
                break
    finally:
        proc.terminate()
    emit(level=0)
    if not speech:
        return None
    path = tempfile.mktemp(suffix='.wav', prefix='siri27-')
    with wave.open(path, 'wb') as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(rate); w.writeframes(bytes(frames))
    return path


def transcribe(path, conf):
    emit(state='thinking')
    if not (os.path.exists(WHISPER) and os.path.exists(WHISPER_MODEL)):
        os.unlink(path)
        raise RuntimeError("Voice isn't set up yet. Run ~/.local/share/siri27/src/fetch.sh (or type to Siri).")
    lang = conf.get('language', 'auto')
    out = subprocess.run([WHISPER, '-m', WHISPER_MODEL, '-f', path, '-l', lang, '-nt', '-np'],
                         capture_output=True, text=True)
    os.unlink(path)
    text = ' '.join(l.strip() for l in out.stdout.splitlines() if l.strip())
    text = re.sub(r'\[.*?\]|\(.*?\)', '', text).strip()
    return text


# -------------------------------------------------------------------- brain
def _post(url, body, headers):
    req = urllib.request.Request(url, data=json.dumps(body).encode(), headers=headers)
    try:
        return urllib.request.urlopen(req, timeout=120)
    except urllib.error.URLError as e:
        if '11434' in url:
            raise RuntimeError("Couldn't reach the local model (Ollama). Install and start it, or pick ChatGPT/Claude "
                               "in System Settings › Apple Intelligence & Siri.") from e
        raise


def ask(text, conf):
    emit(state='thinking')
    prov = conf.get('provider', 'ollama')
    sysmsg = conf['system_prompt']
    answer = ''
    if prov == 'openai':
        c = conf['openai']
        key = c.get('api_key') or os.environ.get('OPENAI_API_KEY', '')
        if not key:
            raise RuntimeError('OpenAI API key missing in ~/.config/siri27/config.json')
        r = _post(c['url'], {"model": c['model'], "stream": True,
                             "messages": [{"role": "system", "content": sysmsg}, {"role": "user", "content": text}]},
                  {"Content-Type": "application/json", "Authorization": "Bearer " + key})
        for line in r:
            line = line.decode().strip()
            if not line.startswith('data:') or line.endswith('[DONE]'):
                continue
            d = json.loads(line[5:]).get('choices', [{}])[0].get('delta', {}).get('content')
            if d:
                answer += d; emit(delta=d)
    elif prov == 'anthropic':
        c = conf['anthropic']
        key = c.get('api_key') or os.environ.get('ANTHROPIC_API_KEY', '')
        if not key:
            raise RuntimeError('Anthropic API key missing in ~/.config/siri27/config.json')
        r = _post(c['url'], {"model": c['model'], "max_tokens": 1024, "stream": True, "system": sysmsg,
                             "messages": [{"role": "user", "content": text}]},
                  {"Content-Type": "application/json", "x-api-key": key, "anthropic-version": "2023-06-01"})
        for line in r:
            line = line.decode().strip()
            if not line.startswith('data:'):
                continue
            ev = json.loads(line[5:])
            if ev.get('type') == 'content_block_delta':
                d = ev.get('delta', {}).get('text')
                if d:
                    answer += d; emit(delta=d)
    else:
        c = conf['ollama']
        r = _post(c['url'].rstrip('/') + '/api/chat',
                  {"model": c['model'], "stream": True,
                   "messages": [{"role": "system", "content": sysmsg}, {"role": "user", "content": text}]},
                  {"Content-Type": "application/json"})
        for line in r:
            if not line.strip():
                continue
            d = json.loads(line).get('message', {}).get('content')
            if d:
                answer += d; emit(delta=d)
    answer = answer.strip()
    emit(answer=answer)
    return answer


# -------------------------------------------------------------------- voice
def should_speak(conf, voice):
    mode = conf.get('spoken_responses', 'automatic')
    if conf.get('speak') is False:       # pre-settings configs
        mode = 'silent'
    if mode == 'silent':
        return False
    if mode == 'spoken':
        return True
    return voice                          # Automatic: talk back when you talked


def log_history(conf, text, answer):
    if not conf.get('history', True):
        return
    try:
        with open(os.path.join(BASE, 'history.jsonl'), 'a') as f:
            f.write(json.dumps({'t': int(time.time()), 'provider': conf.get('provider'), 'q': text, 'a': answer},
                               ensure_ascii=False) + '\n')
    except OSError:
        pass


def speak(text, conf):
    if not text or not os.path.exists(PIPER):
        return
    emit(state='speaking')
    arabic = len(re.findall(r'[؀-ۿ]', text)) > len(text) * 0.2
    voice = conf['voices']['ar' if arabic else 'en']
    model = os.path.join(BASE, 'voices', voice + '.onnx')
    clean = re.sub(r'[*_`#>]+', '', text)
    wav = tempfile.mktemp(suffix='.wav', prefix='siri27-tts-')
    subprocess.run([PIPER, '--model', model, '--output_file', wav], input=clean, text=True,
                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    if os.path.exists(wav):
        subprocess.run(['pw-play', wav], stderr=subprocess.DEVNULL)
        os.unlink(wav)


def main():
    conf = load_conf()
    try:
        if not (conf.get('enabled', True) and conf.get('apple_intelligence', True)):
            emit(error='Siri is turned off in System Settings.'); return
        voice = False
        if len(sys.argv) >= 2 and sys.argv[1] == 'listen':
            voice = True
            wav = record(conf, ptt='ptt' in sys.argv[2:])
            if not wav:
                emit(error="I didn't hear anything."); return
            text = transcribe(wav, conf)
            if not text:
                emit(error="I didn't catch that."); return
            emit(heard=text)
        elif len(sys.argv) >= 3 and sys.argv[1] == 'ask':
            text = ' '.join(sys.argv[2:])
            emit(heard=text)
        else:
            print(__doc__); return
        answer = ask(text, conf)
        log_history(conf, text, answer)
        emit(spoken=should_speak(conf, voice))
        if should_speak(conf, voice):
            speak(answer, conf)
    except Exception as e:
        emit(error=str(e))
    finally:
        emit(state='idle')


if __name__ == '__main__':
    main()
