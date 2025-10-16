{
  description = "Elias's unified Nix configuration for homelab, macOS, and travel USB";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-24.11";
    darwin = {
      url = "github:lnl7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixpkgs-stable, darwin, agenix, ... }@inputs:
  let
    system = builtins.currentSystem;
    darwinSystem = "aarch64-darwin";  # or x86_64-darwin for Intel

    commonModules = [
      ./modules/common/users.nix
      agenix.nixosModules.default
    ];
  in
  {
    nixosConfigurations = {
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
      travel-usb = nixpkgs.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs; };
        modules = commonModules ++ [
          ./hosts/travel-usb/configuration.nix
          ./modules/common/security.nix
          ./modules/travel/portable.nix
          "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
        ];
      };
    };

    darwinConfigurations = {
      macbook = darwin.lib.darwinSystem {
        system = darwinSystem;
        specialArgs = { inherit inputs; };
        modules = [
          ./hosts/macbook/configuration.nix
        ];
      };
    };
  };
}