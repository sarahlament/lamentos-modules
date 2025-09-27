{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
  }: {
    nixosModules.lamentos = {
      imports = [
        home-manager.nixosModules.home-manager
        ./modules/user.nix
        ./modules/system.nix
        ./modules/locale.nix
        ./modules/hardware.nix
      ];
    };
  };
}
