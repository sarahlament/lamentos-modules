{
  description = "LamentOS Module System";
  inputs = {
    # We choose to push nixos-unstable as well as 'unstable' home-manager
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager/";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # We use stylix so we can sucessfully set system-wide theming, such as fonts, cursors, and our custom base24 theme
    stylix = {
      url = "github:nix-community/stylix/";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    ...
  } @ inputs: {
    nixosModules = {
      default = import ./modules/default.nix inputs;
      lamentos = self.nixosModules.default;
    };

    # Expose the formatter you prefer
    formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.alejandra;
  };
}
