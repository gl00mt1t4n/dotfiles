{
  description = "gl00m's system config";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    quickshell = {
      url = "git+https://git.outfoxxed.me/outfoxxed/quickshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    caelestia-cli = {
      url = "github:caelestia-dots/cli";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.caelestia-shell.follows = "";
    };
    zen-browser = {
      url = "github:youwen5/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hermes-agent = {
    url = "github:NousResearch/hermes-agent";
  };
    claude-desktop.url = "github:k3d3/claude-desktop-linux-flake";
  };

  outputs = { self, nixpkgs, home-manager, sops-nix, quickshell, caelestia-cli, zen-browser, claude-desktop, hermes-agent, ... }:
  let
    system = "x86_64-linux";
    overlays = [
      (final: prev: {
        zen-browser = zen-browser.packages.${system}.default;
        claude-desktop = claude-desktop.packages.${system}.claude-desktop;
        hermes-desktop = hermes-agent.packages.${system}.desktop;
      })
    ];
    pkgs = import nixpkgs {
      inherit system overlays;
      config.allowUnfree = true;
    };

    caelestiaCli = caelestia-cli.packages.${system}.default;

    caelestiaShell = pkgs.callPackage ./caelestia/nix {
      rev = self.rev or self.dirtyRev or "dirty";
      stdenv = pkgs.clangStdenv;
      quickshell = quickshell.packages.${system}.default.override {
        withX11 = false;
        withI3 = false;
      };
      caelestia-cli = caelestiaCli;
      withCli = true;
    };

    caelestiaSpotify = pkgs.callPackage ./pkgs/caelestia-spotify.nix {
      theme = ./config/spicetify/Themes/caelestia;
    };

    homeModules = [ ./home.nix ];
    homeExtraSpecialArgs = {
      inherit caelestiaShell caelestiaCli caelestiaSpotify;
    };
  in {
    packages.${system} = {
      caelestia-shell = caelestiaShell;
      spotify-caelestia = caelestiaSpotify;
      default = caelestiaShell;
    };

    # System only
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      inherit system;
      modules = [
        { nixpkgs.overlays = overlays; }
        ./configuration.nix
        sops-nix.nixosModules.sops
      ];
    };

    # User only
    homeConfigurations.gl00m = home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      extraSpecialArgs = homeExtraSpecialArgs;
      modules = homeModules;
    };

    # Both unified
    nixosConfigurations.gl00m-full = nixpkgs.lib.nixosSystem {
      inherit system;
      modules = [
        { nixpkgs.overlays = overlays; }
        hermes-agent.nixosModules.default
        ./modules/hermes.nix
        ./configuration.nix
        sops-nix.nixosModules.sops
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.extraSpecialArgs = homeExtraSpecialArgs;
          home-manager.users.gl00m = { imports = homeModules; };
        }
      ];
    };

  };
}
