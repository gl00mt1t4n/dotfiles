{
  description = "gl00m's system config";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hermes-agent.url = "github:NousResearch/hermes-agent";
    quickshell = {
      url = "git+https://git.outfoxxed.me/outfoxxed/quickshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    zen-browser = {
      url = "github:youwen5/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, hermes-agent, quickshell, zen-browser, ... }:
  let
    system = "x86_64-linux";
    overlays = [
      (final: prev: {
        zen-browser = zen-browser.packages.${system}.default;
      })
    ];
    pkgs = import nixpkgs {
      inherit system overlays;
      config.allowUnfree = true;
    };

    caelestiaShell = pkgs.callPackage ./caelestia/nix {
      rev = self.rev or self.dirtyRev or "dirty";
      stdenv = pkgs.clangStdenv;
      quickshell = quickshell.packages.${system}.default.override {
        withX11 = false;
        withI3 = false;
      };
      caelestia-cli = null;
    };

    homeModules = [ ./home.nix ];
    homeExtraSpecialArgs = { inherit caelestiaShell; };
  in {
    packages.${system} = {
      caelestia-shell = caelestiaShell;
      default = caelestiaShell;
    };

    # System only
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      inherit system;
      modules = [
        { nixpkgs.overlays = overlays; }
        ./configuration.nix
        hermes-agent.nixosModules.default
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
        ./configuration.nix
        hermes-agent.nixosModules.default
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
