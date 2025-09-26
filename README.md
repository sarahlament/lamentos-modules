# LamentOS-modules

This is my attempt at making a simple single-user system module that integrates home-manager at the system-level, that can be used by those just starting their nix journey. Currently there's not much, but I plan on eventually adding much more!

## TODO
- Desktop Environments (let's be real, GUIs are just useful)
- Networking Support (what end-user doesn't need the internet?)
- Audio (a few more 'set-and-forget' things that I'd like to provide)
- Fonts (who wants to remember 'oh yeah, the basic fonts I need are .....'?)
- Locale (and maybe timezone? locale makes sense, but timezone makes more sense to just show how to configure it...)
- Services/Programs (a few things that might be more helpful for those new to linux/configs)
- Stylix (? not sure if I want to have a default 'rice' or not yet)
- Basic shell enhancements (goes along with above, how much of a default 'dotfile config' do I want to ship?)
- Boot/Disk options (?? maybe something very simplistic that can be explained as a more comprehensive guide)


## Features

- System configuration (state version, unfree software, NVIDIA support)
- User management with shell selection (zsh, bash, dash, fish)
- Home-manager integration
- XDG portal configuration for desktop environments

## Installation

Add lamentos to your flake inputs:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";

    # I depend on this, so you need it as well
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    lamentos = {
      url = "github:your-username/lamentos";
      # The next two options, while not strictly necessary, are *highly* recommended.
      # Having these follow your inputs ensure the same version is used across everything
      # which helps prevent different conflicts and evaluation errors (same goes for HM above)
      inputs.nixpkgs.follows = "nixpkgs"; 
      inputs.home-manager.follows = "home-manager";
    };
  };
}
```

## Usage

Import the module in your NixOS configuration:

```nix
{
  imports = [
    inputs.lamentos.nixosModules.lamentos
  ];

  # Configure with defaults
  lamentos = {
    user = {
      name = "user";
      fullName = "System User";
      shell = "zsh";
    };
    system = {
      allowUnfree = true;
    };
    hardware = {
      nvidia.enable = false;  # Set to true if you have NVIDIA GPU
    };
  };
}
```

## Available Options

### System Configuration (`lamentos.system`)
- `stateVersion` - NixOS state version (default: "25.05")
- `systemType` - System architecture (default: "x86_64-linux")
- `allowUnfree` - Allow unfree software (default: true)

### Hardware Configuration (`lamentos.hardware`)
- `nvidia.enable` - Enable NVIDIA support (default: false)
- `nvidia.open` - Use open NVIDIA drivers (default: true)

### User Configuration (`lamentos.user`)
- `name` - User login name (default: "user")
- `fullName` - Display name (default: "System User")
- `shell` - Shell choice: "zsh", "bash", "dash", "fish" (default: "zsh")

### Desktop Configuration (`lamentos.desktop`)
- `xdgThings` - Enable XDG portal setup (default: true)