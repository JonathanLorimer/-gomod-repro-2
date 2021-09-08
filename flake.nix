{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    gomod2nix.url = "github:tweag/gomod2nix";
    terra-src = {
      flake = false;
      url = github:terra-money/core;
    };
  };

  outputs =
    { self
    , nixpkgs
    , flake-utils
    , gomod2nix
    , terra-src
    }:
    let
      overlays = [ gomod2nix.overlay ];
    in flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system overlays; };

        # This is just to aid in setup, not necessary for repro
        genGomod = pkgs.writeShellScriptBin "genGomod" ''
          SOURCE_HOME=$(pwd)
          mkdir "$SOURCE_HOME/tmp"
          cd tmp
          cp -r ${terra-src}/* "$SOURCE_HOME/tmp"
          ${pkgs.gomod2nix}/bin/gomod2nix
          cd "$SOURC_HOME"
          mv "$SOURCE_HOME/tmp/gomod2nix.toml" "$SOURCE_HOME/go-modules.toml"
        '';
      in
      rec {
        packages = flake-utils.lib.flattenTree
          { terra = pkgs.buildGoApplication {
              name = "terra";
              src = "${terra-src}";
              modules = ./go-modules.toml;
            };
          };

        defaultPackage = packages.terra;


        # This is also not necessary for repro, just a convenience
        devShell =
          pkgs.mkShell {
            buildInputs = [ genGomod ];
          };

        apps.terra = flake-utils.lib.mkApp { name = "regen"; drv = packages.terra; };
      });
}
