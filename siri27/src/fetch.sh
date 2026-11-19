#!/bin/bash
# Fetch + build the local voice stack for Siri27 (whisper.cpp + Piper)
set -e
S=$HOME/.local/share/siri27
mkdir -p "$S/src" "$S/models" "$S/voices"
cd $S/src
echo "== whisper.cpp"
[ -d whisper.cpp ] || git clone -q --depth 1 https://github.com/ggml-org/whisper.cpp
cd whisper.cpp
export PATH=/opt/cuda/bin:$PATH
GPU=""
if command -v nvcc >/dev/null 2>&1; then GPU="-DGGML_CUDA=ON"        # NVIDIA
elif command -v glslc >/dev/null 2>&1; then GPU="-DGGML_VULKAN=ON"   # AMD / Intel
fi
echo "   GPU backend: ${GPU:-none (CPU)}"
cmake -B build $GPU -DCMAKE_BUILD_TYPE=Release -DWHISPER_BUILD_EXAMPLES=ON >/dev/null
cmake --build build -j"$(nproc)" --config Release 2>&1 | tail -2
cd $S/models
echo "== whisper model"
[ -f ggml-large-v3-turbo-q5_0.bin ] || curl -sSL -o ggml-large-v3-turbo-q5_0.bin https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-large-v3-turbo-q5_0.bin
echo "== piper"
cd $S/src
[ -d piper ] || (curl -sSL -o piper.tgz https://github.com/rhasspy/piper/releases/download/2023.11.14-2/piper_linux_x86_64.tar.gz && tar xzf piper.tgz && rm piper.tgz)
cd $S/voices
V=https://huggingface.co/rhasspy/piper-voices/resolve/v1.0.0
for v in ar/ar_JO/kareem/medium/ar_JO-kareem-medium en/en_US/hfc_female/medium/en_US-hfc_female-medium; do
  f=$(basename $v)
  [ -f $f.onnx ] || curl -sSL -o $f.onnx $V/$v.onnx
  [ -f $f.onnx.json ] || curl -sSL -o $f.onnx.json $V/$v.onnx.json
done
ls -la $S/models $S/voices $S/src/piper/piper $S/src/whisper.cpp/build/bin/whisper-cli
echo DONE
