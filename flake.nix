{
  description = "LamentOS Module System";
  inputs = {
    # We choose to push nixos-unstable as well as 'unstable' home-manager
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager/";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # We are using the upstream for PR #892 which introduces breaking changes
    # including new configuration options, so we're going to use that here
    stylix = {
      url = "github:make-42/stylix/matugen";
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
