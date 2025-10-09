# LamentOS

A comprehensive and highly ambitious nixosModule intended for desktop/workstation systems that will hopefully handle everything from boot parameters to desktop environments, so you get a working system without all the configuration hassle.

## What's the deal?

I initially started making this nixosModule as an attempt to better understand how NixOS and modules worked, as well as wanting to help ease some of the initial frustration of creating a fully functional NixOS system for those that might want something that 'just works'. Since then I've been slowly working away at that idea, but I eventually want to provide a 'distro-level' configuration that enables users to have a 'ready-to-use' system with just a few lines of config, so that the end-user can focus on making the system itself theirs instead of "shit, how did I get KDE to work again?"

LamentOS makes opinionated choices about how your system should be configured, and (attempts to) provide a full 'it-just-works' system environment that anyone can use.

## How is it opinionated?

We make a few decisions about how the system and users should be setup. While this may not be for everybody, it should provide a 'one-size-fits-all' solution.

- Home Manager as a System module, and Stylix integration
  - System and User configurations are always in sync, and the entire system becomes more reproducible as a result.
  - Stylix provides its own 'it just works' theming suite, so why should I *not* use existing community tools?

- Some system things that are 'touch once, never update' are set for you!
  - system.identity.stateVersion = "25.05"
  - system.identity.systemType = "x86_64-linux"

- Most end-users don't actually care about 'unfree' software (software not released as open-source in some way), and actually actively want it (Discord is considered 'unfree')
  - allowUnfree = true

- We enable our own custom theme by default, as well as a custom Oh My Posh prompt for the shell. Most users want a desktop that 'looks good', so why shouldn't I provide one?
  - system.theming.enable = true
  - system.theming.useCustomTheme = true
  - system.theming.omp.enable = true

- Users are given a default shell.
  - ZSH is just better than bash, but we also have options for bash, fish, and dash.

- We also provide some basic tool replacements within your shell and create aliases for them, such as `eza`, `bat`, and `ripgrep`.
  - shell.modernTools = true

- This one's purely me: I prefer `alejandra` over `nixfmt`, so that's what I use.

## How modules work

Everything is organized through `lamentos.*` options, with self-defining names. We set a few defaults ourselves, with only a few being "must-define"

```nix
# 'mandatory' options: to configure a system a few things must be known
lamentos.system.identity.hostname = "LamentOS"; # set the hostname for the system
lamentos.user.<USERNAME>.isAdmin = true; # I'm going to assume you want your main user able to use sudo and such lol
lamentos.user.<USERNAME>.fullName = "Full Name"; # different 'mandatory' option for users if you don't want them as an admin
lamentos.graphics.vendor = "nvidia"; # OR 'intel' OR 'amd', we take care of the drivers!
# and that's all that *must* be set! Everything else is set to certain defaults to ensure things 'just work'!

# here's some examples of some additional options you can set:
lamentos.system.theming = {
  enable = false; # if you don't want any theming set by me, you can disable it entirely!
  useCustomTheme = false; # don't like my purple theme? default to Catppuccin Mocha instead! (enable must still be true)
  fonts = {<...>}; # coupled options for fonts, including monospace, sansSerif, and serif; please check 'modules/system/theming/settings.nix' for all options
};
lamentos.desktop.kde.enable = true; # enables the Plasma6 DE, along with proper services and some extra programs
lamentos.shell.modernTools.useRustSudo = true; # use `sudo-rs` instead of `sudo`

```

## Development approach

Now that I have my 'basic system setup' modularized through this, I now plan on adding the extra goodies as I want and see fit, such as development tools, virtualization, boot-time options, and possibly even a 'guided disk' setup! Please check back every once in awhile to see what's new!

## Getting Started

I finally have enough I can say 'hey, I might have something to provide you'!!

So, if you wish to use my modules, you can import them like this in your `flake.nix`:

**⚠️ SECURITY WARNING:** Users are created with the default password `Welcome123`, so make sure to change it after your first boot with `passwd`.

```nix
{
  inputs = {
    nixpkgs.url = <...>;

    # *technically*, you actually don't even need these
    # since we import home-manager and stylix ourselves, you *could* trust my pinned versions
    # and not use your own, HOWEVER I still highly recommend *AGAINST* doing so and using your own
    home-manager = {<...>};
    stylix = {<...>};
    lamentos = {
      url = "github:sarahlament/lamentos-modules";

      # now, most flakes will say this one is 'optional' but 'recommendend', I am saying something different: 
      # I will NOT be providing ANY support if you do not use your own nixpkgs. 
      # While I may want to provide a 'it just works' configuration, nixpkgs itself updates far 
      # faster than I have the mental capacity for ensuring compatibility with *every single commit*
      inputs.nixpkgs.follows = "nixpkgs";

      # as stated in the inputs above, you *technically* don't need these either. HOWEVER! I still
      # *highly* recommend them, as it places full version control into your hands.
      # also, if my inputs are having an issue, there's a very good chance this will fix it anyways
      inputs.home-manager.follows = "home-manager";
      inputs.stylix.follows = "stylix";
    };
  };
  outputs = {...}@inputs:
  {
    nixosConfigurations.<HOSTNAME> = nixpkgs.lib.nixosSystem {
      specialArgs = {inherit inputs;};
      modules = [ inputs.lamentos.nixosModules.lamentos ];
      <...>
      ### your config ###
```
---

*Initially generated and reviewed with AI assistance*
