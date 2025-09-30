# LamentOS

A comprehensive and highly ambitious nixosModule system that will hopefully handle everything from boot parameters to desktop environments, so you get a working system without all the configuration hassle.

## What's the deal?

When starting out with NixOS myself, I found quite a few comments ranging along the vibes of 'oh, home manager is difficult to use' or 'flakes are just confusing!' to 'omg HM is great!' and 'you should just accept flakes'. Along the way, I also found multiple people saying they really liked NixOS, but the configuration felt overwhelming and confusing. After personally falling in love with all of it and having my own opinions on how a system should be setup, I decided to make my own module system and simplify as much of it as possible.

LamentOS makes opinionated choices about how your system should be configured and integrates Home Manager at the system level to keep everything in sync.

## How is it opinionated?

LamentOS integrates Home Manager at the system level instead of using it as a standalone module. While this does make simple user tweaks more 'expensive' to do, this also synchronizes the entire system configuration together. With the addition of Nix flakes, this provides an entirely reproducible environment with no concerns between system and user package versioning or dependencies.

LamentOS also uses Stylix right out of the gate, ensuring consistent theming and fonts across the entire system. Most end-users want a nice looking desktop, so I'm going to add some theming to make it look 'not default' for you :P
NOTE: for the time being, I am NOT using the main stylix branch, but instead the upstream for a PR that will change how things are configured entirely, another opinionated choice.

Oh, and formatter. I prefer `alejandra` over `nixfmt`, so there's that as well.

## So... what does this actually get you?

For now, not much more than a few extra goodies and basic user creation and system-level Home Manager. But once this project takes off, users will be able to declare their entire desktop environment with this one module, getting a true 'it just works' desktop experience the Nix way.

## How modules work

Everything is organized in a clear hierarchy:
```
lamentos.hardware.graphics
lamentos.desktop.hyprland
lamentos.services.development
lamentos.system.locale
```
REMINDER! These are just examples, final config options are to be determined

Enable what you want, ignore what you don't.

## Development approach

The initial development of this module system is going to be based on my own needs and use cases as this module system will become the core of my own personal system. Over time, however, I plan on adding much more into it, such as laptop things, virtualization, and others.

## Getting Started

As this is a fledgling module system, I cannot in good concious say 'hey, come use my thing!' just yet. However, if you *really* want to use it regardless, you can import it into your own `flake.nix` file:

```
{
    inputs = {
        nixpkgs.url = <...>;
        home-manager = {<...>};
        stylix = {
            # we use this upstream PR for stylix
            url = "github:make-42/stylix/matugen";
            <...>
        }
        lamentos = {
            url = "github:sarahlament/lamentos-modules";

            # Both are important! This ensures I use the same versions you yourself are using
            inputs.nixpkgs.follows = "nixpkgs";
            inputs.home-manager.follows = "home-manager";
            inputs.stylix.follows = "stylix";
        };
    };
    outputs = {
        <...>
        # rest of config
```
---

*Initially generated and reviewed with AI assistance*
