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
  };

  outputs = { self, nixpkgs, home-manager, nix-darwin, ... }@inputs:
    let
      # サポートするシステム
      systems = {
        linux = "x86_64-linux";
        darwin = "aarch64-darwin"; # Apple Silicon (Intel: x86_64-darwin)
      };

      # ユーザー名
      username = "hlts2";
    in
    {
      # NixOS (Linux)
      nixosConfigurations = {
        nixos = nixpkgs.lib.nixosSystem {
          system = systems.linux;
          specialArgs = { inherit inputs username; };
          modules = [
            ./hosts/nixos/configuration.nix

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
        macbook = nix-darwin.lib.darwinSystem {
          system = systems.darwin;
          specialArgs = { inherit inputs username; };
          modules = [
            ./hosts/darwin/configuration.nix

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
