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
    secrix = {
      url = "github:Platonic-Systems/secrix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, plasma-manager, nixos-generators, secrix }:
  let
    hmModule = file: {
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
      home-manager.sharedModules = [ plasma-manager.homeManagerModules.plasma-manager ];

      home-manager.users.cazzzer = import file;
      # Optionally, use home-manager.extraSpecialArgs to pass
      # arguments to home.nix
    };
  in
  {
    apps.x86_64-linux.secrix = secrix.secrix self;

    nixosConfigurations = {
      Yura-PC = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./modules
          ./hosts/common.nix
          ./hosts/common-desktop.nix
          ./hosts/Yura-PC
          ./users/cazzzer
          # https://nix-community.github.io/home-manager/index.xhtml#sec-flakes-nixos-module
          home-manager.nixosModules.home-manager
          (hmModule ./home/cazzzer-pc.nix)
        ];
      };
      Yura-TPX13 = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./modules
          ./hosts/common.nix
          ./hosts/common-desktop.nix
          ./hosts/Yura-TPX13
          ./users/cazzzer
          # https://nix-community.github.io/home-manager/index.xhtml#sec-flakes-nixos-module
          home-manager.nixosModules.home-manager
          (hmModule ./home/cazzzer-laptop.nix)
        ];
      };
      VM = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./modules
          ./hosts/common.nix
          ./hosts/hw-vm.nix
          ./hosts/vm
          ./users/cazzzer
        ];
      };
      router = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          secrix.nixosModules.default
          ./modules
          ./hosts/common.nix
          ./hosts/router
          ./users/cazzzer
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
          ./hosts/hw-proxmox.nix
          ./hosts/vm
          ./users/cazzzer
        ];
        format = "proxmox";
      };
      vm-proxmox = let
        image = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./modules
            ./hosts/common.nix
            ./hosts/hw-proxmox.nix
            ./hosts/vm
            ./users/cazzzer
          ];
        };
      in
        image.config.system.build.VMA;
    };
  };
}
