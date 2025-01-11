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
              test-stacklock = final.stacklock2nix {
                stackYaml = ./stack.yaml;
                baseHaskellPkgSet = final.haskell.packages.ghc984;

                devShellArguments = {
                  nativeBuildInputs = stacklockHaskellPkgSet: [
                    final.stack
                    final.nil
                    final.pkg-config
                  ];
                  buildInputs = stacklockHaskellPkgSet: [
                    final.pkg-config
                    final.openssl.dev
                  ];
                };

                additionalHaskellPkgSetOverrides = hfinal: hprev: {
                  prettyprinter = final.haskell.lib.compose.dontCheck hprev.prettyprinter;
                  text-iso8601 = final.haskell.lib.compose.dontCheck hprev.text-iso8601;
                  cborg = final.haskell.lib.compose.dontCheck hprev.cborg;
                  serialise = final.haskell.lib.compose.dontCheck hprev.serialise;
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
            default = pkgs.test-stacklock.pkgSet.test-haskell-header-loading;
          };

          devShells.default = pkgs.test-stacklock.devShell;
        };
    };
}
