{
  self,
  athroisma,
  congeries,
}: {
  config,
  lib,
  pkgs,
  ...
}: let
  system = pkgs.stdenv.hostPlatform.system;
  cfg = config.programs.zesis;
  pkexecShim = pkgs.runCommand "zesis-pkexec-shim" {} ''
    mkdir -p $out/bin
    ln -s /run/wrappers/bin/pkexec $out/bin/pkexec
  '';
in {
  options.programs.zesis = (import ./zesis-options.nix {inherit athroisma congeries;}) {
    inherit lib pkgs;
    deployPath = "$XDG_CONFIG_HOME/quickshell/zesis";
    # /var/cache/zesis/starfield/RealStarField.js cannot be written to.
    # We point to per-user cache.
    configPackageDefault = self.lib.mkConfig {
      inherit system;
      starfieldPath = "${config.xdg.cacheHome}/zesis/starfield/RealStarField.js";
    };
    systemdEnableDefault = false;
  };

  config = lib.mkIf cfg.enable {
    xdg.configFile."quickshell/zesis".source = cfg.configPackage;

    home.packages = lib.optional (cfg.package != null) cfg.package;

    systemd.user.services.zesis = lib.mkIf cfg.systemd.enable {
      Unit = {
        Description = "Quickshell (zesis)";
        After = ["graphical-session.target"];
        PartOf = ["graphical-session.target"];
      };

      Service = {
        ExecStart = "${cfg.package}/bin/quickshell -c zesis";
        Restart = "on-failure";
        RestartSec = 5;
        Environment =
          [
            "PATH=${
              lib.concatStringsSep ":" (
                ["${cfg.python}/bin"]
                ++ lib.optional cfg.athroisma.enable "${cfg.athroisma.package}/bin"
                ++ lib.optional (cfg.secretTool == "oo7") "${pkgs.oo7}/bin"
                ++ lib.optional (cfg.secretTool == "secret-tool") "${pkgs.libsecret}/bin"
                ++ lib.optionals cfg.batteriesIncluded.enable (map (p: "${p}/bin") cfg.batteriesIncluded.packages)
                ++ lib.optional cfg.usePkexec "${pkexecShim}/bin"
                ++ lib.optionals cfg.inheritPath ["${config.home.profileDirectory}/bin" "/run/current-system/sw/bin"]
              )
            }"
          ]
          ++ lib.optional cfg.congeries.enable "QML_IMPORT_PATH=${
            lib.concatStringsSep ":" [
              "${pkgs.qt6.qtquick3d}/lib/qt-6/qml"
              "${cfg.congeries.package}/lib/qt-6/qml"
            ]
          }";
      };

      Install.WantedBy = ["graphical-session.target"];
    };

    assertions = [
      {
        assertion = !cfg.systemd.enable || cfg.package != null;
        message = "programs.zesis.package cannot be null when programs.zesis.systemd.enable is true";
      }
    ];
  };
}
