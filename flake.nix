{
  description = "Flake Dev Environment for scripts";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    rust-overlay.url = "github:oxalica/rust-overlay";
    nur.url = "github:bglebrun/nur-packages";
  };

  outputs =
    { self
    , nixpkgs
    , rust-overlay
    , nur
    }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        overlays = [
          rust-overlay.overlays.default
        ];
      };
      nurpkgs = import nur {
        inherit system;
        overlays = [
          nur.packages
        ];
      };
      toolchain = pkgs.rust-bin.fromRustupToolchainFile ./toolchain.toml;
    in
    {
      devShells.${system}.default = pkgs.mkShell {
        packages = [
          toolchain
          pkgs.cached-nix-shell
          pkgs.rust-analyzer-unwrapped
          pkgs.dotnet-sdk
          pkgs.powershell
          nur.legacyPackages.${system}.PowerShellEditorServices
        ];
      };
      RUST_SRC_PATH = "${toolchain}/lib/rustlib/src/rust/library";
      PWSH_EDITOR_SERVICES = "${nur.legacyPackages.${system}.PowerShellEditorServices}";
    };

}
