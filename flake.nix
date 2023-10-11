{
  description = "Flake utils demo";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        blake3 = pkgs.python310Packages.buildPythonPackage rec {
          pname = "blake3";
          version = "0.3.3";
          src = pkgs.fetchFromGitHub {
            owner = "MostAwesomeDude";
            repo = "blake3-py";
            rev = "2a61091f7ea08e016717200acb3fed45d41da9c2";
            sha256 = "sha256-HG5YMuyLDjonf9Uzc+xR56dFC9KlmjACqFjFbIwl53w=";
          };
          format = "pyproject";
          cargoDeps = pkgs.rustPlatform.importCargoLock {
            lockFile = "${src}/Cargo.lock";
          };
          nativeBuildInputs = (with pkgs; [
            pkg-config
          ]) ++ (with pkgs.rustPlatform; [
            cargoSetupHook maturinBuildHook
          ]);
        };
        llm-rs-python = pkgs.python310Packages.buildPythonPackage rec {
          pname = "llm-rs";
          version = "1.0";
          src = ./.;
          format = "pyproject";
          cargoDeps = pkgs.rustPlatform.importCargoLock {
            lockFile = ./Cargo.lock;
            outputHashes = {
              "ggml-0.2.0-dev" = "sha256-0HodDCR1MD1sEWVIhFUBQpgmMxDL8YTxn6guFNdkXuk=";
            };
          };
          nativeBuildInputs = (with pkgs; [
            pkg-config openssl
          ]) ++ (with pkgs.rustPlatform; [
            cargoSetupHook maturinBuildHook
          ]);
          propagatedBuildInputs = (with pkgs.python310Packages; [
            blake3 huggingface-hub
            transformers sentencepiece torch accelerate tqdm einops
          ]);
          PKG_CONFIG_PATH = "${pkgs.openssl.dev}/lib/pkgconfig";
        };
      in {
        packages = {
          default = llm-rs-python;
        };
        devShells.default = pkgs.mkShell {
          name = "llm-rs-env";
          packages = [
            (pkgs.python310.withPackages (ps: [ llm-rs-python ]))
          ];
        };
      }
    );
}
