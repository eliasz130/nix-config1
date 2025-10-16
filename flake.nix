{
  description = "Elias's unified Nix configuration for homelab, macOS, and travel USB";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-24.11";
    
    # macOS support
    darwin = {
      url = "github:lnl7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    # Home manager for user environments
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    # Secrets management
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixpkgs-stable, darwin, home-manager, agenix, ... }@inputs: 
  let
    system = "x86_64-linux";
    darwinSystem = "aarch64-darwin";  # or x86_64-darwin for Intel
    
    # Common configuration shared across all systems
    commonModules = [
      ./modules/common/users.nix
      agenix.nixosModules.default
    ];
  in
  {
    # NixOS Systems
    nixosConfigurations = {
      
      # Media Server
      elias-server2 = nixpkgs.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs; };
        modules = commonModules ++ [
          ./hosts/elias-server2/configuration.nix
          ./modules/common/security.nix
          ./modules/media/wireguard-client.nix
          ./modules/media/jellyfin.nix
          ./modules/media/starr-stack.nix
          ./modules/media/immich.nix
        ];
      };
      
      # Infrastructure Server
      elias-server = nixpkgs.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs; };
        modules = commonModules ++ [
          ./hosts/elias-server/configuration.nix
          ./modules/common/security.nix
          ./modules/infra/wireguard-server.nix
          ./modules/infra/pihole.nix
          ./modules/infra/nginx-proxy.nix
          ./modules/infra/homeassistant.nix
          ./modules/infra/uptime-kuma.nix
        ];
      };
      
      # Travel USB - Portable system with useful tools
      travel-usb = nixpkgs.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs; };
        modules = commonModules ++ [
          ./hosts/travel-usb/configuration.nix
          ./modules/common/security.nix
          ./modules/travel/portable.nix
          
          # ISO/USB build configuration
          "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
        ];
      };
    };

    # macOS System
    darwinConfigurations = {
      macbook = darwin.lib.darwinSystem {
        system = darwinSystem;
        specialArgs = { inherit inputs; };
        modules = [
          ./hosts/macbook/configuration.nix
          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.elias = import ./home/elias.nix;
          }
        ];
      };
    };

    # Standalone home-manager for macOS (alternative to nix-darwin)
    homeConfigurations = {
      "elias@macbook" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.${darwinSystem};
        modules = [
          ./home/elias.nix
        ];
      };
    };
  };
}