{
  description = "NixOS and macOS configuration for hlts2";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-darwin = {
      url = "github:nix-darwin/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-homebrew.url = "github:zhaofengli/nix-homebrew";

    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };
    homebrew-bundle = {
      url = "github:homebrew/homebrew-bundle";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, home-manager, nix-darwin, ... }@inputs:
    let
      systems = {
        linux = "x86_64-linux";
        darwin = "aarch64-darwin"; # Apple Silicon (Intel: x86_64-darwin)
      };
      username = "hlts2";
    in
    {
      # NixOS (Linux)
      nixosConfigurations = {
        thinkpad-x1 = nixpkgs.lib.nixosSystem {
          system = systems.linux;
          specialArgs = { inherit inputs username; };
          modules = [
            ./hosts/thinkpad-x1/configuration.nix

            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.${username} = import ./home;
              home-manager.extraSpecialArgs = { inherit inputs username; };
            }
          ];
        };
      };

      # macOS (Darwin)
      darwinConfigurations = {
        macmini = nix-darwin.lib.darwinSystem {
          system = systems.darwin;
          specialArgs = { inherit inputs username; };
          modules = [
            ./hosts/darwin/configuration.nix

            inputs.nix-homebrew.darwinModules.nix-homebrew
            {
              nix-homebrew = {
                enable = true;
                user = username;
                taps = {
                  "homebrew/homebrew-core" = inputs.homebrew-core;
                  "homebrew/homebrew-cask" = inputs.homebrew-cask;
                  "homebrew/homebrew-bundle" = inputs.homebrew-bundle;
                };
                mutableTaps = false;
                autoMigrate = true;
              };
            }

            home-manager.darwinModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.${username} = import ./home;
              home-manager.extraSpecialArgs = { inherit inputs username; };
            }
          ];
        };
      };
    };
}
