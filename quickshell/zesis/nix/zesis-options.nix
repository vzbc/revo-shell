{
  athroisma,
  congeries,
}: {
  lib,
  pkgs,
  # Where the deployed config lands, for option docs only
  # (e.g. "/etc/xdg/quickshell/zesis" or "$XDG_CONFIG_HOME/quickshell/zesis").
  deployPath,
  configPackageDefault,
  systemdEnableDefault ? false,
}: let
  system = pkgs.stdenv.hostPlatform.system;
in {
  enable = lib.mkEnableOption ''
    zesis, deployed as a named Quickshell config (`${deployPath}`). Any
    manual `quickshell`/`qs` invocation, IPC calls in your compositor
    keybinds, debugging, etc. must pass `-c zesis` (or
    `QS_CONFIG_NAME=zesis`) or it won't find this instance
  '';

  package = lib.mkOption {
    type = lib.types.nullOr lib.types.package;
    default = pkgs.quickshell;
    description = "The quickshell package to run zesis with.";
  };

  configPackage = lib.mkOption {
    type = lib.types.package;
    default = configPackageDefault;
    description = ''
      The zesis QML source (merged with its compiled shaders) deployed to
      `${deployPath}`.
    '';
  };

  athroisma = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Put athroisma on the service's PATH, for the System Monitor widget.";
    };
    package = lib.mkOption {
      type = lib.types.package;
      default = athroisma.packages.${system}.default;
      description = "The athroisma package to use.";
    };
  };

  congeries = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Put congeries on QML_IMPORT_PATH, for the 3D globe widget.";
    };
    package = lib.mkOption {
      type = lib.types.package;
      default = congeries.packages.${system}.default;
      description = "The congeries package to use.";
    };
  };

  python = lib.mkOption {
    type = lib.types.package;
    default = pkgs.python3.withPackages (ps: with ps; [icalendar recurring-ical-events]);
    description = ''
      The python3 build to put on the service's PATH.
      Calendar (icalendar/recurring-ical-events), AirPods battery and the
      3D globe's starfield generation script all need python3.
    '';
  };

  secretTool = lib.mkOption {
    type = lib.types.enum ["none" "oo7" "secret-tool"];
    default = "none";
    description = ''
      The secret service client to put on the service's PATH for credential
      storage and keyring unlock.
    '';
  };

  batteriesIncluded = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Put the full set of optional runtime tools zesis's widgets can shell
        out to on the service's PATH.
      '';
    };
    packages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = with pkgs; [
        bash
        cifs-utils.bin
        coreutils
        curl
        findutils
        git
        gnugrep
        gnused
        imagemagick
        samba
        systemd
        util-linux
        which
        matugen
        awww
        bluez
        avahi
        hostname
        libnotify
        procps
        xdg-utils
        gawk
        brightnessctl
        slurp
        wf-recorder
      ];
      description = "Packages put on the service's PATH when batteriesIncluded.enable is true.";
    };
  };

  inheritPath = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = ''
      Append your normal PATH to the service's PATH. Disable for a
      reproducible dependency surface. You'll most likely want
      `batteriesIncluded.enable = true;`, to still cover the ordinary
      tools zesis's widgets need.
    '';
  };

  usePkexec = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = ''
      Put a `pkexec` symlink on the service's PATH, pointing at setuid wrapper
      NixOS provides via `/run/wrappers/bin/pkexec` (when
      `security.polkit.enablePkexecWrapper = true;` is set.
    '';
  };

  systemd.enable = lib.mkOption {
    type = lib.types.bool;
    default = systemdEnableDefault;
    description = ''
      Launch a `systemd --user` service for zesis, wanted by
      `graphical-session.target`. Disable this if you'd rather start it
      yourself, e.g. with `exec-once = quickshell -c zesis` in your
      compositor config. The `zesis` config is still deployed to
      `${deployPath}` either way
    '';
  };
}
