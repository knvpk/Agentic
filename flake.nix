{
  description = "Agentic";

  inputs = {
    nixpkgs = {
      url = "github:nixos/nixpkgs?ref=nixos-25.11";
    };
    openspec = {
      url = "github:Fission-AI/OpenSpec?ref=v1.3.1";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      openspec,
      ...
    }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config = {
          allowUnfree = true;
        };
      };
    in
    {
      formatter.${system} = pkgs.nixfmt;


      devShells.${system} = {

        default = pkgs.mkShell {
          name = "dev";

          buildInputs = with pkgs; [
            nixd
            nixfmt-rfc-style

            pre-commit
            go-task

            openspec.packages.${system}.default
          ];

          shellHook = ''
            export PROJECT_ROOT=$PWD
          '';
        };
      };
    };
}
