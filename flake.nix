{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      rust-overlay,
    }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-darwin"
      ];
      forEachSystem =
        f:
        nixpkgs.lib.genAttrs systems (
          system:
          let
            pkgs = import nixpkgs {
              inherit system;
              overlays = [ (import rust-overlay) ];
            };
          in
          f pkgs
        );
    in
    {
      packages = forEachSystem (pkgs: {
        default = pkgs.rustPlatform.buildRustPackage {
          pname = "ir441";
          version = "2.2.1";
          src = ./.;
          cargoLock.lockFile = ./Cargo.lock;
        };
      });

      devShells = forEachSystem (
        pkgs:
        let
          rustToolchain = pkgs.rust-bin.stable."1.93.0".default.override {
            extensions = [
              "rust-src"
              "rust-analyzer"
            ];
          };
        in
        {
          default = pkgs.mkShell {
            packages = with pkgs; [
              rustToolchain
            ];
            inputsFrom = [ self.packages.${pkgs.system}.default ];
          };
        }
      );
    };
}
