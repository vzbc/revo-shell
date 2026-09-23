# Nix

Zesis ships three ways to deploy. A **NixOS module**, a **[Home Manager](https://github.com/nix-community/home-manager) module**, and an **[Hjem](https://github.com/feel-co/hjem) module**.

All of them deploy a *named* Quickshell config (`zesis`) wiring up the `athroisma`/`congeries` PATH and `QML_IMPORT_PATH` automatically.

## Which one?

| | NixOS module | Home Manager module | Hjem module |
| --- | --- | --- | --- |
| Scope | system-wide, every user | per-user | per-user |
| Deploys to | `/etc/xdg/quickshell/zesis` | `$XDG_CONFIG_HOME/quickshell/zesis` | `$XDG_CONFIG_HOME/quickshell/zesis` |
| `systemd --user` service | on by default | off by default | off by default |
| PAM (lock screen) | set up for you | manual, see [below](#pam-lock-screen) | manual, see [below](#pam-lock-screen) |
| 3D globe starfield cache | shared, `/var/cache/zesis/starfield` | per-user, `$XDG_CACHE_HOME/zesis/starfield` | per-user, `~/.cache/zesis/starfield` |

## NixOS module

```nix
{
  inputs.zesis.url = "github:zesis-shell/zesis";

  outputs = {nixpkgs, zesis, ...}: {
    nixosConfigurations.mymachine = nixpkgs.lib.nixosSystem {
      modules = [
        zesis.nixosModules.default
        {services.zesis.enable = true;}
      ];
    };
  };
}
```

Zesis puts the built config at `/etc/xdg/quickshell/zesis`, and starts a `zesis.service` wanted by `graphical-session.target`.

The deps can be overwritten or turned off:

```nix
services.zesis = {
  enable = true;
  athroisma.enable = false; # or: athroisma.package = ...;
  congeries.enable = false; # or: congeries.package = ...;
};
```
Zesis relies on a lot of desktop tools - matugen, bluetoothctl, awww, curl, notify-send, and so on. By default Zesis inherits your desktop `PATH` (system-wide, per-user packages). If you want all dependencies automatically provided with Zesis, then use the `batteriesIncluded` option:

```nix
services.zesis = {
  enable = true;
  batteriesIncluded.enable = true; # or: batteriesIncluded.packages = [...];
};
```

The module also registers the [lock screen's PAM service](#pam-lock-screen) (`security.pam.services.quickshell`) for you. Set `services.zesis.pam.enable = false;` if you want to define it yourself.

You can disable systemd if you want to launch zesis yourself in your compositor's config, wrapper script etc.

## Home Manager module

It deploys the built config to `$XDG_CONFIG_HOME/quickshell/zesis` and, optionally, wires up the same kind of `systemd --user` service.

```nix
{
  inputs.zesis.url = "github:zesis-shell/zesis";

  outputs = {home-manager, zesis, ...}: {
    homeConfigurations.me = home-manager.lib.homeManagerConfiguration {
      modules = [
        zesis.homeModules.default
        {
          programs.zesis = {
            enable = true;
            systemd.enable = true;
          };
        }
      ];
    };
  };
}
```

Everything from the NixOS module carries over unchanged, just under `programs.zesis` instead of `services.zesis`.

There's no `pam` option. PAM services are a system-level concern home-manager can't set up on its own, see [PAM (lock screen)](#pam-lock-screen).

## Hjem module

For [hjem](https://github.com/feel-co/hjem) instead of home-manager, `hjemModules.default` does the same thing under `hjem.users.<name>`:

```nix
{
  hjem.users.myuser = {
    imports = [zesis.hjemModules.default];
    programs.zesis = {
      enable = true;
      systemd.enable = true;
    };
  };
}
```

Same options, same defaults, still under `programs.zesis`.

There's no `pam` option. PAM is system-scoped, and hjem's per-user module system can't reach up into it, see [PAM (lock screen)](#pam-lock-screen).

## Squirrel's recommended setup

This is the maintainer's own config:

```nix
hjem.users.squirrel.programs.zesis = {
  enable = true;
  systemd.enable = true;
  inheritPath = false;
  batteriesIncluded.enable = true;
  secretTool = "oo7";
};
```

## PAM (lock screen)

The lock screen needs a `quickshell` PAM service registered, see [Lock screen](../README.md#lock-screen) in the main README for the setup. Only the NixOS module does this for you automatically ([above](#nixos-module)). Home Manager and Hjem can't reach system-level PAM config from their per-user scope.
