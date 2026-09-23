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
  cfg = config.services.zesis;
  pkexecShim = pkgs.runCommand "zesis-pkexec-shim" {} ''
    mkdir -p $out/bin
    ln -s /run/wrappers/bin/pkexec $out/bin/pkexec
  '';
in {
  options.services.zesis =
    (import ./zesis-options.nix {inherit athroisma congeries;}) {
      inherit lib pkgs;
      deployPath = "/etc/xdg/quickshell/zesis";
      configPackageDefault = self.packages.${system}.config;
      systemdEnableDefault = true;
    }
    // {
      pam.enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = ''
          Register the `security.pam.services.quickshell` PAM service the
          lock screen authenticates against (`PamContext { config: "quickshell"; }`
          in `LockSurface.qml`). Without this, unlocking always fails.
        '';
      };
    };

  config = lib.mkIf cfg.enable {
    environment.etc."xdg/quickshell/zesis".source = cfg.configPackage;

    security.pam.services.quickshell = lib.mkIf cfg.pam.enable (lib.mkDefault {});

    systemd.tmpfiles.rules = lib.mkIf cfg.congeries.enable [
      "d /var/cache/zesis/starfield 1777 root root -"
    ];

    systemd.user.services.zesis = lib.mkIf cfg.systemd.enable {
      description = "Quickshell (zesis)";
      wantedBy = ["graphical-session.target"];
      after = ["graphical-session.target"];
      partOf = ["graphical-session.target"];

      enableDefaultPath = false;
      environment =
        {
          PATH = lib.concatStringsSep ":" (
            ["${cfg.python}/bin"]
            ++ lib.optional cfg.athroisma.enable "${cfg.athroisma.package}/bin"
            ++ lib.optional (cfg.secretTool == "oo7") "${pkgs.oo7}/bin"
            ++ lib.optional (cfg.secretTool == "secret-tool") "${pkgs.libsecret}/bin"
            ++ lib.optionals cfg.batteriesIncluded.enable (map (p: "${p}/bin") cfg.batteriesIncluded.packages)
            ++ lib.optional cfg.usePkexec "${pkexecShim}/bin"
            ++ lib.optionals cfg.inheritPath ["/run/current-system/sw/bin" "/etc/profiles/per-user/%u/bin"]
          );
        }
        // lib.optionalAttrs cfg.congeries.enable {
          QML_IMPORT_PATH = lib.concatStringsSep ":" [
            "${pkgs.qt6.qtquick3d}/lib/qt-6/qml"
            "${cfg.congeries.package}/lib/qt-6/qml"
          ];
        };
      serviceConfig = {
        ExecStart = "${cfg.package}/bin/quickshell -c zesis";
        Restart = "on-failure";
        RestartSec = 5;
      };
    };

    assertions = [
      {
        assertion = !cfg.systemd.enable || cfg.package != null;
        message = "services.zesis.package cannot be null when services.zesis.systemd.enable is true";
      }
    ];
  };
}
