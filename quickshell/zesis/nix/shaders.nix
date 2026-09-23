# Shader compilation. A package with pre-baked .qsb files (packages.shaders,
# mirroring the source tree so consumers can drop it alongside the matching
# .frag files) and a dev-facing `nix run .#compile-shaders` that regenerates
# them in-place next to their .frag sources in the working tree.
{
  lib,
  runCommand,
  writeShellScript,
  qt6,
  src,
}: let
  shaderNames = ["globe" "gear"];
  findShaders = "find . -name '_*' -prune -o -name '*.frag' -not -path '*/_*' -print | grep -E '/(${lib.concatStringsSep "|" shaderNames})\\.frag$'";
in {
  package =
    runCommand "zesis-shaders" {
      nativeBuildInputs = [qt6.qtshadertools];
    } ''
      mkdir -p "$out"
      cd ${src}
      for f in $(${findShaders}); do
        mkdir -p "$out/$(dirname "$f")"
        qsb --qt6 -o "$out/''${f%.frag}.qsb" "$f"
      done
    '';

  compile = writeShellScript "compile-shaders" ''
    set -euo pipefail
    for f in $(${findShaders}); do
      echo "compiling $f"
      ${qt6.qtshadertools}/bin/qsb --qt6 -o "''${f%.frag}.qsb" "$f"
    done
  '';
}
