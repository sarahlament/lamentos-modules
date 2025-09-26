# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a NixOS configuration project called "LamentOS" (technical name: lamentos) that provides modular system and user configuration using Nix flakes. It's designed to be beginner-friendly for those starting their Nix journey, with simple single-user system configuration that integrates home-manager at the system level.

## Architecture

- **flake.nix**: Main flake file that exports the `lamentos` NixOS module
- **modules/system.nix**: System and hardware configuration including:
  - Core system settings (stateVersion, systemType, allowUnfree)
  - Hardware-specific options (NVIDIA support with open/proprietary drivers)
- **modules/user.nix**: User and desktop configuration including:
  - User account management (name, full name, shell selection)
  - Shell configuration (zsh, bash, dash, fish support)
  - Desktop environment setup (XDG portal integration)
  - Home-manager integration

## Configuration Pattern

Both modules follow a consistent pattern:
1. Define options using `mkOption` and `mkEnableOption`
2. Apply configurations using `mkMerge` and conditional `mkIf` blocks
3. Integration with home-manager for user-specific settings

## Key Features

- Functional area organization: system, hardware, user, desktop
- NVIDIA graphics support with automatic driver module loading and environment variable setup
- Home-manager integration for user environment management
- XDG portal configuration for desktop integration (Hyprland/GTK support)
- Microcode updates for both AMD and Intel CPUs
- Shell selection support with automatic program enablement
- Extensible architecture for future modules (networking, services, etc.)

## Development Commands

Since this is a Nix-based project, typical operations would include:
- `nix flake check` - Validate flake configuration
- `nix flake show` - Display flake outputs

## Current Status

The project now includes:
- Complete flake setup with nixos-25.05 stable and home-manager inputs
- Working system and user configuration modules
- README.md with installation instructions and usage examples
- Proper input follows patterns documented for users

## Planned Features (TODO)

- Desktop Environments (let's be real, GUIs are just useful)
- Networking Support (what end-user doesn't need the internet?)
- Audio (a few more 'set-and-forget' things that I'd like to provide)
- Fonts (who wants to remember 'oh yeah, the basic fonts I need are .....'?)
- Locale (and maybe timezone? locale makes sense, but timezone makes more sense to just show how to configure it...)
- Services/Programs (a few things that might be more helpful for those new to linux/configs)
- Stylix (? not sure if I want to have a default 'rice' or not yet)
- Basic shell enhancements (goes along with above, how much of a default 'dotfile config' do I want to ship?)
- Boot/Disk options (?? maybe something very simplistic that can be explained as a more comprehensive guide)

## Important Notes

- NVIDIA configuration includes boot-time kernel module setup and environment variables
- Users should always use `inputs.nixpkgs.follows` and `inputs.home-manager.follows` to avoid version conflicts
- The project targets single-user systems with system-level home-manager integration