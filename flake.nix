# flake.nix
{
  description = "Darktop v2";

  inputs = {
    std.url = "github:divnix/std";
    nixpkgs.follows = "std/nixpkgs";
    nixpkgs-wayland = {
      url = "github:nix-community/nixpkgs-wayland";
      inputs.nixpkgs.follows = "std/nixpkgs";
    };
    nixgl = {
      url = "github:guibou/nixGL";
      inputs.nixpkgs.follows = "std/nixpkgs";
    };
  };

  outputs = {
    std,
    self,
    ...
  } @ inputs:
    std.growOn {
      inherit inputs;
      cellsFrom = ./src;
      cellBlocks = with std.blockTypes; [
        #(installables "packages" {ci.build = true;})
        (installables "desktops" {ci.build = true; ci.publish = true;})
        (devshells "devshells" {ci.build = true;})
      ];
    }
    {
      #devShells = std.harvest self ["src" "devshells"];
      packages = std.harvest self ["darktop" "desktops"];
    };
}
