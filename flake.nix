{
  description = "flake for Yura-PC";

  inputs = {
    nixpkgs = {
      url = "github:NixOS/nixpkgs/nixos-unstable";
    };
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixos-generators }: {
    nixosConfigurations = {
      Yura-PC = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./modules
          ./hosts/common.nix
          ./hosts/Yura-PC
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
