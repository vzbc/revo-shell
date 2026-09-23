{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs?ref=nixos-unstable";
    athroisma = {
      url = "github:zesis-shell/athroisma";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    congeries = {
      url = "github:zesis-shell/congeries";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = {
    self,
    nixpkgs,
    athroisma,
    congeries,
    ...
  }: let
    systems = ["x86_64-linux" "aarch64-linux"];
    forEachSystem = nixpkgs.lib.genAttrs systems;
    pkgsFor = system: import nixpkgs {inherit system;};
    shadersFor = system: (pkgsFor system).callPackage ./nix/shaders.nix {src = ./.;};

    mkConfig = {
      system,
      starfieldPath ? "/var/cache/zesis/starfield/RealStarField.js",
    }: let
      pkgs = pkgsFor system;
    in
      pkgs.runCommand "zesis-config" {
        nativeBuildInputs = [pkgs.lndir];
      } ''
        mkdir -p "$out"
        lndir -silent ${./.} "$out"
        lndir -silent ${(shadersFor system).package} "$out"

        ln -s ${starfieldPath} "$out/widgets/globe3d/RealStarField.js"
      '';
  in {
    packages = forEachSystem (system: {
      athroisma = athroisma.packages.${system}.default;
      congeries = congeries.packages.${system}.default;

      shaders = (shadersFor system).package;

      config = mkConfig {inherit system;};
    });

    apps = forEachSystem (system: {
      compile-shaders = {
        type = "app";
        program = toString (shadersFor system).compile;
      };
    });

    lib = {inherit mkConfig;};

    nixosModules.default = import ./nix/module.nix {inherit self athroisma congeries;};

    homeModules.default = import ./nix/home-module.nix {inherit self athroisma congeries;};

    hjemModules.default = import ./nix/hjem-module.nix {inherit self athroisma congeries;};

    devShells = forEachSystem (system: let
      pkgs = pkgsFor system;
    in {
      default = pkgs.callPackage ./nix/shell.nix {
        athroisma = athroisma.packages.${system}.default;
        congeries = congeries.packages.${system}.default;
      };
    });
  };
}
