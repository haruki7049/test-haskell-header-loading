{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    systems.url = "github:nix-systems/default";
    stacklock2nix.url = "github:haruki7049/stacklock2nix/additionalDevShellBuildInputs";
    flake-compat.url = "github:edolstra/flake-compat";
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
  };

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = import inputs.systems;

      perSystem =
        { pkgs, system, ... }:
        let
          overlays = [
            inputs.stacklock2nix.overlay
            (final: prev: {
              gdhs-stacklock = final.stacklock2nix {
                stackYaml = ./stack.yaml;
                baseHaskellPkgSet = final.haskell.packages.ghc984;

                devShellArguments = {
                  nativeBuildInputs = stacklockHaskellPkgSet: [
                    final.stack
                    final.nil
                    final.pkg-config
                  ];
                  buildInputs = stacklockHaskellPkgSet: [
                    final.xorg.libX11.dev
                  ];
                };

                additionalHaskellPkgSetOverrides = hfinal: hprev: {
                  #lens = final.haskell.lib.compose.dontCheck hprev.lens;
                };

                all-cabal-hashes = final.fetchurl {
                  url = "https://github.com/commercialhaskell/all-cabal-hashes/archive/df4fd6587f7e97d8170250ba4419f2cb062736c4.tar.gz";
                  hash = "sha256-kYlq2AWMivC11oYiaYOGu+hBHTkkiWKWM0xlbSuPRe8=";
                };
              };
            })
          ];
        in
        {
          _module.args.pkgs = import inputs.nixpkgs {
            inherit system overlays;
          };

          packages = {
            default = pkgs.gdhs-stacklock.pkgSet.test-haskell-gtk;
          };

          devShells.default = pkgs.gdhs-stacklock.devShell;
        };
    };
}
