{
  description = "flake for Yura-PC";

  inputs = {
    nixpkgs = {
      url = "github:NixOS/nixpkgs/nixos-unstable";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    plasma-manager = {
      url = "github:nix-community/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, plasma-manager, nixos-generators }: {
    nixosConfigurations = {
      Yura-PC = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./modules
          ./hosts/common.nix
          ./hosts/Yura-PC
          # https://nix-community.github.io/home-manager/index.xhtml#sec-flakes-nixos-module
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.sharedModules = [ plasma-manager.homeManagerModules.plasma-manager ];

            home-manager.users.cazzzer = import ./home;
            # Optionally, use home-manager.extraSpecialArgs to pass
            # arguments to home.nix
          }
        ];
      };
      VM = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./modules
          ./hosts/common.nix
          ./hosts/vm
        ];
      };
      router = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./modules
          ./hosts/common.nix
          ./hosts/router
        ];
      };
    };
    # https://github.com/nix-community/nixos-generators?tab=readme-ov-file#using-in-a-flake
    packages.x86_64-linux = {
      proxmox = nixos-generators.nixosGenerate {
        system = "x86_64-linux";
        modules = [
          ./modules
          ./hosts/common.nix
          ./hosts/vm/proxmox.nix
          ./hosts/vm
        ];
        format = "proxmox";
      };
    };
  };
}
